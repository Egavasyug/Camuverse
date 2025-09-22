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
    mapping(address => bool) public hasClaimed;            // one-per-wallet guard
    mapping(address => uint256) public walletToTokenId;    // subscriber number == tokenId (sequential)
    uint256 public nextTokenId = 1;                        // sequential token/subscriber number
    uint256 public totalMinted;
    // Forwarder control
    address public trustedForwarder;                       // mutable trusted forwarder
    bool public requireForwarder = true;                   // when true, only forwarder may call claim()

    event Claimed(address indexed user, uint256 indexed tokenId, uint256 subscriberNo);

    constructor(address forwarder)
        ERC721("Early Access Token", "EARLY")
        ERC2771Context(forwarder)
    {
        trustedForwarder = forwarder;
    }

    /// @notice Mints a non-transferable Subscriber badge to the sender if they haven't received one
    function claim(string memory tokenURI) external {
        address sender = _msgSender();
        require(!hasClaimed[sender], "Already claimed");
        if (requireForwarder) {
            require(isTrustedForwarder(msg.sender), "Forwarder required");
        }
        uint256 tokenId = nextTokenId++;
        hasClaimed[sender] = true;            // effects before interactions
        walletToTokenId[sender] = tokenId;    // record subscriber number
        _safeMint(sender, tokenId);
        _setTokenURI(tokenId, tokenURI);      // Optional: add metadata (e.g. timestamp or campaign info)
        totalMinted++;
        emit Claimed(sender, tokenId, tokenId);
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
        uint256 tokenId = walletToTokenId[user];
        _burn(tokenId);
        hasClaimed[user] = false;
        // Note: subscriber numbers (tokenIds) are not recycled; keep history, set mapping to 0
        walletToTokenId[user] = 0;
        totalMinted--;
    }

    function getSubscriberNo(address user) external view returns (uint256) {
        return walletToTokenId[user];
    }

    // --- Admin controls ---
    function setTrustedForwarder(address newForwarder) external onlyOwner {
        require(newForwarder != address(0), "zero forwarder");
        trustedForwarder = newForwarder;
    }

    function setRequireForwarder(bool v) external onlyOwner {
        requireForwarder = v;
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

    // Override to use our mutable forwarder address
    function isTrustedForwarder(address forwarder) public view override returns (bool) {
        return forwarder == trustedForwarder;
    }
}
