// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface ICamuVerify {
    function members(address) external view returns (uint16 birthYear, bool isVerified, bool isAdult);
    function verifiedCount() external view returns (uint256);
}

