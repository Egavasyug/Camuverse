
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSigTreasury is Ownable {
    uint256 public requiredApprovals;
    address[] public signers;
    address public daoAddress;

    struct Withdrawal {
        address payable to;
        uint256 amount;
        uint256 approvals;
        bool executed;
    }

    uint256 public nextWithdrawalId;
    mapping(uint256 => Withdrawal) public withdrawals;
    mapping(uint256 => mapping(address => bool)) public approvals;

    event FundsDeposited(address from, uint256 amount);
    event WithdrawalRequested(uint256 id, address to, uint256 amount);
    event WithdrawalApproved(uint256 id, address approver);
    event WithdrawalExecuted(uint256 id, address to, uint256 amount);

    modifier onlySigner() {
        require(isSigner(msg.sender), "Only signers can call this function");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can request withdrawal");
        _;
    }

    constructor(address[] memory _signers, uint256 _requiredApprovals) Ownable(msg.sender) {
        require(_signers.length >= _requiredApprovals && _requiredApprovals > 0, "Invalid signer setup");
        signers = _signers;
        requiredApprovals = _requiredApprovals;
    }

    function deposit() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function setDAO(address _daoAddress) external onlyOwner {
        require(_daoAddress != address(0), "Invalid DAO address");
        daoAddress = _daoAddress;
    }

    function requestWithdrawal(address payable _to, uint256 _amount) external onlyDAO returns (uint256) {
        uint256 id = nextWithdrawalId++;
        withdrawals[id] = Withdrawal(_to, _amount, 0, false);
        emit WithdrawalRequested(id, _to, _amount);
        return id;
    }

    function approveWithdrawal(uint256 id) external onlySigner {
        Withdrawal storage w = withdrawals[id];
        require(!w.executed, "Already executed");
        require(!approvals[id][msg.sender], "Already approved");

        approvals[id][msg.sender] = true;
        w.approvals++;

        emit WithdrawalApproved(id, msg.sender);

        if (w.approvals >= requiredApprovals) {
            w.executed = true;
            (bool sent, ) = w.to.call{value: w.amount}("");
            require(sent, "Transfer failed");
            emit WithdrawalExecuted(id, w.to, w.amount);
        }
    }

    function isSigner(address account) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == account) return true;
        }
        return false;
    }
}
