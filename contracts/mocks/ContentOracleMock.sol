// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal content oracle mock compatible with VestingWrapper expectations.
// Allows an admin to set simple flags for posted content and voted state.
contract ContentOracleMock {
    address public admin;

    mapping(address => bool) private _posted;
    mapping(address => bool) private _voted;

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

    function setPostedContent(address user, bool val) external onlyAdmin {
        _posted[user] = val;
    }

    function setVoted(address user, bool val) external onlyAdmin {
        _voted[user] = val;
    }

    function hasPostedContent(address user) external view returns (bool) {
        return _posted[user];
    }

    function hasVoted(address user) external view returns (bool) {
        return _voted[user];
    }
}
