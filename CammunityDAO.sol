// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CamuVerify.sol";
import "./CamuToken.sol";
import "./CamuCoin.sol";

/**
 * @title ModifiedCammunityDAO
 * @notice A DAO contract with a two‑stage voting process.  Stage 1 now
 *         requires voters to hold CAMC and be verified, and uses a
 *         percentage‑based quorum controlled by CAMT‑holders via
 *         governance.  CAMC holders can also submit proposals.
 */
interface ITreasury {
    function requestWithdrawal(address payable to, uint256 amount) external returns (uint256);
    function balance() external view returns (uint256);
}

contract ModifiedCammunityDAO is Ownable {
    CamuVerify public camuVerify;
    CamuCoin public camuCoin;
    CamuToken public camuToken;
    ITreasury public treasury;

    // total number of proposals created
    uint256 public proposalCount;
    // used to reset monthly spending limits
    uint256 public lastResetMonth;
    // amount spent in the current month
    uint256 public monthlySpent;

    /**
     * @notice Stage‑1 quorum expressed as a percentage of verified members.
     *         Proposals in stage 1 must receive at least
     *         (verifiedCount * stage1ThresholdPercent / 100) yes votes.
     *         This variable can be updated by the DAO via the
     *         `updateStage1Threshold` function.  Initialized to 10 %.
     */
    uint256 public stage1ThresholdPercent = 10;

    enum ProposalType { TEXT, FUNDING, TERMINATION }

    struct Proposal {
        uint256 id;
        string description;
        ProposalType proposalType;
        address payable target;
        uint256 amount;
        uint256 verifiedVotes;
        uint256 tokenVotes;
        uint256 voteStart;
        bool stage1Passed;
        bool executed;
        mapping(address => bool) verifiedVoted;
        mapping(address => bool) tokenVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    event NewProposal(uint256 indexed id, string description, ProposalType proposalType);
    event ProposalExecuted(uint256 indexed id);

    constructor(
        address _camuVerify,
        address _camuCoin,
        address _camuToken,
        address _treasury
    ) Ownable(msg.sender) {
        camuVerify = CamuVerify(_camuVerify);
        camuCoin = CamuCoin(_camuCoin);
        camuToken = CamuToken(_camuToken);
        treasury = ITreasury(_treasury);
        lastResetMonth = block.timestamp / 30 days;
    }

    /**
     * @notice Update the stage‑1 threshold.  Can only be called by the DAO
     *         itself via an executed proposal.  Enforces limits to avoid
     *         extreme values.
     * @param percent New threshold (between 5 and 50 percent).
     */
    function updateStage1Threshold(uint256 percent) external {
        require(msg.sender == address(this), "Only DAO can update threshold");
        require(percent >= 5 && percent <= 50, "Invalid threshold range");
        stage1ThresholdPercent = percent;
    }

    /**
     * @notice Create a new proposal.  Any caller holding CAMC can submit
     *         proposals.  The description should describe the action,
     *         and for FUNDING or TERMINATION proposals the target and
     *         amount must be set accordingly.
     */
    function createProposal(
        string memory description,
        ProposalType proposalType,
        address payable target,
        uint256 amount
    ) external {
        require(camuCoin.balanceOf(msg.sender) > 0, "Must hold CAMC to propose");
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = description;
        newProposal.proposalType = proposalType;
        newProposal.target = target;
        newProposal.amount = amount;
        newProposal.voteStart = block.timestamp;
        emit NewProposal(proposalCount, description, proposalType);
        proposalCount++;
    }

    /**
     * @notice Stage 1 voting.  Voters must be verified via CamuVerify and
     *         hold CAMC.  Once the threshold is met, the proposal moves
     *         to stage 2.  A minimum of three votes is always required.
     */
    function voteStage1(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.verifiedVoted[msg.sender], "Already voted in stage 1");
        (, , bool isVerified) = camuVerify.members(msg.sender);
        require(isVerified, "Not verified");
        require(camuCoin.balanceOf(msg.sender) > 0, "No CAMC balance");
        proposal.verifiedVotes++;
        proposal.verifiedVoted[msg.sender] = true;
        // Compute the required number of votes based on threshold
        uint256 required = (camuVerify.verifiedCount() * stage1ThresholdPercent + 99) / 100;
        if (required < 3) {
            required = 3;
        }
        if (proposal.verifiedVotes >= required) {
            proposal.stage1Passed = true;
        }
    }

    /**
     * @notice Stage 2 voting.  Weighted by CAMT balance.  Can only occur
     *         after stage 1 passes.
     */
    function voteStage2(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.stage1Passed, "Stage 1 has not passed");
        require(!proposal.tokenVoted[msg.sender], "Already voted in stage 2");
        uint256 weight = camuToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        proposal.tokenVotes += weight;
        proposal.tokenVoted[msg.sender] = true;
    }

    /**
     * @notice Execute a proposal after stage 2 voting.  Applies spending caps
     *         for funding proposals and additional safeguards for
     *         termination proposals.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.stage1Passed, "Stage 1 not passed");
        require(!proposal.executed, "Already executed");
        uint256 totalVotes = camuToken.totalSupply();
        uint256 quorum = (proposal.tokenVotes * 100) / totalVotes;
        // Budget logic for funding proposals
        if (proposal.proposalType == ProposalType.FUNDING) {
            uint256 currentMonth = block.timestamp / 30 days;
            if (currentMonth > lastResetMonth) {
                lastResetMonth = currentMonth;
                monthlySpent = 0;
            }
            uint256 treasuryBalance = address(treasury).balance;
            uint256 maxMonthlySpend = (treasuryBalance * 15) / 100;
            if (proposal.amount + monthlySpent > maxMonthlySpend) {
                require(quorum >= 67, "Special quorum required for excess budget");
            }
            monthlySpent += proposal.amount;
            treasury.requestWithdrawal(proposal.target, proposal.amount);
        }
        // Additional requirements for termination proposals
        if (proposal.proposalType == ProposalType.TERMINATION) {
            require(quorum >= 67, "Termination quorum not met");
            require(proposal.tokenVotes >= (totalVotes * 75) / 100, "Termination approval too low");
            require(block.timestamp >= proposal.voteStart + 7 days, "Delay not met");
        }
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}



    // --- Governance Logic Enhancements ---
    function getRequiredQuorum(ProposalType ptype) internal pure returns (uint256) {
        if (ptype == ProposalType.FUNDING) return 10;
        if (ptype == ProposalType.PARAM_UPDATE) return 15;
        if (ptype == ProposalType.TERMINATION) return 67;
        if (ptype == ProposalType.DAO_FORK) return 75;
        return 0;
    }

    function getRequiredApproval(ProposalType ptype) internal pure returns (uint256) {
        if (ptype == ProposalType.FUNDING) return 51;
        if (ptype == ProposalType.PARAM_UPDATE) return 60;
        if (ptype == ProposalType.TERMINATION) return 75;
        if (ptype == ProposalType.DAO_FORK) return 90;
        return 50;
    }

    function getTimeDelay(ProposalType ptype) internal pure returns (uint256) {
        if (ptype == ProposalType.FUNDING) return 1 days;
        if (ptype == ProposalType.PARAM_UPDATE) return 3 days;
        if (ptype == ProposalType.TERMINATION) return 7 days;
        if (ptype == ProposalType.DAO_FORK) return 14 days;
        return 0;
    }