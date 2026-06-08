# Property Failures
> Repros can be found in [CryticToFoundry.sol](./CryticToFoundry.sol)

## Summary
- Most broken properties here come from how `periodFinish` can be updated.
  - Extending `periodFinish` breaks several properties related to reward token solvency and `rewardPerToken` state.
  - Rewards are expected to enter the protocol through `notifyRewardAmount()`, but `periodFinish` is also part of the active-reward state. Updating it directly can make rewards appear active even when there are no backed reward tokens.
  - 🚧 need to try clamping to not let `periodFinish` extend to see if we will got any other interesting scenarios

- Interesting areas:
  - `updatePeriodFinish()` does not apply `updateReward()`, so accrued but uncheckpointed rewards can be reduced when `periodFinish` is changed into the range `[lastUpdateTime, block.timestamp)`.
  - `rewardRate` can be diluted by a small top-up through `notifyRewardAmount()`.
    - This may be intended if the reward distributor is fully trusted.
    - It can also be abused by repeatedly distributing `0` or `1 wei`, delaying remaining rewards or causing active stakers to lose future rewards (if rate rounding to 0).
  - The state `ACTIVE_REWARDS` with no stakers can lock rewards if not handled. This can happen through `notifyRewardAmount()` when there are no stakers, or when all users exit during an active reward period.
  - The check `rewardRate <= balance / rewardsDuration` in `notifyRewardAmount()` does not guarantee that the reward token balance can cover all user rewards.
  
---
## property_reward_token_balance_gte_users_earned_and_remaining_schedule

### Repros: 
- `test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_001`
- `test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_002`
- `test_property_reward_token_balance_gte_users_earned_and_remaining_schedule_004`

### Scenario
- Extending `periodFinish`

### Root Cause
- `updatePeriodFinish()` can extend the reward schedule without increasing the reward token balance, so the additional scheduled emissions may be unbacked.

### Impact
- The extended period can have 0 backed reward tokens if no tokens are transferred directly to the contract.
- If users checkpoint those rewards, users will be unable to withdraw their rewards because there are no funds backing them.

---

## property_rewardPerToken_stable_during_no_active_rewards

### Repros: 
- `test_property_rewardPerToken_stable_during_no_active_rewards_001`
- `test_property_rewardPerToken_stable_during_no_active_rewards_004`

### Scenario
- Extending `periodFinish`

### Root Cause
- `updatePeriodFinish()` can extend the reward schedule without increasing the reward token balance, so the additional scheduled emissions may be unbacked.

### Impact
- If users checkpoint those rewards, users may be unable to withdraw their rewards because there are no funds backing them.

---

## property_rewardRate_not_decrease_with_active_stakers

### Repros: 
- `test_property_rewardRate_not_decrease_with_active_stakers_002`
- `test_property_rewardRate_not_decrease_with_active_stakers_004`

### Scenario
- Notify new rewards with a small amount during active rewards.

### Root Cause
- During an active reward period, `notifyRewardAmount()` recalculates `rewardRate` as `(reward + leftover) / rewardsDuration`.
- There is no check that the new `rewardRate` is >= the previous `rewardRate`, so a small top-up can reduce the emission rate for active stakers.

### Impact
- Dilutes the reward rate.
- Delays remaining rewards.
- Active stakers may lose future rewards if the rate rounds down to 0.

---

## property_no_active_rewards_without_stakers

### Repros: 
- `test_property_no_active_rewards_without_stakers_001`
- `test_property_no_active_rewards_without_stakers_002`
- `test_property_no_active_rewards_without_stakers_004`
- `test_property_no_active_rewards_without_stakers_005`

### Root Cause
- `notifyRewardAmount()` does not prevent to distribute during 0 staker
- The contract allows the last staker to exit while rewards are still active without handling the remaining rewards

### Scenario
- Notify rewards when there are no stakers.
- All users exit while rewards are still active.

### Impact
- Rewards emitted while `totalSupply == 0` do not accrue to any staker.
- These rewards may require manual handling btw the protocol can expect manual handling like in this case have recovery functions and can active rewards can end at any time.

---

## property_actor_earned_rewards_not_decrease_except_claim

### Repros: 
- `test_property_actor_earned_rewards_not_decrease_except_claim_004`
- `test_property_actor_earned_rewards_not_decrease_except_claim_005`

