// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/StakingRewards.sol";

abstract contract StakingRewardsTargets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    uint256 canary_rewardDistributionTimestamp;
    uint256 canary_claimRewardsTimestamp;

    function property_canary_timeAdvanceBeforeClaimRewards() public {
        // If rewardsDistribution was updated, then claiming should only be allowed after that timestamp
        if (canary_rewardDistributionTimestamp != 0 && canary_claimRewardsTimestamp != 0) {
            eq(
                canary_claimRewardsTimestamp,
                canary_rewardDistributionTimestamp,
                "canary: claim rewards not advanced time"
            );
        }
    }
    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function stakingRewards_acceptOwnership() public asActor {
        stakingRewards.acceptOwnership();
    }

    function stakingRewards_exit() public updateGhosts asActor {
        stakingRewards.exit();
    }

    function stakingRewards_getReward() public updateGhosts asActor {
        stakingRewards.getReward();

        canary_claimRewardsTimestamp = block.timestamp;
    }

    function stakingRewards_nominateNewOwner(address _owner) public asActor {
        stakingRewards.nominateNewOwner(_owner);
    }

    function stakingRewards_notifyRewardAmount(uint256 reward) public updateGhosts asActor {
        stakingRewards.notifyRewardAmount(reward);

        _ghost_totalNotifiedReward += reward;
        canary_rewardDistributionTimestamp = block.timestamp;
    }

    function stakingRewards_recoverERC20(address tokenAddress, uint256 tokenAmount) public asActor {
        stakingRewards.recoverERC20(tokenAddress, tokenAmount);
    }

    function stakingRewards_setPaused(bool _paused) public updateGhosts asActor {
        stakingRewards.setPaused(_paused);
    }

    function stakingRewards_setRewardsDistribution(address _rewardsDistribution) public asActor {
        stakingRewards.setRewardsDistribution(_rewardsDistribution);
    }

    function stakingRewards_setRewardsDuration(uint256 _rewardsDuration) public updateGhosts asActor {
        stakingRewards.setRewardsDuration(_rewardsDuration);
    }

    function stakingRewards_stake(uint256 amount) public updateGhosts asActor {
        stakingRewards.stake(amount);
    }

    function stakingRewards_updatePeriodFinish(uint256 timestamp) public updateGhosts asActor {
        stakingRewards.updatePeriodFinish(timestamp);
    }

    function stakingRewards_withdraw(uint256 amount) public updateGhosts asActor {
        stakingRewards.withdraw(amount);
    }
}