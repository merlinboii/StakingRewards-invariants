// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

abstract contract DoomsdayTargets is
    BaseTargetFunctions,
    Properties
{
    /// Makes a handler have no side effects
    /// The fuzzer will call this anyway, and because it reverts it will be removed from shrinking
    /// Replace the "withGhosts" with "stateless" to make the code clean
    modifier stateless() {
        _;
        revert("stateless");
    }

    function doomsday_exit_always_success() public stateless {
        try stakingRewards.exit() {
            // success
        } catch Error(string memory reason) {
            if(keccak256(abi.encodePacked(reason)) != keccak256(abi.encodePacked("Cannot withdraw 0"))) {
                t(false, "exit should never revert for proper input");
            }
        }
    }

    function doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards() public stateless {
        /// @dev If rewardsToken == stakingToken, recoverERC20() reverts.
        uint256 preservedAmount = stakingRewards.getRewardForDuration();
        uint256 rewardBalance = stakingRewards.rewardsToken().balanceOf(address(stakingRewards));
        
        bool hasApparentSurplus = rewardBalance > preservedAmount;
        if (!hasApparentSurplus) return;

        uint256 surplus = rewardBalance - preservedAmount;

        vm.prank(currentOwner);
        stakingRewards.recoverERC20(address(stakingRewards.rewardsToken()), surplus);

        uint256 totalRewardOwed = __totalRewardOwedTilNow();
        uint256 remainingScheduledRewards;
        if (block.timestamp < stakingRewards.periodFinish()) {
            remainingScheduledRewards = (stakingRewards.periodFinish() - block.timestamp) * stakingRewards.rewardRate();
        }

        gte(
            stakingRewards.rewardsToken().balanceOf(address(stakingRewards)),
            totalRewardOwed + remainingScheduledRewards,
            "getRewardForDuration-based recovery breaks reward solvency"
        );
    }

}