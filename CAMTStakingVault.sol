// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CAMTStakingVault {
    IERC20 public camtToken;
    IERC20 public camcToken;

    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public lastUpdate;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewardDebt;

    address public admin;

    constructor(address _camt, address _camc) {
        camtToken = IERC20(_camt);
        camcToken = IERC20(_camc);
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Nothing to stake");
        camtToken.transferFrom(msg.sender, address(this), amount);
        _claim(msg.sender);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
    }

    function unstake(uint256 amount) external {
        require(stakedBalance[msg.sender] >= amount, "Insufficient stake");
        _claim(msg.sender);
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        camtToken.transfer(msg.sender, amount);
    }

    function _claim(address user) internal {
        if (rewardPool > 0 && totalStaked > 0) {
            uint256 owed = (rewardPool * stakedBalance[user]) / totalStaked - rewardDebt[user];
            if (owed > 0) {
                camcToken.transfer(user, owed);
                rewardDebt[user] += owed;
            }
        }
    }

    function claimRewards() external {
        _claim(msg.sender);
    }

    function distributeRewards(uint256 amount) external onlyAdmin {
        require(amount > 0, "No reward to distribute");
        camcToken.transferFrom(msg.sender, address(this), amount);
        rewardPool += amount;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function viewOwed(address user) external view returns (uint256) {
        if (rewardPool == 0 || totalStaked == 0) return 0;
        return (rewardPool * stakedBalance[user]) / totalStaked - rewardDebt[user];
    }
}
