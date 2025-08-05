// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CreatorToken.sol";
import "./CamuVerify.sol";

contract CreatorTokenFactory is Ownable {
    CamuVerify public camuVerify;
    address[] public allCreatorTokens;
    mapping(address => address[]) public creatorToTokens;

    event CreatorTokenDeployed(address indexed creator, address tokenAddress);

    constructor(address _camuVerify) {
        camuVerify = CamuVerify(_camuVerify);
    }

    function deployCreatorToken(string memory name, string memory symbol) external returns (address) {
        (, , bool isVerified) = camuVerify.members(msg.sender);
        require(isVerified, "Must be verified to deploy creator tokens");

        CreatorToken token = new CreatorToken(name, symbol, msg.sender);
        allCreatorTokens.push(address(token));
        creatorToTokens[msg.sender].push(address(token));

        emit CreatorTokenDeployed(msg.sender, address(token));
        return address(token);
    }

    function getAllTokens() external view returns (address[] memory) {
        return allCreatorTokens;
    }

    function getTokensByCreator(address creator) external view returns (address[] memory) {
        return creatorToTokens[creator];
    }
}