### Scenario
- Update `periodFinish` to a new period finish that falls within `lastUpdateTime <= newPeriodFinish < block.timestamp`.

### Root Cause
- `updatePeriodFinish()` not apply the `updateReward()` so it not make a check point of the rewards at the updated time leads to un-checkpoint rewards up to update time can be loss

### Impact
- User can lost the un-checkpoint rewards up til updated time
- Or if the intended of the setup is to stop rewards at last checkpoint, user can also prevent that by do any actions that trigger `updateReward()` before the period change to capture that rewards eg, `getReward()`

---

## property_reward_config_changes_do_not_reduce_actor_owed

### Repros: 
- `test_property_reward_config_changes_do_not_reduce_actor_owed_004`
- `test_property_reward_config_changes_do_not_reduce_actor_owed_005`

### Scenario
- Update `periodFinish` to a new period finish that falls within `lastUpdateTime <= newPeriodFinish < block.timestamp`.

### Root Cause
- `updatePeriodFinish()` not apply the `updateReward()` so it not make a check point of the rewards at the updated time leads to un-checkpoint rewards up to update time can be loss

### Impact
- User can lost the un-checkpoint rewards up til updated time
- Or if the intended of the setup is to stop rewards at last checkpoint, user can also prevent that by do any actions that trigger `updateReward()` before the period change to capture that rewards eg, `getReward()`

---

## property_no_reactivate_rewards_without_notify

### Repros: 
- `test_property_no_reactivate_rewards_without_notify_001`
- `test_property_no_reactivate_rewards_without_notify_004`

### Scenario
- Extend `periodFinish`

### Root Cause
- `updatePeriodFinish()` can move `periodFinish` from an ended reward period back into the future without calling `notifyRewardAmount()`.
- This can transition rewards from inactive to active even though no new rewards were notified.

### Impact
- Rewards can become active again without a new reward distribution event.
- The reactivated schedule may be unbacked if no reward tokens were added.

---

## stakingRewards_notifyRewardAmount

### Repros: 
- `test_stakingRewards_notifyRewardAmount_001`
- `test_stakingRewards_notifyRewardAmount_004`
- `test_stakingRewards_notifyRewardAmount_005`

### Scenario
- Notify during active rewards without transferring enough new funds that maintain the new rate below `balance / rewardsDuration`.

### Root Cause
- `notifyRewardAmount()` only checks `rewardRate <= balance / rewardsDuration`.
- This check does not guarantee the reward token balance can cover both rewards already owed to users and the rewards that is newly notified.

### Impact
- Rewards can become underbacked.
- Users may be unable to claim rewards if accrued rewards exceed the contract reward token balance.

---

## doomsday_exit_always_success

### Repros: 
- `test_doomsday_exit_always_success_004`

### Scenario
- Extend `periodFinish` during an active reward period without adding reward tokens.
- A user stakes/checkpoints rewards during the extended period.
- The user later exits after accruing unbacked rewards.

### Root Cause
- Extend `periodFinish` via `updatePeriodFinish()` during an active period without directly transferring rewards to back it. Users can then checkpoint rewards that are unbacked.

### Impact
- `exit()` can revert during `getReward()` if the contract cannot transfer the accrued reward amount.
- User attempt to fully `exit()` can be blocked by underfunded reward accounting.

---

## doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards

### Repros: 
- `test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_005`
- 🚸 `test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_001`
- 🚸 `test_doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards_004`

> 🚸: This appears to be a false positive. The repro is already underbacked because `periodFinish` was extended via `updatePeriodFinish()` before the recovery simulation. so, the failure does not isolate a `getRewardForDuration()`-based recovery issue.

### Scenario
- Reward active
- A user earns rewards.
- `notifyRewardAmount(0)` during active rewards updates reward accounting and rounds `rewardRate` down to `0`.
- `getRewardForDuration()` returns `0`.
- Owner recovers the full reward token balance as apparent surplus.

### Root Cause
- `getRewardForDuration()` only returns `rewardRate * rewardsDuration`, so it can return `0` even when users already have earned rewards.
- If this value is used as the amount to preserve before recovering surplus reward tokens, the owner can recover tokens that are still needed to pay users.

### Impact
- Already-earned user rewards can become unbacked.
