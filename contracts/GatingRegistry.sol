
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface ICamuVerify {
    function isVerified(address user) external view returns (bool);
}

contract GatingRegistry {
    address public admin;
    ICamuVerify public camuVerify;

    // Creator => Gating Token (ERC721 or ERC1155 address)
    mapping(address => address) public creatorGatingToken;

    event GatingTokenRegistered(address indexed creator, address indexed tokenAddress);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(address _camuVerify) {
        admin = msg.sender;
        camuVerify = ICamuVerify(_camuVerify);
    }

    function registerGatingToken(address tokenAddress) external {
        require(camuVerify.isVerified(msg.sender), "Must be verified");
        require(tokenAddress != address(0), "Invalid token address");
        creatorGatingToken[msg.sender] = tokenAddress;
        emit GatingTokenRegistered(msg.sender, tokenAddress);
    }

    function hasAccess(address creator, address viewer) external view returns (bool) {
        address token = creatorGatingToken[creator];
        if (token == address(0)) return false;

        try IERC721(token).balanceOf(viewer) returns (uint256 bal) {
            return bal > 0 && camuVerify.isVerified(viewer);
        } catch {
            return false;
        }
    }

    function updateVerifyContract(address newVerify) external onlyAdmin {
        camuVerify = ICamuVerify(newVerify);
    }
}
