// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

// Helpers
import {MockERC20} from "@recon/MockERC20.sol";


abstract contract Properties is BeforeAfter, Asserts {

    function property_totalSupply_eq_sum_user_balances() public {
        address[] memory actors = _getActors();
        uint256 sumBalances = 0;
         for (uint256 i = 0; i < actors.length; i++) {
            sumBalances += stakingRewards.balanceOf(actors[i]);
        }

        eq(
            stakingRewards.totalSupply(),
            sumBalances,
            "totalSupply should match sum of user balances"
        );
    }

    function property_staking_token_balance_gte_totalSupply() public {
        gte(
            stakingRewards.stakingToken().balanceOf(address(stakingRewards)),
            stakingRewards.totalSupply(),
            "staking token balance cannot cover total supply"
        );
    }

    function property_reward_token_balance_gte_users_earned_and_remaining_schedule() public {
        uint256 totalRewardOwed = __totalRewardOwedTilNow();

        uint256 remainingScheduledRewards;
        if (block.timestamp < stakingRewards.periodFinish()) {
            remainingScheduledRewards = (stakingRewards.periodFinish() - block.timestamp) * stakingRewards.rewardRate();
        }

        gte(
            stakingRewards.rewardsToken().balanceOf(address(stakingRewards)),
            totalRewardOwed + remainingScheduledRewards,
            "reward token balance cannot cover total rewards owed to users plus remaining schedule"
        );
    }

    function property_rewardPerToken_stable_during_no_active_rewards() public {
         if (_before.rewardState == RewardState.NO_ACTIVE_REWARDS){

            uint256 before_rewardPerToken = __rewardPerToken(_before);
            uint256 after_rewardPerToken = __rewardPerToken(_after);

             eq(
                 before_rewardPerToken,
                 after_rewardPerToken,
                 "rewardPerToken should not change when there are no active rewards"
             );
         }
    }

    function property_rewardRate_not_decrease_with_active_stakers() public {
        if (
            _before.rewardState == RewardState.ACTIVE_REWARDS 
            && _before.stakeState == StakeState.STAKING
        ) {
            gte(
                _after.rewardRate,
                _before.rewardRate,
                "reward rate should not decrease when there are active rewards and stakers"
            );
        }
    }
    
    /// @dev Active rewards with no stakers can lock rewards. Even with `recoverERC20()`,
    /// the protocol needs extra accounting to recover those rewards without affecting users.
    function property_no_active_rewards_without_stakers() public {
        bool activeRewardsWithoutStakers = (
            _after.rewardState == RewardState.ACTIVE_REWARDS
            && _after.stakeState == StakeState.NO_STAKE
        );

        t(
            !activeRewardsWithoutStakers,
            "should not enter active rewards if there are no stakers"
        );
    }

    /// @dev User zero-balance since with no prior stake,
    /// any immediate rewards after `stake()` must come from rewards accrued before the stake existed. 
    /// Existing stakers can accrue rewards on their old balance, which might make this check noisy.
    function property_stake_from_zero_does_not_capture_prior_rewards() public {
        if(
            _before.actor_stakeState == StakeState.NO_STAKE
            && _after.actor_stakeState == StakeState.STAKING
        ) {
            eq(
                __earned_rewards(_after),
                __earned_rewards(_before),
                "staking from zero balance should not capture prior rewards"
            );
        }
    }

    function property_actor_earned_rewards_not_decrease_except_claim() public {
        if(
            currentOperation != OpType.CLAIM_REWARDS 
            && currentOperation != OpType.EXIT
        ) {
            gte(
                __earned_rewards(_after),
                __earned_rewards(_before),
                "actor rewards should not decrease except when claiming rewards"
            );
        }
    }

    function property_reward_config_changes_do_not_reduce_actor_owed() public {
        if (
            currentOperation == OpType.ADD_REWARDS
            || currentOperation == OpType.REWARD_CONFIG
        ) {
            gte(
                __earned_rewards(_after),
                __earned_rewards(_before),
                "reward config change reduced total owed rewards"
            );
        }
    }

    function property_no_stake_actor_earned_not_increase() public {
        if (_before.stakeState == StakeState.NO_STAKE) {
            lte(
                __earned_rewards(_after),
                __earned_rewards(_before),
                "actor earned rewards increased while totalSupply was zero"
            );
        }
    }

    function property_no_reactivate_rewards_without_notify() public {
        if (
            _before.rewardState == RewardState.NO_ACTIVE_REWARDS
            && _after.rewardState == RewardState.ACTIVE_REWARDS
        ) {
            t(
                currentOperation == OpType.ADD_REWARDS,
                "other operations can re-activate rewards"
            );
        }
    }

    function property_paused_totalSupply_not_increase() public {
        if (_before.paused) {
            lte(
                _after.totalSupply,
                _before.totalSupply,
                "total supply should not increase while paused"
            );
        }
    } 

}