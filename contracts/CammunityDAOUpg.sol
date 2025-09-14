// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./ICamuVerify.sol";
import "./ICamuToken.sol";
import "./ICamuCoin.sol";
import "./interfaces/ITreasury.sol";

import "./interfaces/ITreasury.sol";

contract CammunityDAO is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    function contractName() external pure returns (string memory) { return "CammunityDAO"; }
    ICamuVerify public camuVerify;
    ICamuCoin public camuCoin;
    ICamuToken public camuToken;
    ITreasury public treasury;

    address public bootstrapAdmin;
    bool public setupFinalized;

    uint256 public proposalCount;
    uint256 public lastResetMonth;
    uint256 public monthlySpent;

    uint256 public stage1ThresholdPercent;
    uint256 public stage1Duration;
    uint256 public stage2Duration;

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
        address callTarget;
        bytes callData;
        }

    mapping(uint256 => Proposal) public proposals;

    event NewProposal(uint256 indexed id, string description, ProposalType proposalType);
    event ProposalExecuted(uint256 indexed id);
    event CamuVerifyUpdated(address indexed newAddr);
    event CamuCoinUpdated(address indexed newAddr);
    event CamuTokenUpdated(address indexed newAddr);
    event TreasuryUpdated(address indexed newAddr);
    event SetupFinalized(address indexed admin);

    modifier onlyDAO() {
        require(msg.sender == address(this), "Only DAO");
        _;
    }

    function initialize(
        address _camuVerify,
        address _camuCoin,
        address _camuToken,
        address _treasury,
        address _bootstrapAdmin
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        camuVerify = ICamuVerify(_camuVerify);
        camuCoin = ICamuCoin(_camuCoin);
        camuToken = ICamuToken(_camuToken);
        treasury = ITreasury(_treasury);
        lastResetMonth = block.timestamp / 30 days;
        stage1ThresholdPercent = 10; // 10%
        stage1Duration = 3 days;
        stage2Duration = 7 days;
        bootstrapAdmin = _bootstrapAdmin;
    }

    function updateStage1Threshold(uint256 percent) external onlyDAO {
        require(percent >= 5 && percent <= 50, "Invalid threshold");
        stage1ThresholdPercent = percent;
    }

    function updateDurations(uint256 s1, uint256 s2) external onlyDAO {
        require(s1 >= 1 days && s1 <= 14 days, "s1 out of range");
        require(s2 >= 1 days && s2 <= 30 days, "s2 out of range");
        stage1Duration = s1;
        stage2Duration = s2;
    }

    function bootstrapSetAddresses(
        address _camuVerify,
        address _camuCoin,
        address _camuToken,
        address _treasury
    ) external {
        require(msg.sender == bootstrapAdmin, "Only bootstrap");
        require(!setupFinalized, "Setup finalized");
        require(_camuVerify != address(0) && _camuCoin != address(0) && _camuToken != address(0) && _treasury != address(0), "Zero addr");
        camuVerify = ICamuVerify(_camuVerify);
        camuCoin = ICamuCoin(_camuCoin);
        camuToken = ICamuToken(_camuToken);
        treasury = ITreasury(_treasury);
        emit CamuVerifyUpdated(_camuVerify);
        emit CamuCoinUpdated(_camuCoin);
        emit CamuTokenUpdated(_camuToken);
        emit TreasuryUpdated(_treasury);
    }

    function finalizeSetup() external {
        require(msg.sender == bootstrapAdmin, "Only bootstrap");
        require(!setupFinalized, "Setup finalized");
        setupFinalized = true;
        emit SetupFinalized(bootstrapAdmin);
        bootstrapAdmin = address(0);
    }

    function updateCamuVerify(address a) external onlyDAO {
        require(a != address(0), "Zero addr");
        camuVerify = ICamuVerify(a);
        emit CamuVerifyUpdated(a);
    }

    function updateCamuCoin(address a) external onlyDAO {
        require(a != address(0), "Zero addr");
        camuCoin = ICamuCoin(a);
        emit CamuCoinUpdated(a);
    }

    function updateCamuToken(address a) external onlyDAO {
        require(a != address(0), "Zero addr");
        camuToken = ICamuToken(a);
        emit CamuTokenUpdated(a);
    }

    function updateTreasury(address a) external onlyDAO {
        require(a != address(0), "Zero addr");
        treasury = ITreasury(a);
        emit TreasuryUpdated(a);
    }

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
     * @notice Create a configuration proposal that, upon passing Stage 2, executes a call.
     *         Use for DAO self-calls (e.g., updateDurations/threshold) or owned contracts (e.g., CamuVerify.addVerifier).
     */
    function createConfigProposal(
        string memory description,
        address target,
        bytes calldata data
    ) external {
        require(camuCoin.balanceOf(msg.sender) > 0, "Must hold CAMC");
        require(target != address(0), "No target");
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.description = description;
        p.proposalType = ProposalType.TEXT; // keep enum stable; use call data to indicate executable
        p.target = payable(address(0));
        p.amount = 0;
        p.callTarget = target;
        p.callData = data;
        p.voteStart = block.timestamp;
        p.stage1Deadline = p.voteStart + stage1Duration;
        p.stage2Deadline = p.stage1Deadline + stage2Duration;
        emit NewProposal(proposalCount, description, ProposalType.TEXT);
        proposalCount++;
    }

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

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage p = proposals[proposalId];
        require(p.stage1Passed, "Stage1 not passed");
        require(!p.executed, "Executed");
        require(block.timestamp > p.stage2Deadline, "Voting not ended");
        uint256 totalVotes = camuToken.totalSupply();
        require(totalVotes > 0, "No CAMT supply");
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
        if (p.callTarget != address(0) && p.callData.length > 0) {
            (bool ok, ) = p.callTarget.call(p.callData);
            require(ok, "Call failed" );
        }

        p.executed = true;
        emit ProposalExecuted(proposalId);
    }
}



