// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VestingWrapper
 * @notice Simple vesting milestone tracker that depends on external oracles/registries
 *         for activity checks. Interfaces are kept minimal so the contract compiles
 *         without requiring those implementations in this repo.
 */

interface ICamuVerifyMinimal {
    function isVerified(address user) external view returns (bool);
}

interface IContentOracle {
    function hasPostedContent(address user) external view returns (bool);
    function hasVoted(address user) external view returns (bool);
}

interface IGatingMetrics {
    function hasIssuedCTDSG(address creator) external view returns (bool);
    function uniqueBuyerCount(address creator) external view returns (uint256);
}

contract VestingWrapper {
    ICamuVerifyMinimal public camuVerify;
    IGatingMetrics public gatingMetrics;
    IContentOracle public contentOracle;

    mapping(address => uint256) public unlockedMilestones;
    mapping(address => uint256) public unlockedTokens;

    constructor(address _verify, address _metrics, address _content) {
        camuVerify = ICamuVerifyMinimal(_verify);
        gatingMetrics = IGatingMetrics(_metrics);
        contentOracle = IContentOracle(_content);
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

