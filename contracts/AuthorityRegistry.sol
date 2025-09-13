// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AuthorityRegistry
 * @notice Minimal on-chain registry to record that a legacy DAO address
 *         designates a controller (new DAO) address for operations.
 *         Intended for transparency only; not enforced by other contracts.
 */
contract AuthorityRegistry is Ownable {
    // identity (e.g., legacy DAO) => controller (e.g., new DAO)
    mapping(address => address) public controllerOf;

    event ControllerSet(address indexed identity, address indexed controller);

    function setController(address identity, address controller) external onlyOwner {
        require(identity != address(0) && controller != address(0), "Zero addr");
        controllerOf[identity] = controller;
        emit ControllerSet(identity, controller);
    }

    function getController(address identity) external view returns (address) {
        return controllerOf[identity];
    }
}

