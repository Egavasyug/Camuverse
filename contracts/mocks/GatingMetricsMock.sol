// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal gating metrics mock compatible with VestingWrapper expectations.
// Allows an admin to set issuance flags and unique buyer counts per creator.
contract GatingMetricsMock {
    address public admin;

    mapping(address => bool) private _issued;
    mapping(address => uint256) private _buyers;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function setIssuedCTDSG(address creator, bool val) external onlyAdmin {
        _issued[creator] = val;
    }

    function setUniqueBuyerCount(address creator, uint256 count) external onlyAdmin {
        _buyers[creator] = count;
    }

    function hasIssuedCTDSG(address creator) external view returns (bool) {
        return _issued[creator];
    }

    function uniqueBuyerCount(address creator) external view returns (uint256) {
        return _buyers[creator];
    }
}
