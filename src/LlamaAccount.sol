// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {IERC1155} from "@openzeppelin/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";
import {Address} from "@openzeppelin/utils/Address.sol";

import {
  ERC20Data,
  ERC721Data,
  ERC721OperatorData,
  ERC1155Data,
  ERC1155BatchData,
  ERC1155OperatorData
} from "src/lib/Structs.sol";

/// @title Llama Account
/// @author Llama (devsdosomething@llama.xyz)
/// @notice The contract that holds the Llama instance's assets.
contract LlamaAccount is ERC721Holder, ERC1155Holder, Initializable {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /// @dev Data for sending native tokens to recipients.
  struct NativeTokenData {
    address payable recipient;
    uint256 amount;
  }

  // ======================================
  // ======== Errors and Modifiers ========
  // ======================================

  error OnlyLlama();
  error Invalid0xRecipient();
  error FailedExecution(bytes result);

  modifier onlyLlama() {
    if (msg.sender != llamaCore) revert OnlyLlama();
    _;
  }

  // =============================================================
  // ======== Constants, Immutables and Storage Variables ========
  // =============================================================

  /// @notice Name of this Llama Account.
  string public name;

  /// @notice Llama instance.
  address public llamaCore;

  // ======================================================
  // ======== Contract Creation and Initialization ========
  // ======================================================

  constructor() initializer {}

  /// @notice Initializes a new LlamaAccount clone.
  /// @param _name The name of the LlamaAccount clone.
  function initialize(string memory _name) external initializer {
    llamaCore = msg.sender;
    name = _name;
  }

  // ===========================================
  // ======== External and Public Logic ========
  // ===========================================

  // -------- Native Token --------

  /// @notice Function for Llama Account to receive native token.
  receive() external payable {}

  /// @notice Function for the llama instance to transfer native tokens to other parties.
  /// @param nativeTokenData The data of the native token transfer.
  function transferNativeToken(NativeTokenData calldata nativeTokenData) public onlyLlama {
    if (nativeTokenData.recipient == address(0)) revert Invalid0xRecipient();
    nativeTokenData.recipient.sendValue(nativeTokenData.amount);
  }

  /// @notice Function for the llama instance to batch transfer native tokens to other parties.
  /// @param nativeTokenData The data of the native token transfer.
  function batchTransferNativeToken(NativeTokenData[] calldata nativeTokenData) external onlyLlama {
    uint256 length = nativeTokenData.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      transferNativeToken(nativeTokenData[i]);
    }
  }

  // -------- ERC20 Token --------

  /// @notice Function for the llama instance to transfer ERC20 tokens to other parties.
  /// @param erc20Data The data of the ERC20 transfer.
  function transferERC20(ERC20Data calldata erc20Data) public onlyLlama {
    if (erc20Data.recipient == address(0)) revert Invalid0xRecipient();
    erc20Data.token.safeTransfer(erc20Data.recipient, erc20Data.amount);
  }

  /// @notice Function for the llama instance to batch transfer ERC20 tokens to other parties.
  /// @param erc20Data The data of the ERC20 transfers.
  function batchTransferERC20(ERC20Data[] calldata erc20Data) external onlyLlama {
    uint256 length = erc20Data.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      transferERC20(erc20Data[i]);
    }
  }

  /// @notice Function for the llama instance to give ERC20 allowance to other parties.
  /// @param erc20Data The data of the ERC20 allowance.
  function approveERC20(ERC20Data calldata erc20Data) public onlyLlama {
    erc20Data.token.safeApprove(erc20Data.recipient, erc20Data.amount);
  }

  /// @notice Function for the llama instance to batch give ERC20 allowance to other parties.
  /// @param erc20Data The data of the ERC20 allowances.
  function batchApproveERC20(ERC20Data[] calldata erc20Data) external onlyLlama {
    uint256 length = erc20Data.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      approveERC20(erc20Data[i]);
    }
  }

  // -------- ERC721 Token --------

  /// @notice Function for the llama instance to transfer ERC721 tokens to other parties.
  /// @param erc721Data The data of the ERC721 transfer.
  function transferERC721(ERC721Data calldata erc721Data) public onlyLlama {
    if (erc721Data.recipient == address(0)) revert Invalid0xRecipient();
    erc721Data.token.transferFrom(address(this), erc721Data.recipient, erc721Data.tokenId);
  }

  /// @notice Function for the llama instance to batch transfer ERC721 tokens to other parties.
  /// @param erc721Data The data of the ERC721 transfers.
  function batchTransferERC721(ERC721Data[] calldata erc721Data) external onlyLlama {
    uint256 length = erc721Data.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      transferERC721(erc721Data[i]);
    }
  }

  /// @notice Function for the llama instance to give ERC721 allowance to other parties.
  /// @param erc721Data The data of the ERC721 allowance.
  function approveERC721(ERC721Data calldata erc721Data) public onlyLlama {
    erc721Data.token.approve(erc721Data.recipient, erc721Data.tokenId);
  }

  /// @notice Function for the llama instance to batch give ERC721 allowance to other parties.
  /// @param erc721Data The data of the ERC721 allowances.
  function batchApproveERC721(ERC721Data[] calldata erc721Data) external onlyLlama {
    uint256 length = erc721Data.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      approveERC721(erc721Data[i]);
    }
  }

  /// @notice Function for the llama instance to give ERC721 operator allowance to other parties.
  /// @param erc721OperatorData The data of the ERC721 operator allowance.
  function approveOperatorERC721(ERC721OperatorData calldata erc721OperatorData) public onlyLlama {
    erc721OperatorData.token.setApprovalForAll(erc721OperatorData.recipient, erc721OperatorData.approved);
  }

  /// @notice Function for the llama instance to batch give ERC721 operator allowance to other parties.
  /// @param erc721OperatorData The data of the ERC721 operator allowances.
  function batchApproveOperatorERC721(ERC721OperatorData[] calldata erc721OperatorData) external onlyLlama {
    uint256 length = erc721OperatorData.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      approveOperatorERC721(erc721OperatorData[i]);
    }
  }

  // -------- ERC1155 Token --------

  /// @notice Function for the llama instance to transfer ERC1155 tokens to other parties.
  /// @param erc1155Data The data of the ERC1155 transfer.
  function transferERC1155(ERC1155Data calldata erc1155Data) external onlyLlama {
    if (erc1155Data.recipient == address(0)) revert Invalid0xRecipient();
    erc1155Data.token.safeTransferFrom(
      address(this), erc1155Data.recipient, erc1155Data.tokenId, erc1155Data.amount, erc1155Data.data
    );
  }

  /// @notice Function for the llama instance to batch transfer ERC1155 tokens of a single ERC1155 collection to other
  /// parties.
  /// @param erc1155BatchData The data of the ERC1155 batch transfer.
  function batchTransferSingleERC1155(ERC1155BatchData calldata erc1155BatchData) public onlyLlama {
    if (erc1155BatchData.recipient == address(0)) revert Invalid0xRecipient();
    erc1155BatchData.token.safeBatchTransferFrom(
      address(this),
      erc1155BatchData.recipient,
      erc1155BatchData.tokenIds,
      erc1155BatchData.amounts,
      erc1155BatchData.data
    );
  }

  /// @notice Function for the llama instance to batch transfer ERC1155 tokens of multiple ERC1155 collections to other
  /// parties.
  /// @param erc1155BatchData The data of the ERC1155 batch transfers.
  function batchTransferMultipleERC1155(ERC1155BatchData[] calldata erc1155BatchData) external onlyLlama {
    uint256 length = erc1155BatchData.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      batchTransferSingleERC1155(erc1155BatchData[i]);
    }
  }

  /// @notice Function for the llama instance to give ERC1155 operator allowance to other parties.
  /// @param erc1155OperatorData The data of the ERC1155 operator allowance.
  function approveOperatorERC1155(ERC1155OperatorData calldata erc1155OperatorData) public onlyLlama {
    erc1155OperatorData.token.setApprovalForAll(erc1155OperatorData.recipient, erc1155OperatorData.approved);
  }

  /// @notice Function for the llama instance to batch give ERC1155 operator allowance to other parties.
  /// @param erc1155OperatorData The data of the ERC1155 operator allowances.
  function batchApproveOperatorERC1155(ERC1155OperatorData[] calldata erc1155OperatorData) external onlyLlama {
    uint256 length = erc1155OperatorData.length;
    for (uint256 i = 0; i < length; i = _uncheckedIncrement(i)) {
      approveOperatorERC1155(erc1155OperatorData[i]);
    }
  }

  // -------- Generic Execution --------

  /// @notice Function for the llama instance to execute arbitrary calls.
  /// @param target The address of the contract to call.
  /// @param callData The call data to pass to the contract.
  /// @param withDelegatecall Whether to use delegatecall or call.
  function execute(address target, bytes calldata callData, bool withDelegatecall)
    external
    payable
    onlyLlama
    returns (bytes memory)
  {
    bool success;
    bytes memory result;

    if (withDelegatecall) (success, result) = target.delegatecall(callData);
    else (success, result) = target.call{value: msg.value}(callData);

    if (!success) revert FailedExecution(result);
    return result;
  }

  // ================================
  // ======== Internal Logic ========
  // ================================

  function _uncheckedIncrement(uint256 i) internal pure returns (uint256) {
    unchecked {
      return i + 1;
    }
  }
}