// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import {EnumerableSet} from "@recon/EnumerableSet.sol";

abstract contract StakingRewardsManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    ///@notice The current staking rewards contract being used
    address private _stakingRewards;

    ///@notice The list of all staking rewards contracts being used
    EnumerableSet.AddressSet private _stakingRewardsList;

    // If the current target is address(0) then it has not been setup yet and should revert
    error StakingRewardsNotSetup();
    // Do not allow duplicates
    error StakingRewardsExists();
    // If the staking rewards contract does not exist
    error StakingRewardsNotAdded();

    /// @notice address(this) is the default staking rewards contract
    constructor() {}

    /// @notice Returns the current active staking rewards contract
    function _getStakingRewards() internal view returns (address) {
        return _stakingRewards;
    }

    /// @notice Returns all staking rewards contracts being used
    function _getStakingRewardsList() internal view returns (address[] memory) {
        return _stakingRewardsList.values();
    }

    /// @notice Adds a staking rewards contract to the list of contracts
    function _addStakingRewards(address target) internal {
        if (_stakingRewardsList.contains(target)) {
            revert StakingRewardsExists();
        }
        _stakingRewardsList.add(target);
    }

    /// @notice Removes a staking rewards contract from the list of contracts
    function _removeStakingRewards(address target) internal {
        if (!_stakingRewardsList.contains(target)) {
            revert StakingRewardsNotAdded();
        }

        _stakingRewardsList.remove(target);
    }

    /// @dev Expose this in the `TargetFunctions` contract to let the fuzzer switch staking rewards contracts
    ///   NOTE: We revert if the entropy is greater than the number of staking rewards contracts, for Halmos compatibility
    /// @dev This may reduce fuzzing performance if using multiple actors, if so add explicitly clamped handlers to ManagersTargets using the index of all added actors
    /// @notice Switches the current staking rewards contract based on the entropy
    /// @param entropy The entropy to choose a random staking rewards contract in the array for switching
    /// @return target The new active staking rewards contract
    function _switchStakingRewards(uint256 entropy) internal returns (address target) {
        target = _stakingRewardsList.at(entropy);
        _stakingRewards = target;
    }
}
