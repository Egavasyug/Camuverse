// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CamuCoin is ERC20, Ownable {
    uint256 public daoFee = 1; // 1% fee to DAO
    uint256 public lpFee = 2;  // 2% fee to LP vault

    address public daoWallet;
    address public lpWallet;  // This will now point to the CAMT staking vault

    mapping(address => bool) public isExcludedFromFees;

    constructor(address _daoWallet, address _lpVault) ERC20("CamuCoin", "CAMC") {
        daoWallet = _daoWallet;
        lpWallet = _lpVault;
        isExcludedFromFees[_daoWallet] = true;
        isExcludedFromFees[_lpVault] = true;
        isExcludedFromFees[msg.sender] = true;
    }

    function setFees(uint256 _daoFee, uint256 _lpFee) external onlyOwner {
        require(_daoFee + _lpFee <= 10, "Total fee too high");
        daoFee = _daoFee;
        lpFee = _lpFee;
    }

    function setWallets(address _daoWallet, address _lpVault) external onlyOwner {
        daoWallet = _daoWallet;
        lpWallet = _lpVault;
    }

    function setFeeExclusion(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 daoAmount = (amount * daoFee) / 100;
            uint256 lpAmount = (amount * lpFee) / 100;
            uint256 remaining = amount - daoAmount - lpAmount;

            super._transfer(sender, daoWallet, daoAmount);
            super._transfer(sender, lpWallet, lpAmount);
            super._transfer(sender, recipient, remaining);
        }
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}


    // === Initial Mint Logic (One-Time Execution) ===
    bool public initialMinted = false;

    function initialMint(
        address treasuryWallet,
        address vestingWrapperWallet,
        address lpOrFoundersWallet
    ) external onlyOwner {
        require(!initialMinted, "Initial mint already performed");
        require(treasuryWallet != address(0), "Treasury wallet cannot be zero address");
        require(vestingWrapperWallet != address(0), "Vesting wallet cannot be zero address");
        require(lpOrFoundersWallet != address(0), "Founders wallet cannot be zero address");

        uint256 total = 2_000_000 ether;
        uint256 toTreasury = 1_200_000 ether;
        uint256 toVesting = 400_000 ether;
        uint256 toLP = 400_000 ether;

        _mint(treasuryWallet, toTreasury);
        _mint(vestingWrapperWallet, toVesting);
        _mint(lpOrFoundersWallet, toLP);

        initialMinted = true;
    }
