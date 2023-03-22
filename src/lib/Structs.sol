// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {VertexStrategy} from "src/VertexStrategy.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/token/ERC1155/IERC1155.sol";

struct RoleHolderData {
  bytes32 role; // Name of the role to set.
  address user; // User to assign the role to.
  uint64 expiration; // When the role expires, or zero to remove the role.
}

struct RolePermissionData {
  bytes32 role; // Name of the role to set.
  bytes32 permissionId; // Permission ID to assign to the role.
  bool hasPermission; // Whether to assign the permission or remove the permission.
}

struct ExpiredRole {
  bytes32 role; // Role that has expired.
  address user; // User that held the role.
}

struct PermissionData {
  address target; // Contract being called by an action.
  bytes4 selector; // Selector of the function being called by an action.
  VertexStrategy strategy; // Strategy used to govern the action.
}

struct PermissionIdCheckpoint {
  uint128 timestamp; // Timestamp of the checkpoint, i.e. `block.timestamp`.
  uint128 quantity; // Quantity of the permission ID held at the timestamp.
}

struct Action {
  address creator; // msg.sender of createAction.
  bool executed; // has action executed.
  bool canceled; // is action canceled.
  bytes4 selector; // The function selector that will be called when the action is executed.
  VertexStrategy strategy; // strategy that determines the validation process of this action.
  address target; // The contract called when the action is executed
  bytes data; //  The encoded arguments to be passed to the function that is called when the action is executed.
  uint256 value; // The value in wei to be sent when the action is executed.
  uint256 creationTime; // The timestamp when action was created (used for policy snapshots).
  uint256 executionTime; // Only set when an action is queued. The timestamp when action execution can begin.
  uint256 totalApprovals; // The total weight of policyholder approvals.
  uint256 totalDisapprovals; // The total weight of policyholder disapprovals.
  uint256 approvalPolicySupply; // The total amount of policyholders eligible to approve.
  uint256 disapprovalPolicySupply; // The total amount of policyholders eligible to disapprove.
}

struct Strategy {
  uint256 approvalPeriod; // The length of time of the approval period.
  uint256 queuingPeriod; // The length of time of the queuing period. The disapproval period is the queuing period when
    // enabled.
  uint256 expirationPeriod; // The length of time an action can be executed before it expires.
  uint256 minApprovalPct; // Minimum percentage of total approval weight / total approval supply.
  uint256 minDisapprovalPct; // Minimum percentage of total disapproval weight / total disapproval supply.
  bool isFixedLengthApprovalPeriod; // Determines if an action be queued before approvalEndTime.
  bytes32 approvalRole; // Anyone with this role can vote to approve an action.
  bytes32 disapprovalRole; // Anyone with this role can vote to disapprove an action.
  bytes32[] forceApprovalRoles; // Anyone with this role can single-handedly approve an action.
  bytes32[] forceDisapprovalRoles; // Anyone with this role can single-handedly disapprove an action.
}

struct ERC20Data {
  IERC20 token; // The ERC20 token to transfer
  address recipient; // The address to transfer the token to
  uint256 amount; // The amount of tokens to transfer
}

struct ERC721Data {
  IERC721 token; // The ERC721 token to transfer
  address recipient; // The address to transfer the token to
  uint256 tokenId; // The tokenId of the token to transfer
}

struct ERC721OperatorData {
  IERC721 token; // The ERC721 token to transfer
  address recipient; // The address to transfer the token to
  bool approved; // Whether to approve or revoke allowance
}

struct ERC1155Data {
  IERC1155 token; // The ERC1155 token to transfer
  address recipient; // The address to transfer the token to
  uint256 tokenId; // The tokenId of the token to transfer
  uint256 amount; // The amount of tokens to transfer
  bytes data; // The data to pass to the ERC1155 token
}

struct ERC1155BatchData {
  IERC1155 token; // The ERC1155 token to transfer
  address recipient; // The address to transfer the token to
  uint256[] tokenIds; // The tokenId of the token to transfer
  uint256[] amounts; // The amount of tokens to transfer
  bytes data; // The data to pass to the ERC1155 token
}

struct ERC1155OperatorData {
  IERC1155 token; // The ERC1155 token to transfer
  address recipient; // The address to transfer the token to
  bool approved; // Whether to approve or revoke allowance
}
