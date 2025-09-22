// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

/// @title CamuverseForwarder
/// @notice OZ MinimalForwarder wrapper used for ERC-2771 meta-transactions
contract CamuverseForwarder is MinimalForwarder {}
