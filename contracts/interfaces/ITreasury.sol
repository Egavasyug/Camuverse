// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasury {
    function requestWithdrawal(address payable to, uint256 amount) external returns (uint256);
    function balance() external view returns (uint256);
}
