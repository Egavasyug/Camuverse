// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreatorToken is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;

    constructor(string memory name, string memory symbol, address owner) ERC721(name, symbol) {
        tokenCounter = 0;
        transferOwnership(owner);
    }

    function mint(address to, string memory tokenURI) external onlyOwner {
        uint256 newTokenId = tokenCounter;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        tokenCounter++;
    }
}
