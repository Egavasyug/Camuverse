// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title EarlyAccessSBT
 * @notice Subscriber Badge Token (SBT) for early access / wallet registration
 */
contract EarlyAccessSBT is ERC721URIStorage, Ownable {
    mapping(address => bool) public hasClaimed;
    uint256 public totalMinted;

    constructor() ERC721("Early Access Token", "EARLY") {}

    /// @notice Mints a non-transferable Subscriber badge to the sender if they haven't received one
    function claim(string memory tokenURI) external {
        require(!hasClaimed[msg.sender], "Already claimed");
        uint256 tokenId = uint256(uint160(msg.sender)); // Token ID derived from wallet address
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI); // Optional: add metadata (e.g. timestamp or campaign info)
        hasClaimed[msg.sender] = true;
        totalMinted++;
    }

    /// @notice Override transfer functions to enforce non-transferability (Subscriber badge)
    function _transfer(address, address, uint256) internal pure override {
        revert("Subscriber: transfer not allowed");
    }

    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert("Subscriber: approvals not allowed");
    }

    function setApprovalForAll(address, bool) public pure override(ERC721, IERC721) {
        revert("Subscriber: approvals not allowed");
    }

    /// @notice Owner can burn token if needed (e.g. to reset)
    function burn(address user) external onlyOwner {
        require(hasClaimed[user], "No token");
        uint256 tokenId = uint256(uint160(user));
        _burn(tokenId);
        hasClaimed[user] = false;
        totalMinted--;
    }
}
