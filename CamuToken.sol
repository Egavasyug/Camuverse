
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CamuToken is ERC20, Ownable {
    address public founderWallet;
    address public daoTreasury;
    uint256 public mintFee = 0.02 ether;
    uint256 public founderPercentage = 20; // 20%

    constructor(
        uint256 initialSupply,
        address initialOwner,
        address _founderWallet,
        address _daoTreasury
    ) ERC20("CamuToken", "CAMT") Ownable(initialOwner) {
        require(_founderWallet != address(0) && _daoTreasury != address(0), "Invalid address");
        founderWallet = _founderWallet;
        daoTreasury = _daoTreasury;
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mintWithFee(uint256 amount) external payable {
        require(msg.value >= mintFee, "Insufficient mint fee");
        uint256 founderCut = (msg.value * founderPercentage) / 100;
        uint256 daoCut = msg.value - founderCut;

        payable(founderWallet).transfer(founderCut);
        payable(daoTreasury).transfer(daoCut);

        _mint(msg.sender, amount);
    }

    function updateMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
    }

    function updateFounderPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 100, "Percentage too high");
        founderPercentage = newPercentage;
    }

    function updateWallets(address newFounderWallet, address newDaoTreasury) external onlyOwner {
        require(newFounderWallet != address(0) && newDaoTreasury != address(0), "Invalid address");
        founderWallet = newFounderWallet;
        daoTreasury = newDaoTreasury;
    }
}
