## Format
- creating a separate table for properties in each contract can help keep things clean and easier to track
- property name: use `property_` prefix with a descriptive name of the property definition. If it's a stateful test implemented in a handler just add the name of the handler where it's defined
- description: what the property checks for, in English
- implemented: use ✅ to signify completed, 🚧 for in progress and leave blank if not implemented
- tested: use the ✅ to signify passing, ❌ for failed properties

## Notes
Having descriptive names in the function name should allow more easily finding a given property definition without having to look it up in the table.

## <ContractName>
| Property | Description | Implemented | Tested |
| --- | --- | --- | --- |
| `property_totalSupply_eq_sum_user_balances` | `stakingRewards.totalSupply() == ∑stakingRewards.balanceOf(user_i)` | ✅ |  |
| `property_staking_token_balance_gte_totalSupply` | staking token balance of `stakingRewards` is greater or equal the tracked totalSupply | ✅ |  |
| `property_reward_token_balance_gte_users_earned_and_remaining_schedule` | rewards token balance of `stakingRewards` is greater or equal ∑user's earned rewards | ✅ | ❌ |
| `property_rewardPerToken_stable_during_no_active_rewards` | if state before is: no active rewards, `rewardPerToken()` must stay the same | ✅ | ❌ |
| `property_rewardRate_not_decrease_with_active_stakers` | if in the state: staking and active rewards: `rewardRate` should not be decreased, otherwise that will delay the user rewards | ✅ | ❌ |
| `property_no_active_rewards_without_stakers` | should not distribute rewards while `totalSupply == 0` as rewards emitted during no staking state are not belong to any staker and can become stranded or require manual recovery  | ✅ | ❌ |
| `property_stake_from_zero_does_not_capture_prior_rewards` | a user with zero stake before staking must not receive claimable rewards immediately after staking into an active reward period. This aim to catch the case where late stake capturing rewards from prior intervals | ✅ |  |
| `property_actor_earned_rewards_not_decrease_except_claim` | a user’s earned rewards to users should stay the same or increase, except when users claim rewards through `getReward()` or `exit()` | ✅ | ❌ |
| `property_reward_config_changes_do_not_reduce_actor_owed` | Reward config changes (`notifyRewardAmount`, `setRewardsDuration`, `updatePeriodFinish`) may change future emissions, but must not reduce rewards already owed to the actor | ✅ | ❌ |
| `property_no_stake_actor_earned_not_increase` | if `totalSupply == 0`, the actor’s earned rewards should not increase because no stake exists to receive emissions | ✅ |  |
| `property_no_reactivate_rewards_without_notify` | if rewards are inactive, no operation except adding rewards should transition the system back to active rewards | ✅ | ❌ |
| `property_paused_totalSupply_not_increase` | while paused, `totalSupply` should not increase | ✅ |  |
| `stakingRewards_getReward` | **inlined:** `getReward()` should zero the actor’s stored rewards and transfer no more than the actor had earned before the claim | ✅ |  |
| `stakingRewards_stake` | **inlined:** successful `stake(amount)` should increase the actor balance by `amount` | ✅ |  |
| `stakingRewards_withdraw` | **inlined:** successful `withdraw(amount)` should decrease the actor balance by `amount` | ✅ |  |
| `stakingRewards_exit` | **inlined:** `exit()` zero actor balance and rewards | ✅  |  |
| `stakingRewards_notifyRewardAmount` | **inlined:** after `notifyRewardAmount()`, the reward token balance must cover rewards already owed to users plus the remaining scheduled emissions. This checks whether `rewardRate <= balance / rewardsDuration` is sufficient | ✅ | ❌ |
| `doomsday_exit_always_success` | `exit()` always_success if balance > 0 | ✅  | ❌ |
| `doomsday_recover_surplus_using_getRewardForDuration_preserves_rewards` | if owner uses `getRewardForDuration()` as the amount of reward token to preserve and recovers the rest as surplus, rewards already owed to users plus remaining scheduled emissions must still be fully backed | ✅ | ❌ |

