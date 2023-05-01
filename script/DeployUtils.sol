// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VmSafe} from "forge-std/Vm.sol";
import {console2, stdJson} from "forge-std/Script.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {AbsoluteStrategyConfig, RelativeStrategyConfig, RoleHolderData, RolePermissionData} from "src/lib/Structs.sol";
import {RoleDescription} from "src/lib/UDVTs.sol";

library DeployUtils {
  using stdJson for string;

  address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
  VmSafe internal constant VM = VmSafe(VM_ADDRESS);

  uint8 public constant BOOTSTRAP_ROLE = 1;
  uint256 internal constant ONE_HUNDRED_IN_BPS = 10_000;

  struct RelativeStrategyJsonInputs {
    // Attributes need to be in alphabetical order so JSON decodes properly.
    uint64 approvalPeriod;
    uint8 approvalRole;
    uint8 disapprovalRole;
    uint64 expirationPeriod;
    uint8[] forceApprovalRoles;
    uint8[] forceDisapprovalRoles;
    bool isFixedLengthApprovalPeriod;
    uint16 minApprovalPct;
    uint16 minDisapprovalPct;
    uint64 queuingPeriod;
  }

  struct RoleHolderJsonInputs {
    // Attributes need to be in alphabetical order so JSON decodes properly.
    string comment;
    uint64 expiration;
    address policyholder;
    uint128 quantity;
    uint8 role;
  }

  struct RolePermissionJsonInputs {
    // Attributes need to be in alphabetical order so JSON decodes properly.
    string comment;
    bytes32 permissionId;
    uint8 role;
  }

  function print(string memory message) internal view {
    // Avoid getting flooded with logs during tests. Note that fork tests will show logs with this
    // approach, because there's currently no way to tell which environment we're in, e.g. script
    // or test. This is being tracked in https://github.com/foundry-rs/foundry/issues/2900.
    if (block.chainid != 31_337) console2.log(message);
  }

  function readScriptInput(string memory filename) internal view returns (string memory) {
    string memory inputDir = string.concat(VM.projectRoot(), "/script/input/");
    string memory chainDir = string.concat(VM.toString(block.chainid), "/");
    return VM.readFile(string.concat(inputDir, chainDir, filename));
  }

  function readRelativeStrategies(string memory jsonInput) internal pure returns (bytes[] memory) {
    bytes memory strategyData = jsonInput.parseRaw(".initialStrategies");
    RelativeStrategyJsonInputs[] memory rawStrategyConfigs = abi.decode(strategyData, (RelativeStrategyJsonInputs[]));

    RelativeStrategyConfig[] memory strategyConfigs = new RelativeStrategyConfig[](rawStrategyConfigs.length);
    for (uint256 i = 0; i < rawStrategyConfigs.length; i++) {
      RelativeStrategyJsonInputs memory rawStrategy = rawStrategyConfigs[i];
      strategyConfigs[i].approvalPeriod = rawStrategy.approvalPeriod;
      strategyConfigs[i].queuingPeriod = rawStrategy.queuingPeriod;
      strategyConfigs[i].expirationPeriod = rawStrategy.expirationPeriod;
      strategyConfigs[i].minApprovalPct = rawStrategy.minApprovalPct;
      strategyConfigs[i].minDisapprovalPct = rawStrategy.minDisapprovalPct;
      strategyConfigs[i].isFixedLengthApprovalPeriod = rawStrategy.isFixedLengthApprovalPeriod;
      strategyConfigs[i].approvalRole = rawStrategy.approvalRole;
      strategyConfigs[i].disapprovalRole = rawStrategy.disapprovalRole;
      strategyConfigs[i].forceApprovalRoles = rawStrategy.forceApprovalRoles;
      strategyConfigs[i].forceDisapprovalRoles = rawStrategy.forceDisapprovalRoles;
    }

    return encodeStrategyConfigs(strategyConfigs);
  }

  function readRoleDescriptions(string memory jsonInput) internal returns (RoleDescription[] memory roleDescriptions) {
    string[] memory descriptions = jsonInput.readStringArray(".initialRoleDescriptions");
    for (uint256 i; i < descriptions.length; i++) {
      require(bytes(descriptions[i]).length <= 32, "Role description is too long");
    }
    roleDescriptions = abi.decode(abi.encode(descriptions), (RoleDescription[]));
  }

  function readRoleHolders(string memory jsonInput) internal pure returns (RoleHolderData[] memory roleHolders) {
    bytes memory roleHolderData = jsonInput.parseRaw(".initialRoleHolders");
    RoleHolderJsonInputs[] memory rawRoleHolders = abi.decode(roleHolderData, (RoleHolderJsonInputs[]));

    roleHolders = new RoleHolderData[](rawRoleHolders.length);
    for (uint256 i = 0; i < rawRoleHolders.length; i++) {
      RoleHolderJsonInputs memory rawRoleHolder = rawRoleHolders[i];
      roleHolders[i].role = rawRoleHolder.role;
      roleHolders[i].policyholder = rawRoleHolder.policyholder;
      roleHolders[i].quantity = rawRoleHolder.quantity;
      roleHolders[i].expiration = rawRoleHolder.expiration;
    }
  }

  function readRolePermissions(string memory jsonInput)
    internal
    pure
    returns (RolePermissionData[] memory rolePermissions)
  {
    bytes memory rolePermissionData = jsonInput.parseRaw(".initialRolePermissions");
    RolePermissionJsonInputs[] memory rawRolePermissions = abi.decode(rolePermissionData, (RolePermissionJsonInputs[]));

    rolePermissions = new RolePermissionData[](rawRolePermissions.length);
    for (uint256 i = 0; i < rawRolePermissions.length; i++) {
      RolePermissionJsonInputs memory rawRolePermission = rawRolePermissions[i];
      rolePermissions[i].role = rawRolePermission.role;
      rolePermissions[i].permissionId = rawRolePermission.permissionId;
      rolePermissions[i].hasPermission = true;
    }
  }

  function encodeStrategy(RelativeStrategyConfig memory strategy) internal pure returns (bytes memory encoded) {
    encoded = abi.encode(strategy);
  }

  function encodeStrategy(AbsoluteStrategyConfig memory strategy) internal pure returns (bytes memory encoded) {
    encoded = abi.encode(strategy);
  }

  function encodeStrategyConfigs(RelativeStrategyConfig[] memory strategies)
    internal
    pure
    returns (bytes[] memory encoded)
  {
    encoded = new bytes[](strategies.length);
    for (uint256 i = 0; i < strategies.length; i++) {
      encoded[i] = encodeStrategy(strategies[i]);
    }
  }

  function encodeStrategyConfigs(AbsoluteStrategyConfig[] memory strategies)
    internal
    pure
    returns (bytes[] memory encoded)
  {
    encoded = new bytes[](strategies.length);
    for (uint256 i; i < strategies.length; i++) {
      encoded[i] = encodeStrategy(strategies[i]);
    }
  }

  function bootstrapSafetyCheck(string memory filename) internal view {
    // NOTE: This only supports relative strategies for now.

    // -------- Read data --------
    // Read the raw, encoded input file
    string memory jsonInput = readScriptInput(filename);

    // Get the list of role holders.
    RoleHolderData[] memory roleHolderData = readRoleHolders(jsonInput);

    // Get the bootstrap strategy, which is the first strategy in the list.
    bytes memory encodedStrategyConfigs = jsonInput.parseRaw(".initialStrategies");
    RelativeStrategyJsonInputs[] memory relativeStrategyConfigs =
      abi.decode(encodedStrategyConfigs, (RelativeStrategyJsonInputs[]));

    RelativeStrategyJsonInputs memory bootstrapStrategy = relativeStrategyConfigs[0];

    // -------- Validate data --------
    // For a bootstrap strategy to passable, we need at least one of the following to be true:
    //   1. The approval role is be the bootstrap role AND there are enough bootstrap role holders
    //      to pass an action.
    //   2. A force approval role is the bootstrap role AND there is at least one bootstrap role
    //      holder.

    // Get the number of role holders with Role ID 1, which is the bootstrap role.
    uint256 bootstrapRoleSupply = 0;
    for (uint256 i = 0; i < roleHolderData.length; i++) {
      if (roleHolderData[i].role == BOOTSTRAP_ROLE) bootstrapRoleSupply++;
    }

    // If no one holds that role, then the bootstrap strategy is not passable.
    require(bootstrapRoleSupply > 0, "No one holds the bootstrap role");

    // Check 1.
    bool isCheck1Satisfied = false;
    if (bootstrapStrategy.approvalRole == BOOTSTRAP_ROLE) {
      // Based on the bootstrap strategy config and number of bootstrap role holders, compute the
      // minimum number of role holders to pass a vote. The calculation here MUST match the one
      // in the RelativeStrategy's `_getMinimumAmountNeeded` method. This check should never fail
      // for relative strategies, but it's left in as a reminder that it needs to be checked for
      // absolute strategies.
      uint256 minPct = bootstrapStrategy.minApprovalPct;
      uint256 numApprovalsRequired = FixedPointMathLib.mulDivUp(bootstrapRoleSupply, minPct, ONE_HUNDRED_IN_BPS);

      if (bootstrapRoleSupply >= numApprovalsRequired) isCheck1Satisfied = true;
    }

    // Check 2.
    bool isCheck2Satisfied = false;
    for (uint256 i = 0; i < bootstrapStrategy.forceApprovalRoles.length; i++) {
      if (bootstrapStrategy.forceApprovalRoles[i] == BOOTSTRAP_ROLE) {
        isCheck2Satisfied = true;
        break;
      }
    }

    // If neither check is satisfied, the bootstrap strategy is invalid.
    string memory check1Result = string.concat("\n  check1: ", isCheck1Satisfied ? "true" : "false");
    string memory check2Result = string.concat("\n  check2: ", isCheck2Satisfied ? "true" : "false");
    require(
      isCheck1Satisfied || isCheck2Satisfied,
      string.concat("Bootstrap strategy is invalid", check1Result, check2Result, "\n")
    );
  }
}