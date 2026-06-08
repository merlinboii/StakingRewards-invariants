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

import {MockERC20} from "@recon/MockERC20.sol";


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
            lte(
                canary_claimRewardsTimestamp,
                canary_rewardDistributionTimestamp,
                "canary: claim rewards not advanced time"
            );
        }
    }

    ///@dev fund rewardsToken first, then notify a bounded reward amount.
    function stakingRewards_fund_then_notifyRewardAmount(uint256 rewards) public {
        MockERC20(address(stakingRewards.rewardsToken())).mint(address(stakingRewards), rewards);
        stakingRewards_notifyRewardAmount(rewards);
    }

    /// @dev new period finish >= current period finish
    /// @dev secondsAdjust == 0, keeps the same period finish (no change)
    function stakingRewards_updatePeriodFinish_extend_clamped(uint40 secondsAdjust) public {
        uint256 currentPeriodFinish = stakingRewards.periodFinish();
        require(currentPeriodFinish > block.timestamp, "period ended");

        stakingRewards_updatePeriodFinish(currentPeriodFinish + secondsAdjust);
    }

    /// @dev block.timestamp <= new period finish < current period finish     
    /// @dev secondsAdjust % window == 0, end now
    function stakingRewards_updatePeriodFinish_end_early_clamped(uint40 secondsAdjust) public {
        uint256 currentPeriodFinish = stakingRewards.periodFinish();
        require(currentPeriodFinish > block.timestamp, "period ended");

        uint256 window = currentPeriodFinish - block.timestamp;
        uint256 newPeriodFinish = block.timestamp + (secondsAdjust % window);
        stakingRewards_updatePeriodFinish(newPeriodFinish);
    }

    /// @dev lastUpdateTime <= new period finish < block.timestamp 
    /// @dev secondsAdjust % window == 0, newPeriodFinish == lastUpdateTime
    function stakingRewards_updatePeriodFinish_elapsed_clamped(uint40 secondsAdjust) public {
        uint256 currentPeriodFinish = stakingRewards.periodFinish();
        uint256 lastUpdateTime = stakingRewards.lastUpdateTime();
        require(currentPeriodFinish > block.timestamp, "period ended");
        require(block.timestamp > lastUpdateTime, "empty window");

        uint256 window = block.timestamp - lastUpdateTime;
        uint256 newPeriodFinish = lastUpdateTime + (secondsAdjust % window);
        stakingRewards_updatePeriodFinish(newPeriodFinish);        
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function stakingRewards_acceptOwnership() public asActor {
        stakingRewards.acceptOwnership();

        currentOwner = _getActor();
    }

    function stakingRewards_exit() public updateGhostsWithType(OpType.EXIT) asActor {
        stakingRewards.exit();

        eq(
            stakingRewards.balanceOf(_getActor()),
            0,
            "stakingRewards_exit: not zero balances for actor"
        );
        
        eq(
            stakingRewards.rewards(_getActor()),
            0,
            "stakingRewards_exit: not zero rewards for actor"
        );
    }

    function stakingRewards_getReward() public updateGhostsWithType(OpType.CLAIM_REWARDS) asActor {
        stakingRewards.getReward();

        canary_claimRewardsTimestamp = block.timestamp;

        eq(
            stakingRewards.rewards(_getActor()),
            0,
            "stakingRewards_getReward: not zero rewards for actor"
        );
    }

    function stakingRewards_nominateNewOwner(address _owner) public asActor {
        stakingRewards.nominateNewOwner(_owner);
    }

    function stakingRewards_notifyRewardAmount(uint256 reward) public updateGhostsWithType(OpType.ADD_REWARDS) asActor {
        stakingRewards.notifyRewardAmount(reward);

        _ghost_totalNotifiedReward += reward;
        canary_rewardDistributionTimestamp = block.timestamp;

        uint256 remainingScheduledRewards = (stakingRewards.periodFinish() - block.timestamp) * stakingRewards.rewardRate();
        uint256 totalRewardOwed = __totalRewardOwedTilNow();

        gte(
            stakingRewards.rewardsToken().balanceOf(address(stakingRewards)),
            totalRewardOwed + remainingScheduledRewards,
            "reward token balance cannot cover owed rewards plus scheduled rewards"
        );
    }

    function stakingRewards_recoverERC20(address tokenAddress, uint256 tokenAmount) public asActor {
        if (!ALLOW_OWNER_REKT) {
            // block rewardsToken recovery entirely for now, later this can be relaxed to allow only surplus (will need extra accounting here)
            require(tokenAddress != address(stakingRewards.rewardsToken()), "owner rekt disabled");
        }
        stakingRewards.recoverERC20(tokenAddress, tokenAmount);

    }

    function stakingRewards_setPaused(bool _paused) public updateGhosts asActor {
        stakingRewards.setPaused(_paused);
    }

    function stakingRewards_setRewardsDistribution(address _rewardsDistribution) public asActor {
        stakingRewards.setRewardsDistribution(_rewardsDistribution);
    }

    function stakingRewards_setRewardsDuration(uint256 _rewardsDuration) public updateGhostsWithType(OpType.REWARD_CONFIG) asActor {
        stakingRewards.setRewardsDuration(_rewardsDuration);
    }

    function stakingRewards_stake(uint256 amount) public updateGhostsWithType(OpType.ADD_STAKE) asActor {
        uint256 before__stakeBalance = stakingRewards.balanceOf(_getActor());
        stakingRewards.stake(amount);
        uint256 after__stakeBalance = stakingRewards.balanceOf(_getActor());

        eq(
            after__stakeBalance,
            before__stakeBalance + amount,
            "stakingRewards_stake: increase inaccurately"
        );
    }

    function stakingRewards_updatePeriodFinish(uint256 timestamp) public updateGhostsWithType(OpType.REWARD_CONFIG) asActor {
        if (!ALLOW_OWNER_REKT) {
            // just not allow the update that can cause th underflow revert (lastTimeRewardApplicable() - lastUpdateTime)
            require(timestamp >= stakingRewards.lastUpdateTime(), "owner rekt disabled: make underflow revert in calcualtion");
            require(timestamp < stakingRewards.periodFinish(), "owner rekt disabled: make extend period without rewards backing");

        }
        stakingRewards.updatePeriodFinish(timestamp);
    }

    function stakingRewards_withdraw(uint256 amount) public updateGhostsWithType(OpType.REMOVE_STAKE) asActor {
        uint256 before__stakeBalance = stakingRewards.balanceOf(_getActor());
        stakingRewards.withdraw(amount);
        uint256 after__stakeBalance = stakingRewards.balanceOf(_getActor());

        eq(
            after__stakeBalance,
            before__stakeBalance - amount,
            "stakingRewards_withdraw: decrease inaccurately"
        );

    }
}