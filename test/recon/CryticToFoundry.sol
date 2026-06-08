// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";


// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        // TODO: add failing property tests here for debugging
    }

    //////////// Recon Fuzzer, log scraper by: https://getrecon.xyz/tools/echidna ////////////
    ////// @dev 001: shrinkLimit: 100000
    ////// @dev 002, 004: shrinkLimit: 500000
    ////// @dev 005: not allow extending period finish
    //////////////////////////////////////////////////////////////////////////////////////////

    // forge test --match-test test_property_no_active_rewards_without_stakers_001 -vvv 
    function test_property_no_active_rewards_without_stakers_001() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        property_no_active_rewards_without_stakers();

    }

    // forge test --match-test test_property_no_active_rewards_without_stakers_002 -vvv 
    function test_property_no_active_rewards_without_stakers_002() public {
        //@note this found by adding the `totalSupply == 0` check in `stakingRewards.notifyRewardAmount()`
        stakingRewards_setRewardsDuration(1);

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(1);

        stakingRewards_exit();

        property_no_active_rewards_without_stakers();

    }

    // forge test --match-test test_property_rewardPerToken_stable_during_no_active_rewards_001 -vvv 
    function test_property_rewardPerToken_stable_during_no_active_rewards_001() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        vm.warp(block.timestamp + 1);
        stakingRewards_stake(1);

        vm.warp(block.timestamp + 1);
        stakingRewards_updatePeriodFinish(591233543662825994214495745566112816088526820809093);

        property_rewardPerToken_stable_during_no_active_rewards();

    }

    // forge test --match-test test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_001 -vvv 
    function test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_001() public {

        //@note Breaks because `periodFinish` is extended far into the future.
        // The period finish was extended before this check, so the contract is already underbacked before the recovery simulation.

        stakingRewards_fund_then_notifyRewardAmount(604803);

        stakingRewards_updatePeriodFinish(1525403738);

        doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards();

    }

    // forge test --match-test test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_001 -vvv 
    function test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_001() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        stakingRewards_updatePeriodFinish(81239500760770610911879908910759874620338853564673980445122457793293885704996);

        property_reward_token_balance_gte_users_earned_and_remaining_schedule();

    }

    // forge test --match-test test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_002 -vvv 
    function test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_002() public {

        stakingRewards_setRewardsDuration(1);

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(1);

        stakingRewards_updatePeriodFinish(1524812326);

        property_reward_token_balance_gte_users_earned_and_remaining_schedule();

    }

    // forge test --match-test test_property_no_reactivate_rewards_without_notify_001 -vvv 
    function test_property_no_reactivate_rewards_without_notify_001() public {

        stakingRewards_fund_then_notifyRewardAmount(604810);

        vm.warp(block.timestamp + 604800);
        stakingRewards_updatePeriodFinish(1525403330);

        property_no_reactivate_rewards_without_notify();

    }

    // forge test --match-test test_stakingRewards_notifyRewardAmount_001 -vvv 
    function test_stakingRewards_notifyRewardAmount_001() public {

        stakingRewards_setRewardsDuration(1);

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_notifyRewardAmount(1);

    }

    // forge test --match-test test_property_rewardRate_not_decrease_with_active_stakers_001 -vvv 
    function test_property_rewardRate_not_decrease_with_active_stakers_001() public {
        // 🚧 this break `property_rewardRate_not_decrease_with_active_stakers`
        //@note before shrinking

        vm.roll(block.number + 5887);
        vm.warp(block.timestamp + 5335);
        stakingRewards_setRewardsDuration(3);

        switch_asset(0);

        vm.roll(block.number + 8896);
        vm.warp(block.timestamp + 1874);
        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        vm.roll(block.number + 1758);
        vm.warp(block.timestamp + 343);
        stakingRewards_notifyRewardAmount(1);

        vm.roll(block.number + 6538);
        vm.warp(block.timestamp + 465713);
        property_canary_timeAdvanceBeforeClaimRewards();

        vm.roll(block.number + 8227);
        vm.warp(block.timestamp + 165060);
        asset_approve(0x0000000000000000000000000000000000000004,71596639995805765737390801109734523017);

        vm.roll(block.number + 44950);
        vm.warp(block.timestamp + 31355);
        property_rewardRate_not_decrease_with_active_stakers();

        vm.roll(block.number + 6917);
        vm.warp(block.timestamp + 327218);
        property_canary_timeAdvanceBeforeClaimRewards();

        vm.roll(block.number + 21805);
        vm.warp(block.timestamp + 18047);
        setup_newStakingRewards(216,207);

        vm.roll(block.number + 95928);
        vm.warp(block.timestamp + 169212);
        property_reward_token_balance_gte_users_earned_and_remaining_schedule();

        vm.roll(block.number + 47112);
        vm.warp(block.timestamp + 20467);
        stakingRewards_notifyRewardAmount(0);

        vm.roll(block.number + 14262);
        vm.warp(block.timestamp + 6402);
        property_actor_earned_rewards_not_decrease_except_claim();

        vm.roll(block.number + 55404);
        vm.warp(block.timestamp + 1069448);
        stakingRewards_nominateNewOwner(0x00000000000000000000000000000001fffffffE);

        vm.roll(block.number + 61764);
        vm.warp(block.timestamp + 379831);
        property_rewardRate_not_decrease_with_active_stakers();

        vm.roll(block.number + 52910);
        vm.warp(block.timestamp + 789283);
        property_reward_token_balance_gte_users_earned_and_remaining_schedule();

        vm.roll(block.number + 13574);
        vm.warp(block.timestamp + 11007);
        asset_mint(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496,5737366979366933456393890722427601097);

        vm.roll(block.number + 22775);
        vm.warp(block.timestamp + 588958);
        setup_newStakingRewards_same_stakingToken_rewardsToken(49);

        vm.roll(block.number + 58543);
        vm.warp(block.timestamp + 765662);
        property_rewardRate_not_decrease_with_active_stakers();

        vm.roll(block.number + 21833);
        vm.warp(block.timestamp + 584578);
        property_no_reactivate_rewards_without_notify();

        vm.roll(block.number + 94024);
        vm.warp(block.timestamp + 286286);
        property_no_stake_actor_earned_not_increase();

        vm.roll(block.number + 18406);
        vm.warp(block.timestamp + 97857);
        property_no_reactivate_rewards_without_notify();

        vm.roll(block.number + 30176);
        vm.warp(block.timestamp + 548176);
        property_canary_timeAdvanceBeforeClaimRewards();

        vm.roll(block.number + 9740);
        vm.warp(block.timestamp + 12338);
        add_new_asset(0);

        vm.roll(block.number + 26702);
        vm.warp(block.timestamp + 10664);
        stakingRewards_fund_then_notifyRewardAmount(26074678303323496502310660558043770453581341290055914304923681055958917795203);

        vm.roll(block.number + 91400);
        vm.warp(block.timestamp + 1048599);
        property_stake_from_zero_does_not_capture_prior_rewards();

        vm.roll(block.number + 59447);
        vm.warp(block.timestamp + 570048);
        property_no_stake_actor_earned_not_increase();

        vm.roll(block.number + 77633);
        vm.warp(block.timestamp + 28397);
        stakingRewards_nominateNewOwner(0x0000000000000000000000000000000000000006);

        vm.roll(block.number + 34980);
        vm.warp(block.timestamp + 301905);
        property_no_reactivate_rewards_without_notify();

        vm.roll(block.number + 118758);
        vm.warp(block.timestamp + 894678);
        property_canary_timeAdvanceBeforeClaimRewards();

        vm.roll(block.number + 60280);
        vm.warp(block.timestamp + 364322);
        property_rewardPerToken_stable_during_no_active_rewards();

        vm.roll(block.number + 49402);
        vm.warp(block.timestamp + 457129);
        property_stake_from_zero_does_not_capture_prior_rewards();

        vm.roll(block.number + 19218);
        vm.warp(block.timestamp + 24062);
        property_reward_token_balance_gte_users_earned_and_remaining_schedule();

        vm.roll(block.number + 36342);
        vm.warp(block.timestamp + 605);
        property_rewardRate_not_decrease_with_active_stakers();

    }

    // forge test --match-test test_property_rewardRate_not_decrease_with_active_stakers_002 -vvv 
    function test_property_rewardRate_not_decrease_with_active_stakers_002() public {

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(604804);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_notifyRewardAmount(0);

        property_rewardRate_not_decrease_with_active_stakers();

    }

    // forge test --match-test test_stakingRewards_fund_then_notifyRewardAmount_001 -vvv 
    function test_stakingRewards_fund_then_notifyRewardAmount_001() public {

        //@note Breaks because `periodFinish` is extended far into the future
        // The next notify includes a large leftover schedule, so the contract's balance/rate check can revert

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        vm.warp(block.timestamp + 2);
        stakingRewards_stake(671);

        stakingRewards_setRewardsDuration(100477556399539989170467312233197366165556802047565303163384532753090641672036);

        vm.warp(block.timestamp + 20);
        stakingRewards_updatePeriodFinish(25227283125566709962717149482382663811529416080926161514961101788081692210382);

        stakingRewards_fund_then_notifyRewardAmount(18);

    }

    // forge test --match-test test_stakingRewards_fund_then_notifyRewardAmount_002 -vvv 
    function test_stakingRewards_fund_then_notifyRewardAmount_002() public {

        stakingRewards_setRewardsDuration(1);

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(1);

        vm.warp(block.timestamp + 2);
        stakingRewards_setRewardsDuration(129907);

        stakingRewards_updatePeriodFinish(1524915562);

        stakingRewards_fund_then_notifyRewardAmount(0); //> revert `Provided reward too high`

    }

    ///////////////////// 004 ////////////////////
    // forge test --match-test test_stakingRewards_fund_then_notifyRewardAmount_004 -vvv 
    function test_stakingRewards_fund_then_notifyRewardAmount_004() public {

        //@note Breaks because `periodFinish` is extended far into the future
        // The next notify includes a large leftover schedule, so the contract's balance/rate check can revert

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        vm.warp(block.timestamp + 2);
        stakingRewards_stake(671);

        stakingRewards_setRewardsDuration(100477556399539989170467312233197366165556802047565303163384532753090641672036);

        vm.warp(block.timestamp + 20);
        stakingRewards_updatePeriodFinish(25227283125566709962717149482382663811529416080926161514961101788081692210382);

        stakingRewards_fund_then_notifyRewardAmount(18);

    }

    // forge test --match-test test_property_no_reactivate_rewards_without_notify_004 -vvv 
    function test_property_no_reactivate_rewards_without_notify_004() public {

        stakingRewards_fund_then_notifyRewardAmount(604801);

        vm.warp(block.timestamp + 604800);
        stakingRewards_updatePeriodFinish(1525391362);

        property_no_reactivate_rewards_without_notify();

    }

    // forge test --match-test test_stakingRewards_notifyRewardAmount_004 -vvv 
    function test_stakingRewards_notifyRewardAmount_004() public {

        stakingRewards_setRewardsDuration(1);

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_notifyRewardAmount(1);

    }

    // forge test --match-test test_property_no_active_rewards_without_stakers_004 -vvv 
    function test_property_no_active_rewards_without_stakers_004() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        property_no_active_rewards_without_stakers();

    }

    // forge test --match-test test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_004 -vvv 
    function test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_004() public {

        //@note Breaks because `periodFinish` is extended far into the future.
        // The period finish was extended before this check, so the contract is already underbacked before the recovery simulation.

        stakingRewards_fund_then_notifyRewardAmount(604801);

        stakingRewards_updatePeriodFinish(1525391737);

        doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards();

    }

    // forge test --match-test test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_004 -vvv 
    function test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_004() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        stakingRewards_updatePeriodFinish(81239500760770610911879908910759874620338853564673980445122457793293885704996);

        property_reward_token_balance_gte_users_earned_and_remaining_schedule();

    }

    // forge test --match-test test_property_rewardPerToken_stable_during_no_active_rewards_004 -vvv 
    function test_property_rewardPerToken_stable_during_no_active_rewards_004() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_stake(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_updatePeriodFinish(591233543662825994214495745566112816088526820809093);

        property_rewardPerToken_stable_during_no_active_rewards();

    }

    // forge test --match-test test_property_rewardRate_not_decrease_with_active_stakers_004 -vvv 
    function test_property_rewardRate_not_decrease_with_active_stakers_004() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        vm.warp(block.timestamp + 2);
        stakingRewards_stake(671);

        stakingRewards_setRewardsDuration(100477556399539989170467312233197366165556802047565303163384532753090641672036);

        stakingRewards_updatePeriodFinish(60377619795181001575889095999292468231762561001496232546180999709614564143162);

        stakingRewards_fund_then_notifyRewardAmount(21063529232496854508924612873125709214062949133544944363475760368069296581818);

        property_rewardRate_not_decrease_with_active_stakers();
    }

    // forge test --match-test test_doomsday_exit_always_success_004 -vvv 
    function test_doomsday_exit_always_success_004() public {

        stakingRewards_fund_then_notifyRewardAmount(604803);

        stakingRewards_updatePeriodFinish(1525457545);

        stakingRewards_stake(1);

        vm.warp(block.timestamp + 604804);
        doomsday_exit_always_success();

    }

    // forge test --match-test test_property_reward_config_changes_do_not_reduce_actor_owed_004 -vvv 
    function test_property_reward_config_changes_do_not_reduce_actor_owed_004() public {

        stakingRewards_fund_then_notifyRewardAmount(604801);

        stakingRewards_stake(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_updatePeriodFinish_elapsed_clamped(0);

        property_reward_config_changes_do_not_reduce_actor_owed();

    }

    // forge test --match-test test_property_actor_earned_rewards_not_decrease_except_claim_004 -vvv 
    function test_property_actor_earned_rewards_not_decrease_except_claim_004() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        stakingRewards_stake(1);

        stakingRewards_updatePeriodFinish(591233543662825994214495745566112816088526820809093);

        //@note this update the `updatePeriodFinish(1) == lastUpdateTime(1)`
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_updatePeriodFinish_elapsed_clamped(516284443333);

        property_actor_earned_rewards_not_decrease_except_claim();

    }

    ///////////////////// 005 ////////////////////
    // forge test --match-test test_property_reward_config_changes_do_not_reduce_actor_owed_005 -vvv 
    function test_property_reward_config_changes_do_not_reduce_actor_owed_005() public {

        stakingRewards_fund_then_notifyRewardAmount(604801);

        stakingRewards_stake(1);

        vm.warp(block.timestamp + 1);
        stakingRewards_updatePeriodFinish_elapsed_clamped(0);

        property_reward_config_changes_do_not_reduce_actor_owed();

    }

    // forge test --match-test test_stakingRewards_notifyRewardAmount_005 -vvv 
    function test_stakingRewards_notifyRewardAmount_005() public {

        stakingRewards_setRewardsDuration(1);

        stakingRewards_stake(1);

        stakingRewards_fund_then_notifyRewardAmount(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_notifyRewardAmount(1);

    }

    // forge test --match-test test_property_no_active_rewards_without_stakers_005 -vvv 
    function test_property_no_active_rewards_without_stakers_005() public {

        stakingRewards_setRewardsDuration(1);

        switch_asset(0);

        asset_mint(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a,1);

        stakingRewards_notifyRewardAmount(1);

        property_no_active_rewards_without_stakers();

    }

    // forge test --match-test test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_005 -vvv 
    function test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_005() public {

        stakingRewards_fund_then_notifyRewardAmount(604801);

        stakingRewards_stake(1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
        stakingRewards_notifyRewardAmount(0);

        doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards();

    }

    // forge test --match-test test_property_actor_earned_rewards_not_decrease_except_claim_005 -vvv 
    function test_property_actor_earned_rewards_not_decrease_except_claim_005() public {

        stakingRewards_fund_then_notifyRewardAmount(604801);

        stakingRewards_stake(1);

        vm.warp(block.timestamp + 1);
        stakingRewards_updatePeriodFinish_elapsed_clamped(0);

        property_actor_earned_rewards_not_decrease_except_claim();

    }
    
}