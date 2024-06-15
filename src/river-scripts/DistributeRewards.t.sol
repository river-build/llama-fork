// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "forge-std/console.sol";
import {Test, console2} from "forge-std/Test.sol";

import {LlamaCore} from "src/LlamaCore.sol";
import {LlamaAccount} from "src/accounts/LlamaAccount.sol";
import {LlamaExecutor} from "src/LlamaExecutor.sol";
import {IOptimismMintableERC20} from "src/interfaces/IOptimismMintableERC20.sol";
import {IRewardsDistribution} from "src/interfaces/IRewardsDistribution.sol";
import {DistributeRewardsScriptBase, DistributeRewardsScriptBaseSepolia} from "src/llama-scripts/DistributeRewardsScript.sol";
import {LlamaTestSetup} from "test/utils/LlamaTestSetup.sol";

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

// Base Sepolia test
contract DistributeRewardsTestSetupBaseSepolia is LlamaTestSetup {
  // RIVER_EXECUTOR, RIVER_CORE addresses identical on base, base_sepolia
  address public constant RIVER_EXECUTOR = 0x63217D4c321CC02Ed306cB3843309184D347667B;
  address public constant RIVER_CORE = 0xA547373eB2b3c93AdeB27ec72133Fb7B92F70F7f;
  uint256 public constant BLOCK_NUMBER = 11_312_872;
  DistributeRewardsScriptBaseSepolia public rewardsScript;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl("base_sepolia"), 11_312_872);
    rewardsScript = new DistributeRewardsScriptBaseSepolia();
  }
}

contract DistributeRewardsBaseSepolia is DistributeRewardsTestSetupBaseSepolia {
  function test_BaseSepolia_DistributeRewards() public {
    // check block number
    assertEq(block.number, BLOCK_NUMBER);
    // Authorize script
    vm.prank(address(RIVER_EXECUTOR));
    LlamaCore(RIVER_CORE).setScriptAuthorization(address(rewardsScript), true);

    // Call distributeRewardsFromTreasury
    vm.prank(address(RIVER_CORE));
    LlamaExecutor(RIVER_EXECUTOR).execute(
      address(rewardsScript), true, abi.encodeWithSignature("distributeOperatorRewards()")
    );
  }
}

// Base test
contract DistributeRewardsTestSetupBase is LlamaTestSetup {
  address public constant RIVER_EXECUTOR = 0x63217D4c321CC02Ed306cB3843309184D347667B;
  address public constant RIVER_CORE = 0xA547373eB2b3c93AdeB27ec72133Fb7B92F70F7f;
  uint256 public constant BLOCK_NUMBER = 15_851_201;
  /// @dev The Treasury Llama account address.
  address public constant RIVER_TREASURY = 0x8ee48C016b932A69779A25133b53F0fFf66C85C0;
  /// @dev The RVR ERC20 token address.
  IOptimismMintableERC20 internal constant RVR_TOKEN = IOptimismMintableERC20(0x9172852305F32819469bf38A3772f29361d7b768);
  /// Base Registry
  address internal constant REGISTRY_DIAMOND = 0x7c0422b31401C936172C897802CF0373B35B7698;
  IRewardsDistribution internal constant REWARDS_DISTRIBUTION = IRewardsDistribution(REGISTRY_DIAMOND);
  /// @dev The Base Bridge.
  address internal constant BRIDGE_BASE = 0x4200000000000000000000000000000000000010;
  uint256 internal constant PERIOD_AMOUNT = 30_769_230;
  DistributeRewardsScriptBase public rewardsScript;

  /// operators
  address internal constant FRAMEWORK = 0x09285F179a9bA06CEBA12DeCd1755Ac6942A8cf4;


  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl("base"), BLOCK_NUMBER);
    rewardsScript = new DistributeRewardsScriptBase();
    // mint RVR from Bridge
    console.log("RIVER_TREASURY: ", RIVER_TREASURY);
    vm.prank(BRIDGE_BASE);
    // mint a little more than period amount to RIVER_TREASURY
    RVR_TOKEN.mint(RIVER_TREASURY, PERIOD_AMOUNT + 1);
    uint256 bal = RVR_TOKEN.balanceOf(RIVER_TREASURY);
    console.log("RVR_TOKEN.balanceOf(RIVER_TREASURY): ", bal);
  }
}

contract DistributeRewardsBase is DistributeRewardsTestSetupBase {
  function test_Base_DistributeRewards() public {
    // check block number
    assertEq(block.number, BLOCK_NUMBER);
    // assert treasury balance
    assertEq(RVR_TOKEN.balanceOf(RIVER_TREASURY), PERIOD_AMOUNT + 1);
    // check period distribution amount
    uint256 periodDistributionAmount = REWARDS_DISTRIBUTION.getPeriodDistributionAmount();
    console.log("periodDistributionAmount: ", periodDistributionAmount);
    // check an operators claimable amount before distribution
    uint256 frameworkClaimableAmt = REWARDS_DISTRIBUTION.getClaimableAmountForOperator(FRAMEWORK);
    console.log("frameworkClaimableAmt: ", frameworkClaimableAmt);
    // Authorize script
    vm.prank(address(RIVER_EXECUTOR));
    LlamaCore(RIVER_CORE).setScriptAuthorization(address(rewardsScript), true);

    // Call distributeRewardsFromTreasury
    vm.prank(address(RIVER_CORE));
    LlamaExecutor(RIVER_EXECUTOR).execute(
      address(rewardsScript), true, abi.encodeWithSignature("distributeOperatorRewards()")
    );
    // get claimable amount after distributing rewards
    uint256 frameworkClaimableAmtPost = REWARDS_DISTRIBUTION.getClaimableAmountForOperator(FRAMEWORK);
    console.log("frameworkClaimableAmt: ", frameworkClaimableAmtPost);
  }
}