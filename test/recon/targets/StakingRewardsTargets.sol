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


    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function stakingRewards_acceptOwnership() public asActor {
        stakingRewards.acceptOwnership();
    }

    function stakingRewards_exit() public asActor {
        stakingRewards.exit();
    }

    function stakingRewards_getReward() public asActor {
        stakingRewards.getReward();
    }

    function stakingRewards_nominateNewOwner(address _owner) public asActor {
        stakingRewards.nominateNewOwner(_owner);
    }

    function stakingRewards_notifyRewardAmount(uint256 reward) public asActor {
        stakingRewards.notifyRewardAmount(reward);
    }

    function stakingRewards_recoverERC20(address tokenAddress, uint256 tokenAmount) public asActor {
        stakingRewards.recoverERC20(tokenAddress, tokenAmount);
    }

    function stakingRewards_setPaused(bool _paused) public asActor {
        stakingRewards.setPaused(_paused);
    }

    function stakingRewards_setRewardsDistribution(address _rewardsDistribution) public asActor {
        stakingRewards.setRewardsDistribution(_rewardsDistribution);
    }

    function stakingRewards_setRewardsDuration(uint256 _rewardsDuration) public asActor {
        stakingRewards.setRewardsDuration(_rewardsDuration);
    }

    function stakingRewards_stake(uint256 amount) public asActor {
        stakingRewards.stake(amount);
    }

    function stakingRewards_updatePeriodFinish(uint256 timestamp) public asActor {
        stakingRewards.updatePeriodFinish(timestamp);
    }

    function stakingRewards_withdraw(uint256 amount) public asActor {
        stakingRewards.withdraw(amount);
    }
}