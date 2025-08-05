
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketplace is Ownable {
    IERC20 public camuCoin;

    address public founderWallet;
    address public daoTreasury;
    uint256 public marketFeePercent = 2; // 2%
    uint256 public founderPercentage = 50; // 50% of fee goes to founder

    struct Listing {
        uint256 id;
        address seller;
        string item;
        uint256 price;
        bool sold;
    }

    uint256 public nextListingId;
    mapping(uint256 => Listing) public listings;

    event ItemListed(uint256 id, address seller, string item, uint256 price);
    event ItemPurchased(uint256 id, address buyer);

    constructor(
        address _camuCoinAddress,
        address _founderWallet,
        address _daoTreasury
    ) Ownable(msg.sender) {
        require(_founderWallet != address(0) && _daoTreasury != address(0), "Invalid address");
        camuCoin = IERC20(_camuCoinAddress);
        founderWallet = _founderWallet;
        daoTreasury = _daoTreasury;
    }

    function listItem(string memory _item, uint256 _price) external {
        listings[nextListingId] = Listing(nextListingId, msg.sender, _item, _price, false);
        emit ItemListed(nextListingId, msg.sender, _item, _price);
        nextListingId++;
    }

    function purchaseItem(uint256 _id) external {
        Listing storage listing = listings[_id];
        require(!listing.sold, "Item already sold");

        uint256 fee = (listing.price * marketFeePercent) / 100;
        uint256 founderCut = (fee * founderPercentage) / 100;
        uint256 daoCut = fee - founderCut;
        uint256 sellerAmount = listing.price - fee;

        require(camuCoin.transferFrom(msg.sender, listing.seller, sellerAmount), "Payment to seller failed");
        require(camuCoin.transferFrom(msg.sender, founderWallet, founderCut), "Payment to founder failed");
        require(camuCoin.transferFrom(msg.sender, daoTreasury, daoCut), "Payment to DAO failed");

        listing.sold = true;
        emit ItemPurchased(_id, msg.sender);
    }

    // Admin controls
    function updateFeeSettings(uint256 _feePercent, uint256 _founderShare) external onlyOwner {
        require(_feePercent <= 100 && _founderShare <= 100, "Invalid values");
        marketFeePercent = _feePercent;
        founderPercentage = _founderShare;
    }

    function updateWallets(address _founder, address _treasury) external onlyOwner {
        require(_founder != address(0) && _treasury != address(0), "Invalid address");
        founderWallet = _founder;
        daoTreasury = _treasury;
    }
}
