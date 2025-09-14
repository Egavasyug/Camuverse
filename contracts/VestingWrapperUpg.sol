// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ICamuVerifyMinimalUpg {
    function isVerified(address user) external view returns (bool);
}

interface IContentOracleUpg {
    function hasPostedContent(address user) external view returns (bool);
    function hasVoted(address user) external view returns (bool);
}

interface IGatingMetricsUpg {
    function hasIssuedCTDSG(address creator) external view returns (bool);
    function uniqueBuyerCount(address creator) external view returns (uint256);
}

contract VestingWrapperUpg is Initializable, OwnableUpgradeable {
    ICamuVerifyMinimalUpg public camuVerify;
    IGatingMetricsUpg public gatingMetrics;
    IContentOracleUpg public contentOracle;

    mapping(address => uint256) public unlockedMilestones;
    mapping(address => uint256) public unlockedTokens;

    function initialize(
        address _verify,
        address _metrics,
        address _content,
        address _owner
    ) external initializer {
        __Ownable_init();
        require(_verify != address(0) && _metrics != address(0) && _content != address(0), "zero addr");
        camuVerify = ICamuVerifyMinimalUpg(_verify);
        gatingMetrics = IGatingMetricsUpg(_metrics);
        contentOracle = IContentOracleUpg(_content);
        if (_owner != address(0) && _owner != owner()) {
            _transferOwnership(_owner);
        }
    }

    function setVerify(address _verify) external onlyOwner {
        require(_verify != address(0), "zero addr");
        camuVerify = ICamuVerifyMinimalUpg(_verify);
    }

    function setMetrics(address _metrics) external onlyOwner {
        require(_metrics != address(0), "zero addr");
        gatingMetrics = IGatingMetricsUpg(_metrics);
    }

    function setContentOracle(address _content) external onlyOwner {
        require(_content != address(0), "zero addr");
        contentOracle = IContentOracleUpg(_content);
    }

    function unlockForVerification(address influencer) external {
        require(camuVerify.isVerified(influencer), "Not verified");
        unlockedMilestones[influencer] = 1;
        unlockedTokens[influencer] += 1000;
    }

    function unlockNextMilestone(address influencer) external {
        uint256 milestone = unlockedMilestones[influencer];

        if (milestone == 1 && contentOracle.hasPostedContent(influencer)) {
            unlockedMilestones[influencer] = 2;
            unlockedTokens[influencer] += 2000;
        } else if (milestone == 2 && gatingMetrics.hasIssuedCTDSG(influencer)) {
            unlockedMilestones[influencer] = 3;
            unlockedTokens[influencer] += 2000;
        } else if (milestone == 3 && gatingMetrics.uniqueBuyerCount(influencer) >= 5) {
            unlockedMilestones[influencer] = 4;
            unlockedTokens[influencer] += 2500;
        } else if (milestone == 4 && contentOracle.hasVoted(influencer)) {
            unlockedMilestones[influencer] = 5;
            unlockedTokens[influencer] += 2500;
        }
    }

    function getUnlockedTokens(address influencer) external view returns (uint256) {
        return unlockedTokens[influencer];
    }
}

