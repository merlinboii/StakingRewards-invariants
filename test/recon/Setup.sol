// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";
import {StakingRewardsManager} from "test/recon/managers/StakingRewardsManager.sol";
// Helpers
import {Utils} from "@recon/Utils.sol";
import {MockERC20} from "@recon/MockERC20.sol";

// Your deps
import "src/StakingRewards.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, StakingRewardsManager, Utils {
    StakingRewards stakingRewards;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override {
        stakingRewards = _deployStakingRewards(_newAsset(18), _newAsset(18));
        _addStakingRewards(address(stakingRewards));

        // Setup actors
        _addActor(address(0x1));
        _addActor(address(0x3));
        _addActor(address(0x4));
        _addActor(address(0x5));
        _addActor(address(0x6));
        _addActor(address(0x7));
        _addActor(address(0x8));
        _addActor(address(0x9));

        // Setup approvals and mints as necessary
        address[] memory actors = _getActors();
        address[] memory approvals = new address[](actors.length);
        for (uint256 i = 0; i < actors.length; i++) {
            approvals[i] = address(stakingRewards);
        }
        _finalizeAssetDeployment(actors, approvals, type(uint88).max);
    }

    function setup_newStakingRewards(uint8 stakingTokenDec, uint8 rewardsTokenDec) public asActor {
        // Disable for now, just want to keep the interface

        // StakingRewards newStakingRewards = _deployStakingRewards(_newAsset(stakingTokenDec), _newAsset(rewardsTokenDec));

        // address[] memory actors = _getActors();
        // for (uint256 i = 0; i < actors.length; i++) {
        //     MockERC20(newStakingRewards.stakingToken()).mint(actors[i], type(uint88).max);
        //     MockERC20(newStakingRewards.rewardsToken()).mint(actors[i], type(uint88).max);
            
        //     vm.startPrank(actors[i]);
        //     MockERC20(newStakingRewards.stakingToken()).approve(address(newStakingRewards), type(uint256).max);
        //     MockERC20(newStakingRewards.rewardsToken()).approve(address(newStakingRewards), type(uint256).max);
        //     vm.stopPrank();
        // }

        // _addStakingRewards(address(newStakingRewards));
    }

    function setup_newStakingRewards_same_stakingToken_rewardsToken(uint8 tokenDec) public asActor {
        // Disable for now, just want to keep the interface
        // address token = _newAsset(tokenDec);
        // StakingRewards newStakingRewards = _deployStakingRewards(token, token);

        // address[] memory actors = _getActors();
        // for (uint256 i = 0; i < actors.length; i++) {
        //     MockERC20(newStakingRewards.stakingToken()).mint(actors[i], type(uint88).max);
        //     MockERC20(newStakingRewards.rewardsToken()).mint(actors[i], type(uint88).max);
            
        //     vm.startPrank(actors[i]);
        //     MockERC20(newStakingRewards.stakingToken()).approve(address(newStakingRewards), type(uint256).max);
        //     MockERC20(newStakingRewards.rewardsToken()).approve(address(newStakingRewards), type(uint256).max);
        //     vm.stopPrank();
        // }

        // _addStakingRewards(address(newStakingRewards));
    }

    function _deployStakingRewards(
        address stakingToken,
        address rewardsToken
    ) internal returns (StakingRewards) {
        return new StakingRewards(
            address(this),
            address(this),
            stakingToken,
            rewardsToken
        );
    }

    /// === MODIFIERS === ///
    /// Prank admin and actor
    
    modifier asAdmin {
        vm.startPrank(address(this));
        _;
        vm.stopPrank();
    }

    modifier asActor {
        vm.startPrank(address(_getActor()));
        _;
        vm.stopPrank();
    }
}
