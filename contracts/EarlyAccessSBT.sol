// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/**
 * @title EarlyAccessSBT
 * @notice Subscriber Badge Token (SBT) for early access / wallet registration
 */
contract EarlyAccessSBT is ERC721URIStorage, Ownable, ERC2771Context {
    mapping(address => bool) public hasClaimed;
    mapping(address => uint256) public subscriberNo; // sequential display number per wallet
    uint256 public nextSubscriberNo = 1; // starts at 1
    uint256 public totalMinted;

    event Claimed(address indexed user, uint256 indexed tokenId, uint256 subscriberNo);

    constructor(address trustedForwarder)
        ERC721("Early Access Token", "EARLY")
        ERC2771Context(trustedForwarder)
    {}

    /// @notice Mints a non-transferable Subscriber badge to the sender if they haven't received one
    function claim(string memory tokenURI) external {
        address sender = _msgSender();
        require(!hasClaimed[sender], "Already claimed");
        uint256 tokenId = uint256(uint160(sender)); // Token ID derived from wallet address
        hasClaimed[sender] = true; // effects before interactions
        uint256 sn = nextSubscriberNo++;
        subscriberNo[sender] = sn;
        _safeMint(sender, tokenId);
        _setTokenURI(tokenId, tokenURI); // Optional: add metadata (e.g. timestamp or campaign info)
        totalMinted++;
        emit Claimed(sender, tokenId, sn);
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
        if (subscriberNo[user] != 0) {
            // Note: subscriber numbers are not recycled; keep history
        }
        totalMinted--;
    }

    function getSubscriberNo(address user) external view returns (uint256) {
        return subscriberNo[user];
    }

    // ERC2771 meta-tx overrides
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return ERC2771Context._contextSuffixLength();
    }
}
