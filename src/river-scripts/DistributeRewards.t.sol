// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";

import {LlamaCore} from "src/LlamaCore.sol";
import {LlamaExecutor} from "src/LlamaExecutor.sol";
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
  uint256 public constant BLOCK_NUMBER = 15_848_234;
  DistributeRewardsScriptBase public rewardsScript;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl("base"), BLOCK_NUMBER);
    rewardsScript = new DistributeRewardsScriptBase();
  }
}

contract DistributeRewardsBase is DistributeRewardsTestSetupBase {
  function test_Base_DistributeRewards() public {
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