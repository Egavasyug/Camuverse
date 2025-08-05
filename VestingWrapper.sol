// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CamuVerify.sol";
import "./GatingRegistry.sol";

contract VestingWrapper {
    CamuVerify public camuVerify;
    GatingRegistry public gatingRegistry;

    mapping(address => uint) public unlockedMilestones;
    mapping(address => uint) public unlockedTokens;

    constructor(address _verify, address _registry) {
        camuVerify = CamuVerify(_verify);
        gatingRegistry = GatingRegistry(_registry);
    }

    function unlockForVerification(address influencer) external {
        require(camuVerify.isVerified(influencer), "Not verified");
        unlockedMilestones[influencer] = 1;
        unlockedTokens[influencer] += 1000;
    }

    function unlockNextMilestone(address influencer) external {
        uint milestone = unlockedMilestones[influencer];

        if (milestone == 1 && camuVerify.hasPostedContent(influencer)) {
            unlockedMilestones[influencer] = 2;
            unlockedTokens[influencer] += 2000;
        } else if (milestone == 2 && gatingRegistry.hasIssuedCTDSG(influencer)) {
            unlockedMilestones[influencer] = 3;
            unlockedTokens[influencer] += 2000;
        } else if (milestone == 3 && gatingRegistry.uniqueBuyerCount(influencer) >= 5) {
            unlockedMilestones[influencer] = 4;
            unlockedTokens[influencer] += 2500;
        } else if (milestone == 4 && camuVerify.hasVoted(influencer)) {
            unlockedMilestones[influencer] = 5;
            unlockedTokens[influencer] += 2500;
        }
    }

    function getUnlockedTokens(address influencer) external view returns (uint) {
        return unlockedTokens[influencer];
    }
}
