// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
    struct Vars {
        /// CONTRACT STATE VARIABLES ///
        uint256 totalSupply;
        uint256 rewardRate;
        uint256 periodFinish;
        uint256 lastUpdateTime;
        uint256 rewardsDuration;
        uint256 rewardPerTokenStored;

        uint256 totalRewardDistributed;
        uint256 timestamp;

        /// STATEs ///
        RewardState rewardState;
        StakeState stakeState;
        bool paused;

        /// ACTOR STATE VARIABLES ///
        uint256 actor_stakingBalance;
        uint256 actor_rewards;
        uint256 actor_userRewardPerTokenPaid;

        StakeState actor_stakeState;
    }

    Vars internal _before;
    Vars internal _after;
    OpType internal currentOperation;

    uint256 internal _ghost_totalNotifiedReward;

    enum OpType {
        GENERIC,
        ADD_STAKE,
        REMOVE_STAKE,
        ADD_REWARDS,
        CLAIM_REWARDS,
        EXIT,
        REWARD_CONFIG
    }

    enum StakeState {
        NONE,
        NO_STAKE,
        STAKING
    }

    enum RewardState {
        NONE,
        NO_ACTIVE_REWARDS,
        ACTIVE_REWARDS
    }

    modifier updateGhostsWithType(OpType op) {
       currentOperation = op;
        __before();
        _;
        __after();
    }

    modifier updateGhosts {
        currentOperation = OpType.GENERIC;
        __before();
        _;
        __after();
    }

    function __before() internal {
        __snapshot(_before);

    }

    function __after() internal {
        __snapshot(_after);

    }

    function __snapshot(Vars storage vars) internal {
        /// CONTRACT STATE VARIABLES ///
        vars.totalSupply = stakingRewards.totalSupply();
        vars.rewardRate = stakingRewards.rewardRate();
        vars.periodFinish = stakingRewards.periodFinish();
        vars.lastUpdateTime = stakingRewards.lastUpdateTime();
        vars.rewardPerTokenStored = stakingRewards.rewardPerTokenStored();
        vars.rewardsDuration = stakingRewards.rewardsDuration();

        vars.totalRewardDistributed = _ghost_totalNotifiedReward;
        vars.timestamp = block.timestamp;

        /// STATEs ///
        vars.rewardState = __isActiveReward(block.timestamp, vars.periodFinish, vars.rewardRate);
        vars.stakeState = __stakeState(vars.totalSupply);
        vars.paused = stakingRewards.paused();

        /// ACTOR STATE VARIABLES ///
        address actor = _getActor();
        vars.actor_stakingBalance = stakingRewards.balanceOf(actor);
        vars.actor_rewards = stakingRewards.rewards(actor);
        vars.actor_userRewardPerTokenPaid = stakingRewards.userRewardPerTokenPaid(actor);

        vars.actor_stakeState = __stakeState(vars.actor_stakingBalance);
    }

    function __isActiveReward(uint256 timestamp, uint256 periodFinish, uint256 rewardRate) internal view returns (RewardState) {
        if (periodFinish == 0 || rewardRate == 0) {
            return RewardState.NO_ACTIVE_REWARDS;
        }
        return timestamp < periodFinish ? RewardState.ACTIVE_REWARDS : RewardState.NO_ACTIVE_REWARDS;
    }

    function __stakeState(uint256 totalSupply) internal view returns (StakeState) {
        return totalSupply > 0 ? StakeState.STAKING : StakeState.NO_STAKE;
    }

    function __lastTimeRewardApplicable(Vars storage vars) internal view returns (uint256) {
        return __lastTimeRewardApplicable(vars.timestamp, vars.periodFinish);
    }

    function __lastTimeRewardApplicable(uint256 timestamp, uint256 periodFinish) internal pure returns (uint256) {
        return timestamp < periodFinish ? timestamp : periodFinish;
    }

    function __rewardPerToken(Vars storage vars) internal view returns (uint256) {
        return __rewardPerToken(
            vars.timestamp,
            vars.rewardPerTokenStored,
            vars.periodFinish,
            vars.lastUpdateTime,
            vars.rewardRate,
            vars.totalSupply
        );
    }

    function __rewardPerToken(uint256 timestamp, uint256 rewardPerTokenStored, uint256 periodFinish, uint256 lastUpdateTime, uint256 rewardRate, uint256 totalSupply) internal pure returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + (__lastTimeRewardApplicable(timestamp, periodFinish) - lastUpdateTime) * rewardRate * 1e18 / totalSupply;
    }

    function __earned_rewards(Vars storage vars) internal view returns (uint256) {
        return __earned_rewards(
            vars.actor_stakingBalance,
            __rewardPerToken(vars),
            vars.actor_userRewardPerTokenPaid,
            vars.actor_rewards
        );
    }

    function __earned_rewards(uint256 balance, uint256 rewardPerToken, uint256 userRewardPerTokenPaid, uint256 rewards) internal pure returns (uint256) {
        return (balance * (rewardPerToken - userRewardPerTokenPaid) / 1e18) + rewards;
    }

    function __totalRewardOwedTilNow() internal view returns (uint256) {
        address[] memory actors = _getActors();
        uint256 totalRewardOwed = 0;
        for (uint256 i = 0; i < actors.length; i++) {
            totalRewardOwed += stakingRewards.earned(actors[i]);
        }

        return totalRewardOwed;
    }

}