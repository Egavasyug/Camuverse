// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ICamuVerify.sol";
import "./ICamuToken.sol";
import "./ICamuCoin.sol";

/**
 * @title ModifiedCammunityDAO
 * @notice Two-stage governance: Stage 1 (verified CAMC holders) + Stage 2 (token-weighted CAMT),
 *         with monthly spend caps and optional termination safeguards.
 */
interface ITreasury {
    function requestWithdrawal(address payable to, uint256 amount) external returns (uint256);
    function balance() external view returns (uint256);
}

contract ModifiedCammunityDAO is Ownable, ReentrancyGuard {
    ICamuVerify public camuVerify;
    ICamuCoin public camuCoin;
    ICamuToken public camuToken;
    ITreasury public treasury;

    // total number of proposals created
    uint256 public proposalCount;
    // used to reset monthly spending limits
    uint256 public lastResetMonth;
    // amount spent in the current month
    uint256 public monthlySpent;

    /**
     * @notice Stage 1 quorum as a percentage of verified members.
     *         Proposals must get at least (verifiedCount * stage1ThresholdPercent / 100) yes votes.
     */
    uint256 public stage1ThresholdPercent = 10; // 10%

    // Timeframes for voting windows
    // stage1Duration: time from creation for Stage 1 voting
    // stage2Duration: time after Stage 1 for Stage 2 voting
    uint256 public stage1Duration = 3 days;
    uint256 public stage2Duration = 7 days;

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
        uint256 stage1Deadline;
        uint256 stage2Deadline;
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
    ) Ownable() {
        camuVerify = ICamuVerify(_camuVerify);
        camuCoin = ICamuCoin(_camuCoin);
        camuToken = ICamuToken(_camuToken);
        treasury = ITreasury(_treasury);
        lastResetMonth = block.timestamp / 30 days;
    }

    /**
     * @notice Update Stage 1 quorum threshold. Only callable by DAO (self) via executed proposal.
     */
    function updateStage1Threshold(uint256 percent) external {
        require(msg.sender == address(this), "Only DAO");
        require(percent >= 5 && percent <= 50, "Invalid threshold");
        stage1ThresholdPercent = percent;
    }

    /**
     * @notice Update voting durations. Only callable by DAO (self) via executed proposal.
     */
    function updateDurations(uint256 s1, uint256 s2) external {
        require(msg.sender == address(this), "Only DAO");
        require(s1 >= 1 days && s1 <= 14 days, "s1 out of range");
        require(s2 >= 1 days && s2 <= 30 days, "s2 out of range");
        stage1Duration = s1;
        stage2Duration = s2;
    }

    /**
     * @notice Any CAMC holder can create a proposal.
     */
    function createProposal(
        string memory description,
        ProposalType proposalType,
        address payable target,
        uint256 amount
    ) external {
        require(camuCoin.balanceOf(msg.sender) > 0, "Must hold CAMC");
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.description = description;
        p.proposalType = proposalType;
        p.target = target;
        p.amount = amount;
        p.voteStart = block.timestamp;
        p.stage1Deadline = p.voteStart + stage1Duration;
        p.stage2Deadline = p.stage1Deadline + stage2Duration;
        emit NewProposal(proposalCount, description, proposalType);
        proposalCount++;
    }

    /**
     * @notice Stage 1 (verified members with CAMC), threshold-based and time-bound.
     */
    function voteStage1(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(!p.verifiedVoted[msg.sender], "Voted stage1");
        (, , bool isVerified) = camuVerify.members(msg.sender);
        require(isVerified, "Not verified");
        require(camuCoin.balanceOf(msg.sender) > 0, "No CAMC");
        require(block.timestamp <= p.stage1Deadline, "Stage1 ended");
        p.verifiedVotes++;
        p.verifiedVoted[msg.sender] = true;
        uint256 required = (camuVerify.verifiedCount() * stage1ThresholdPercent + 99) / 100;
        if (required < 3) required = 3;
        if (p.verifiedVotes >= required) p.stage1Passed = true;
    }

    /**
     * @notice Stage 2 (token-weighted CAMT), only after stage1 passes and before stage2 deadline.
     */
    function voteStage2(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(p.stage1Passed, "Stage1 not passed");
        require(!p.tokenVoted[msg.sender], "Voted stage2");
        require(block.timestamp <= p.stage2Deadline, "Stage2 ended");
        uint256 weight = camuToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        p.tokenVotes += weight;
        p.tokenVoted[msg.sender] = true;
    }

    /**
     * @notice Execute after stage2 window ends. Applies budget caps for FUNDING and strict rules for TERMINATION.
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage p = proposals[proposalId];
        require(p.stage1Passed, "Stage1 not passed");
        require(!p.executed, "Executed");
        require(block.timestamp > p.stage2Deadline, "Voting not ended");
        uint256 totalVotes = camuToken.totalSupply();
        uint256 quorum = (p.tokenVotes * 100) / totalVotes;

        if (p.proposalType == ProposalType.FUNDING) {
            uint256 currentMonth = block.timestamp / 30 days;
            if (currentMonth > lastResetMonth) { lastResetMonth = currentMonth; monthlySpent = 0; }
            uint256 treasuryBalance = address(treasury).balance;
            uint256 maxMonthlySpend = (treasuryBalance * 15) / 100;
            if (p.amount + monthlySpent > maxMonthlySpend) {
                require(quorum >= 67, "Special quorum for excess budget");
            }
            monthlySpent += p.amount;
            treasury.requestWithdrawal(p.target, p.amount);
        }

        if (p.proposalType == ProposalType.TERMINATION) {
            require(quorum >= 67, "Termination quorum");
            require(p.tokenVotes >= (totalVotes * 75) / 100, "Termination approval");
            require(block.timestamp >= p.voteStart + 7 days, "Delay not met");
        }

        p.executed = true;
        emit ProposalExecuted(proposalId);
    }
}

