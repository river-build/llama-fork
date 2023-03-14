// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Clones} from "@openzeppelin/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {IVertexCore} from "src/interfaces/IVertexCore.sol";
import {VertexStrategy} from "src/VertexStrategy.sol";
import {VertexPolicy} from "src/VertexPolicy.sol";
import {VertexAccount} from "src/VertexAccount.sol";
import {ActionState} from "src/lib/Enums.sol";
import {Action, PermissionData, Strategy} from "src/lib/Structs.sol";

/// @title Core of a Vertex system
/// @author Llama (vertex@llama.xyz)
/// @notice Main point of interaction with a Vertex system.
contract VertexCore is IVertexCore, Initializable {
  error InvalidStrategy();
  error InvalidCancelation();
  error InvalidActionId();
  error OnlyQueuedActions();
  error InvalidStateForQueue();
  error ActionCannotBeCanceled();
  error OnlyVertex();
  error ActionNotActive();
  error ActionNotQueued();
  error InvalidSignature();
  error TimelockNotFinished();
  error FailedActionExecution();
  error DuplicateApproval();
  error DuplicateDisapproval();
  error DisapproveDisabled();
  error PolicyholderDoesNotHavePermission();
  error InsufficientMsgValue();
  error ApprovalRoleHasZeroSupply();
  error DisapprovalRoleHasZeroSupply();

  /// @notice EIP-712 base typehash.
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice EIP-712 approval typehash.
  bytes32 public constant APPROVAL_EMITTED_TYPEHASH = keccak256("PolicyholderApproved(uint256 id,address policyholder)");

  /// @notice EIP-712 disapproval typehash.
  bytes32 public constant DISAPPROVAL_EMITTED_TYPEHASH =
    keccak256("PolicyholderDisapproved(uint256 id,address policyholder)");

  /// @notice Equivalent to 100%, but scaled for precision
  uint256 internal constant ONE_HUNDRED_IN_BPS = 10_000;

  /// @notice The Vertex Strategy implementation (logic) contract.
  VertexStrategy public vertexStrategyLogic;

  /// @notice The Vertex Account implementation (logic) contract.
  VertexAccount public vertexAccountLogic;

  /// @notice The NFT contract that defines the policies for this Vertex system.
  VertexPolicy public policy;

  /// @notice Name of this Vertex system.
  string public name;

  /// @notice The current number of actions created.
  uint256 public actionsCount;

  /// @notice Mapping of actionIds to Actions.
  /// @dev Making this `public` results in stack too deep with no optimizer, but this data can be
  /// accessed with the `getAction` function so this is ok. We want the contracts to compile
  /// without the optimizer so `forge coverage` can be used.
  mapping(uint256 => Action) internal actions;

  /// @notice Mapping of actionIds to policyholders to approvals.
  mapping(uint256 => mapping(address => bool)) public approvals;

  /// @notice Mapping of action ids to policyholders to disapprovals.
  mapping(uint256 => mapping(address => bool)) public disapprovals;

  /// @notice Mapping of all authorized strategies.
  mapping(VertexStrategy => bool) public authorizedStrategies;

  constructor() initializer {}

  modifier onlyVertex() {
    if (msg.sender != address(this)) revert OnlyVertex();
    _;
  }

  function initialize(
    string memory _name,
    VertexPolicy _policy,
    VertexStrategy _vertexStrategyLogic,
    VertexAccount _vertexAccountLogic,
    Strategy[] calldata initialStrategies,
    string[] calldata initialAccounts
  ) external override initializer {
    name = _name;
    policy = _policy;
    vertexStrategyLogic = _vertexStrategyLogic;
    vertexAccountLogic = _vertexAccountLogic;

    _deployStrategies(initialStrategies, _policy);
    _deployAccounts(initialAccounts);
  }

  /// @inheritdoc IVertexCore
  function createAction(VertexStrategy strategy, address target, uint256 value, bytes4 selector, bytes calldata data)
    external
    override
    returns (uint256)
  {
    if (!authorizedStrategies[strategy]) revert InvalidStrategy();

    PermissionData memory permission = PermissionData({target: target, selector: selector, strategy: strategy});
    bytes32 permissionId = keccak256(abi.encode(permission));
    if (!policy.hasPermission(uint256(uint160(msg.sender)), permissionId)) revert PolicyholderDoesNotHavePermission();

    uint256 previousActionCount = actionsCount;
    Action storage newAction = actions[previousActionCount];

    uint256 approvalPolicySupply = policy.totalSupplyAt(strategy.approvalRole(), block.timestamp);
    if (approvalPolicySupply == 0) revert ApprovalRoleHasZeroSupply();
    uint256 disapprovalPolicySupply = policy.totalSupplyAt(strategy.disapprovalRole(), block.timestamp);
    if (disapprovalPolicySupply == 0) revert DisapprovalRoleHasZeroSupply();

    newAction.creator = msg.sender;
    newAction.strategy = strategy;
    newAction.target = target;
    newAction.value = value;
    newAction.selector = selector;
    newAction.data = data;
    newAction.creationTime = block.timestamp;
    newAction.approvalPolicySupply = approvalPolicySupply;
    newAction.disapprovalPolicySupply = disapprovalPolicySupply;

    unchecked {
      ++actionsCount;
    }

    emit ActionCreated(previousActionCount, msg.sender, strategy, target, value, selector, data);

    return previousActionCount;
  }

  /// @inheritdoc IVertexCore
  function queueAction(uint256 actionId) external override {
    if (getActionState(actionId) != ActionState.Approved) revert InvalidStateForQueue();
    Action storage action = actions[actionId];
    uint256 executionTime = block.timestamp + action.strategy.queuingPeriod();

    action.executionTime = executionTime;

    emit ActionQueued(actionId, msg.sender, action.strategy, action.creator, executionTime);
  }

  /// @inheritdoc IVertexCore
  function executeAction(uint256 actionId) external payable override returns (bytes memory) {
    if (getActionState(actionId) != ActionState.Queued) revert OnlyQueuedActions();

    Action storage action = actions[actionId];
    if (block.timestamp < action.executionTime) revert TimelockNotFinished();
    if (msg.value < action.value) revert InsufficientMsgValue();

    action.executed = true;

    (bool success, bytes memory result) =
      action.target.call{value: action.value}(abi.encodePacked(action.selector, action.data));

    if (!success) revert FailedActionExecution();

    emit ActionExecuted(actionId, msg.sender, action.strategy, action.creator);

    return result;
  }

  /// @inheritdoc IVertexCore
  function cancelAction(uint256 actionId) external override {
    ActionState state = getActionState(actionId);
    if (
      state == ActionState.Executed || state == ActionState.Canceled || state == ActionState.Expired
        || state == ActionState.Failed
    ) revert InvalidCancelation();

    Action storage action = actions[actionId];
    if (!(msg.sender == action.creator || action.strategy.isActionCancelationValid(actionId))) {
      revert ActionCannotBeCanceled();
    }

    action.canceled = true;

    emit ActionCanceled(actionId);
  }

  /// @inheritdoc IVertexCore
  function submitApproval(uint256 actionId, bytes32 role) external override {
    return _submitApproval(msg.sender, role, actionId);
  }

  /// @inheritdoc IVertexCore
  function submitApprovalBySignature(uint256 actionId, bytes32 role, uint8 v, bytes32 r, bytes32 s) external override {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this))),
        keccak256(abi.encode(APPROVAL_EMITTED_TYPEHASH, actionId, msg.sender))
      )
    );
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0)) revert InvalidSignature();
    return _submitApproval(signer, role, actionId);
  }

  /// @inheritdoc IVertexCore
  function submitDisapproval(uint256 actionId, bytes32 role) external override {
    return _submitDisapproval(msg.sender, role, actionId);
  }

  /// @inheritdoc IVertexCore
  function submitDisapprovalBySignature(uint256 actionId, bytes32 role, uint8 v, bytes32 r, bytes32 s)
    external
    override
  {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this))),
        keccak256(abi.encode(DISAPPROVAL_EMITTED_TYPEHASH, actionId, msg.sender))
      )
    );
    address signer = ecrecover(digest, v, r, s);
    if (signer == address(0)) revert InvalidSignature();
    return _submitDisapproval(signer, role, actionId);
  }

  /// @inheritdoc IVertexCore
  function createAndAuthorizeStrategies(Strategy[] calldata strategies) external override onlyVertex {
    _deployStrategies(strategies, policy);
  }

  /// @inheritdoc IVertexCore
  function unauthorizeStrategies(VertexStrategy[] calldata strategies) external override onlyVertex {
    uint256 strategiesLength = strategies.length;
    unchecked {
      for (uint256 i = 0; i < strategiesLength; ++i) {
        delete authorizedStrategies[strategies[i]];
        emit StrategyUnauthorized(strategies[i]);
      }
    }
  }

  /// @inheritdoc IVertexCore
  function createAndAuthorizeAccounts(string[] calldata accounts) external override onlyVertex {
    _deployAccounts(accounts);
  }

  /// @inheritdoc IVertexCore
  function isActionExpired(uint256 actionId) public view override returns (bool) {
    Action storage action = actions[actionId];
    return block.timestamp >= action.executionTime + action.strategy.expirationPeriod();
  }

  /// @inheritdoc IVertexCore
  function getAction(uint256 actionId) external view override returns (Action memory) {
    return actions[actionId];
  }

  /// @inheritdoc IVertexCore
  function getActionState(uint256 actionId) public view override returns (ActionState) {
    if (actionId >= actionsCount) revert InvalidActionId();
    Action storage action = actions[actionId];
    uint256 approvalEndTime = action.creationTime + action.strategy.approvalPeriod();

    if (action.canceled) return ActionState.Canceled;

    if (
      block.timestamp < approvalEndTime
        && (action.strategy.isFixedLengthApprovalPeriod() || !action.strategy.isActionPassed(actionId))
    ) return ActionState.Active;

    if (!action.strategy.isActionPassed(actionId)) return ActionState.Failed;

    if (action.executionTime == 0) return ActionState.Approved;

    if (action.executed) return ActionState.Executed;

    if (isActionExpired(actionId)) return ActionState.Expired;

    return ActionState.Queued;
  }

  function _submitApproval(address policyholder, bytes32 role, uint256 actionId) internal {
    if (getActionState(actionId) != ActionState.Active) revert ActionNotActive();
    bool hasApproved = approvals[actionId][policyholder];
    if (hasApproved) revert DuplicateApproval();

    Action storage action = actions[actionId];
    uint256 weight = action.strategy.getApprovalWeightAt(policyholder, role, action.creationTime);

    action.totalApprovals = action.totalApprovals == type(uint256).max || weight == type(uint256).max
      ? type(uint256).max
      : action.totalApprovals + weight;
    approvals[actionId][policyholder] = true;

    emit PolicyholderApproved(actionId, policyholder, weight);
  }

  function _submitDisapproval(address policyholder, bytes32 role, uint256 actionId) internal {
    if (getActionState(actionId) != ActionState.Queued) revert ActionNotQueued();
    bool hasDisapproved = disapprovals[actionId][policyholder];
    if (hasDisapproved) revert DuplicateDisapproval();

    Action storage action = actions[actionId];

    if (action.strategy.minDisapprovalPct() > ONE_HUNDRED_IN_BPS) revert DisapproveDisabled();

    uint256 weight = action.strategy.getDisapprovalWeightAt(policyholder, role, action.creationTime);

    action.totalDisapprovals = action.totalDisapprovals == type(uint256).max || weight == type(uint256).max
      ? type(uint256).max
      : action.totalDisapprovals + weight;
    disapprovals[actionId][policyholder] = true;

    emit PolicyholderDisapproved(actionId, policyholder, weight);
  }

  function _deployAccounts(string[] calldata accounts) internal {
    uint256 accountLength = accounts.length;
    unchecked {
      for (uint256 i; i < accountLength; ++i) {
        bytes32 salt = bytes32(keccak256(abi.encode(accounts[i])));
        VertexAccount account = VertexAccount(payable(Clones.cloneDeterministic(address(vertexAccountLogic), salt)));
        account.initialize(accounts[i], address(this));
        emit AccountAuthorized(account, accounts[i]);
      }
    }
  }

  function _deployStrategies(Strategy[] calldata strategies, VertexPolicy _policy) internal {
    uint256 strategyLength = strategies.length;
    unchecked {
      for (uint256 i; i < strategyLength; ++i) {
        bytes32 salt = bytes32(
          keccak256(
            abi.encodePacked(
              strategies[i].approvalPeriod,
              strategies[i].queuingPeriod,
              strategies[i].expirationPeriod,
              strategies[i].minApprovalPct,
              strategies[i].minDisapprovalPct,
              strategies[i].isFixedLengthApprovalPeriod
            )
          )
        );

        VertexStrategy strategy = VertexStrategy(Clones.cloneDeterministic(address(vertexStrategyLogic), salt));
        strategy.initialize(strategies[i], _policy, IVertexCore(address(this)));
        authorizedStrategies[strategy] = true;
        emit StrategyAuthorized(strategy, strategies[i]);
      }
    }
  }
}