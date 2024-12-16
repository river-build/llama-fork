// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRegistryDiamond} from "src/interfaces/IRegistryDiamond.sol";
import {LlamaAccount} from "src/accounts/LlamaAccount.sol";
import {LlamaBaseScript} from "src/llama-scripts/LlamaBaseScript.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

/// @title Distribute Rewards V2 Script
contract DistributeRewardsV2ScriptBase is LlamaBaseScript {
  /// @notice The `RegistryDiamond` contract address.
  IRegistryDiamond public constant REGISTRY_DIAMOND = IRegistryDiamond(0x7c0422b31401C936172C897802CF0373B35B7698);

  /// @notice The Treasury Llama account address.
  LlamaAccount public constant RIVER_TREASURY = LlamaAccount(payable(0x8ee48C016b932A69779A25133b53F0fFf66C85C0));

  /// @notice The RVR ERC20 token address.
  IERC20 public constant RVR_TOKEN = IERC20(0x91930fd11ABAa5241241d3B07c02A8d0B5ac1920);

  function distributeRewards() external onlyDelegateCall {
    uint256 rewardAmount = REGISTRY_DIAMOND.getPeriodRewardAmount();

    RIVER_TREASURY.transferERC20(
      LlamaAccount.ERC20Data({
        token: RVR_TOKEN,
        recipient: address(REGISTRY_DIAMOND),
        amount: rewardAmount
      })
    );

    REGISTRY_DIAMOND.notifyRewardAmount(rewardAmount);
  }
}

/// @title Distribute Rewards V2 Script
contract DistributeRewardsV2ScriptBaseSepolia is LlamaBaseScript {
  /// @notice The `RegistryDiamond` contract address.
  IRegistryDiamond public constant REGISTRY_DIAMOND = IRegistryDiamond(0x08cC41b782F27d62995056a4EF2fCBAe0d3c266F);

  /// @notice The Treasury Llama account address.
  LlamaAccount public constant RIVER_TREASURY = LlamaAccount(payable(0x8ee48C016b932A69779A25133b53F0fFf66C85C0));

  /// @notice The RVR ERC20 token address.
  IERC20 public constant RVR_TOKEN = IERC20(0x24e3123E1b30E041E2df26Da9d6140c5B07Fe4F0);

  function distributeRewards() external onlyDelegateCall {
    uint256 rewardAmount = REGISTRY_DIAMOND.getPeriodRewardAmount();

    RIVER_TREASURY.transferERC20(
      LlamaAccount.ERC20Data({
        token: RVR_TOKEN,
        recipient: address(REGISTRY_DIAMOND),
        amount: rewardAmount
      })
    );

    REGISTRY_DIAMOND.notifyRewardAmount(rewardAmount);
  }
}
