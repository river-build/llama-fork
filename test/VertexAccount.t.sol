// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {Clones} from "@openzeppelin/proxy/Clones.sol";
import {VertexCore} from "src/VertexCore.sol";
import {VertexAccount} from "src/VertexAccount.sol";
import {VertexFactory} from "src/VertexFactory.sol";
import {VertexPolicy} from "src/VertexPolicy.sol";
import {Strategy, PolicyGrantData, PermissionMetadata} from "src/lib/Structs.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/token/ERC1155/IERC1155.sol";
import {TestScript} from "test/mock/scripts/TestScript.sol";
import {ICryptoPunk} from "test/mock/external/ICryptoPunk.sol";
import {
  ERC20Data,
  ERC721Data,
  ERC721OperatorData,
  ERC1155Data,
  ERC1155BatchData,
  ERC1155OperatorData
} from "src/lib/Structs.sol";
import {VertexTestSetup} from "test/utils/VertexTestSetup.sol";

contract VertexAccountTest is VertexTestSetup {
  // Testing Parameters
  // Native Token
  address public constant ETH_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
  uint256 public constant ETH_AMOUNT = 1000e18;

  // ERC20 Token
  IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address public constant USDC_WHALE = 0x55FE002aefF02F77364de339a1292923A15844B8;
  uint256 public constant USDC_AMOUNT = 1000e6;

  IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address public constant USDT_WHALE = 0xA7A93fd0a276fc1C0197a5B5623eD117786eeD06;
  uint256 public constant USDT_AMOUNT = 1000e6;

  IERC20 public constant UNI = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
  address public constant UNI_WHALE = 0x47173B170C64d16393a52e6C480b3Ad8c302ba1e;
  uint256 public constant UNI_AMOUNT = 1000e18;

  // ERC721 Token
  IERC721 public constant BAYC = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
  address public constant BAYC_WHALE = 0x619866736a3a101f65cfF3A8c3d2602fC54Fd749;
  uint256 public constant BAYC_ID = 27;
  uint256 public constant BAYC_ID_2 = 8885;

  IERC721 public constant NOUNS = IERC721(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
  address public constant NOUNS_WHALE = 0x2573C60a6D127755aA2DC85e342F7da2378a0Cc5;
  uint256 public constant NOUNS_ID = 540;
  uint256 public constant NOUNS_ID_2 = 550;

  // Non-standard NFT
  ICryptoPunk public constant PUNK = ICryptoPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
  address public constant PUNK_WHALE = 0xB88F61E6FbdA83fbfffAbE364112137480398018;
  uint256 public constant PUNK_ID = 9313;

  // ERC1155 Token
  IERC1155 public constant RARI = IERC1155(0xd07dc4262BCDbf85190C01c996b4C06a461d2430);
  address public constant RARI_WHALE = 0xEdba5d56d0147aee8a227D284bcAaC03B4a87eD4;
  uint256 public constant RARI_ID_1 = 657_774;
  uint256 public constant RARI_ID_1_AMOUNT = 3;
  uint256 public constant RARI_ID_2 = 74_385;
  uint256 public constant RARI_ID_2_AMOUNT = 1;

  IERC1155 public constant OPENSTORE = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);
  address public constant OPENSTORE_WHALE = 0xaBA7161A7fb69c88e16ED9f455CE62B791EE4D03;
  uint256 public constant OPENSTORE_ID_1 =
    50_227_944_111_491_829_717_518_767_573_293_673_148_720_215_112_283_513_814_059_266_953_762_918_367_332;
  uint256 public constant OPENSTORE_ID_1_AMOUNT = 20;
  uint256 public constant OPENSTORE_ID_2 =
    25_221_312_271_773_506_578_423_917_291_534_224_130_165_348_289_584_384_465_161_209_685_514_687_348_761;
  uint256 public constant OPENSTORE_ID_2_AMOUNT = 1;

  address account1Addr;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl("mainnet"), 16_573_464);
    VertexTestSetup.setUp();
    account1Addr = address(account1); // For convenience, to avoid tons of casting to address.
  }

  /*///////////////////////////////////////////////////////////////
                            Unit tests
    //////////////////////////////////////////////////////////////*/

  // transfer Native unit tests
  function test_transfer_TransferETH() public {
    _transferETHToAccount(ETH_AMOUNT);

    uint256 accountETHBalance = account1Addr.balance;
    uint256 whaleETHBalance = ETH_WHALE.balance;

    // Transfer ETH from account to whale
    vm.startPrank(address(core));
    account1.transfer(payable(ETH_WHALE), ETH_AMOUNT);
    assertEq(account1Addr.balance, 0);
    assertEq(account1Addr.balance, accountETHBalance - ETH_AMOUNT);
    assertEq(ETH_WHALE.balance, whaleETHBalance + ETH_AMOUNT);
    vm.stopPrank();
  }

  function test_transfer_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.transfer(payable(ETH_WHALE), ETH_AMOUNT);
  }

  function test_transfer_RevertIfToZeroAddress() public {
    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.transfer(payable(address(0)), ETH_AMOUNT);
    vm.stopPrank();
  }

  // transfer ERC20 unit tests
  function test_transferERC20_TransferUSDC() public {
    _transferUSDCToAccount(USDC_AMOUNT);

    uint256 accountUSDCBalance = USDC.balanceOf(account1Addr);
    uint256 whaleUSDCBalance = USDC.balanceOf(USDC_WHALE);

    // Transfer USDC from account to whale
    vm.startPrank(address(core));
    account1.transferERC20(ERC20Data(USDC, USDC_WHALE, USDC_AMOUNT));
    assertEq(USDC.balanceOf(account1Addr), 0);
    assertEq(USDC.balanceOf(account1Addr), accountUSDCBalance - USDC_AMOUNT);
    assertEq(USDC.balanceOf(USDC_WHALE), whaleUSDCBalance + USDC_AMOUNT);
    vm.stopPrank();
  }

  function test_transferERC20_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.transferERC20(ERC20Data(USDC, USDC_WHALE, USDC_AMOUNT));
  }

  function test_transferERC20_RevertIfToZeroAddress() public {
    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.transferERC20(ERC20Data(USDC, address(0), USDC_AMOUNT));
    vm.stopPrank();
  }

  // batch transfer ERC20 unit tests
  function test_batchTransferERC20_TransferUSDCAndUNI() public {
    _transferUSDCToAccount(USDC_AMOUNT);
    _transferUNIToAccount(UNI_AMOUNT);

    uint256 accountUSDCBalance = USDC.balanceOf(account1Addr);
    uint256 accountUNIBalance = UNI.balanceOf(account1Addr);
    uint256 whaleUSDCBalance = USDC.balanceOf(USDC_WHALE);
    uint256 whaleUSDTBalance = UNI.balanceOf(UNI_WHALE);

    ERC20Data[] memory erc20Data = new ERC20Data[](2);
    erc20Data[0] = ERC20Data(USDC, USDC_WHALE, USDC_AMOUNT);
    erc20Data[1] = ERC20Data(UNI, UNI_WHALE, UNI_AMOUNT);

    // Transfer USDC and USDT from account to whale
    vm.startPrank(address(core));
    account1.batchTransferERC20(erc20Data);
    assertEq(USDC.balanceOf(account1Addr), 0);
    assertEq(UNI.balanceOf(account1Addr), 0);
    assertEq(USDC.balanceOf(account1Addr), accountUSDCBalance - USDC_AMOUNT);
    assertEq(UNI.balanceOf(account1Addr), accountUNIBalance - UNI_AMOUNT);
    assertEq(USDC.balanceOf(USDC_WHALE), whaleUSDCBalance + USDC_AMOUNT);
    assertEq(UNI.balanceOf(UNI_WHALE), whaleUSDTBalance + UNI_AMOUNT);
    vm.stopPrank();
  }

  function test_batchTransferERC20_RevertIfNotVertexMsgSender() public {
    ERC20Data[] memory erc20Data = new ERC20Data[](2);

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchTransferERC20(erc20Data);
  }

  function test_batchTransferERC20_RevertIfToZeroAddress() public {
    ERC20Data[] memory erc20Data = new ERC20Data[](1);
    erc20Data[0] = ERC20Data(USDC, address(0), USDC_AMOUNT);

    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.batchTransferERC20(erc20Data);
    vm.stopPrank();
  }

  // approve ERC20 unit tests
  function test_approveERC20_ApproveUSDC() public {
    _approveUSDCToRecipient(USDC_AMOUNT);
  }

  function test_approveERC20_IncreaseUSDCAllowance() public {
    _approveUSDCToRecipient(USDC_AMOUNT);
    _approveUSDCToRecipient(0);
    _approveUSDCToRecipient(USDC_AMOUNT + 1);
  }

  function test_approveERC20_DecreaseUSDCAllowance() public {
    _approveUSDCToRecipient(USDC_AMOUNT);
    _approveUSDCToRecipient(0);
    _approveUSDCToRecipient(USDC_AMOUNT - 1);
  }

  function test_approveERC20_IncreaseUSDTAllowance() public {
    _approveUSDTToRecipient(USDT_AMOUNT);
    _approveUSDTToRecipient(0);
    _approveUSDTToRecipient(USDT_AMOUNT + 1);
  }

  function test_approveERC20_DecreaseUSDTAllowance() public {
    _approveUSDTToRecipient(USDT_AMOUNT);
    _approveUSDTToRecipient(0);
    _approveUSDTToRecipient(USDT_AMOUNT - 1);
  }

  function test_approveERC20_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.approveERC20(ERC20Data(USDC, USDC_WHALE, USDC_AMOUNT));
  }

  // batch approve ERC20 unit tests
  function test_batchApproveERC20_ApproveUSDCAndUNI() public {
    ERC20Data[] memory erc20Data = new ERC20Data[](2);
    erc20Data[0] = ERC20Data(USDC, USDC_WHALE, USDC_AMOUNT);
    erc20Data[1] = ERC20Data(UNI, UNI_WHALE, UNI_AMOUNT);

    // Approve USDC and UNI to whale
    vm.startPrank(address(core));
    account1.batchApproveERC20(erc20Data);
    assertEq(USDC.allowance(account1Addr, USDC_WHALE), USDC_AMOUNT);
    assertEq(UNI.allowance(account1Addr, UNI_WHALE), UNI_AMOUNT);
    vm.stopPrank();
  }

  function test_batchApproveERC20_RevertIfNotVertexMsgSender() public {
    ERC20Data[] memory erc20Data = new ERC20Data[](2);

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchApproveERC20(erc20Data);
  }

  // transfer ERC721 unit tests
  function test_transferERC721_TransferBAYC() public {
    _transferBAYCToAccount(BAYC_ID);

    uint256 accountNFTBalance = BAYC.balanceOf(account1Addr);
    uint256 whaleNFTBalance = BAYC.balanceOf(BAYC_WHALE);

    // Transfer NFT from account to whale
    vm.startPrank(address(core));
    account1.transferERC721(ERC721Data(BAYC, BAYC_WHALE, BAYC_ID));
    assertEq(BAYC.balanceOf(account1Addr), 0);
    assertEq(BAYC.balanceOf(account1Addr), accountNFTBalance - 1);
    assertEq(BAYC.balanceOf(BAYC_WHALE), whaleNFTBalance + 1);
    assertEq(BAYC.ownerOf(BAYC_ID), BAYC_WHALE);
    vm.stopPrank();
  }

  function test_transferERC721_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.transferERC721(ERC721Data(BAYC, BAYC_WHALE, BAYC_ID));
  }

  function test_transferERC721_RevertIfToZeroAddress() public {
    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.transferERC721(ERC721Data(BAYC, address(0), BAYC_ID));
    vm.stopPrank();
  }

  // batch transfer ERC721 unit tests
  function test_batchTransferERC721_TransferBAYCAndNOUNS() public {
    _transferBAYCToAccount(BAYC_ID);
    _transferNOUNSToAccount(NOUNS_ID);

    uint256 accountBAYCBalance = BAYC.balanceOf(account1Addr);
    uint256 whaleBAYCBalance = BAYC.balanceOf(BAYC_WHALE);
    uint256 accountNOUNSBalance = NOUNS.balanceOf(account1Addr);
    uint256 whaleNOUNSBalance = NOUNS.balanceOf(NOUNS_WHALE);

    ERC721Data[] memory erc721Data = new ERC721Data[](2);
    erc721Data[0] = ERC721Data(BAYC, BAYC_WHALE, BAYC_ID);
    erc721Data[1] = ERC721Data(NOUNS, NOUNS_WHALE, NOUNS_ID);

    // Transfer NFTs from account to whale
    vm.startPrank(address(core));
    account1.batchTransferERC721(erc721Data);
    assertEq(BAYC.balanceOf(account1Addr), accountBAYCBalance - 1);
    assertEq(BAYC.balanceOf(BAYC_WHALE), whaleBAYCBalance + 1);
    assertEq(BAYC.ownerOf(BAYC_ID), BAYC_WHALE);
    assertEq(NOUNS.balanceOf(account1Addr), accountNOUNSBalance - 1);
    assertEq(NOUNS.balanceOf(NOUNS_WHALE), whaleNOUNSBalance + 1);
    assertEq(NOUNS.ownerOf(NOUNS_ID), NOUNS_WHALE);
    vm.stopPrank();
  }

  function test_batchTransferERC721_RevertIfNotVertexMsgSender() public {
    ERC721Data[] memory erc721Data = new ERC721Data[](2);

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchTransferERC721(erc721Data);
  }

  function test_batchTransferERC721_RevertIfToZeroAddress() public {
    ERC721Data[] memory erc721Data = new ERC721Data[](1);
    erc721Data[0] = ERC721Data(BAYC, address(0), BAYC_ID);

    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.batchTransferERC721(erc721Data);
    vm.stopPrank();
  }

  // approve ERC721 unit tests
  function test_approveERC721_ApproveBAYC() public {
    _transferBAYCToAccount(BAYC_ID);
    _approveBAYCToRecipient(BAYC_ID);
  }

  function test_approveERC721_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.approveERC721(ERC721Data(BAYC, BAYC_WHALE, BAYC_ID));
  }

  // batch approve ERC721 unit tests
  function test_batchApproveERC721_ApproveBAYCAndNOUNS() public {
    _transferBAYCToAccount(BAYC_ID);
    _transferNOUNSToAccount(NOUNS_ID);

    ERC721Data[] memory erc721Data = new ERC721Data[](2);
    erc721Data[0] = ERC721Data(BAYC, BAYC_WHALE, BAYC_ID);
    erc721Data[1] = ERC721Data(NOUNS, NOUNS_WHALE, NOUNS_ID);

    // Approve NFTs from account to whale
    vm.startPrank(address(core));
    account1.batchApproveERC721(erc721Data);
    assertEq(BAYC.getApproved(BAYC_ID), BAYC_WHALE);
    assertEq(NOUNS.getApproved(NOUNS_ID), NOUNS_WHALE);
    vm.stopPrank();
  }

  function test_batchApproveERC721_RevertIfNotVertexMsgSender() public {
    ERC721Data[] memory erc721Data = new ERC721Data[](2);

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchApproveERC721(erc721Data);
  }

  // approve operator ERC721 unit tests
  function test_approveOperatorERC721_ApproveBAYC() public {
    _approveOperatorBAYCToRecipient(true);
  }

  function test_approveOperatorERC721_DisapproveBAYC() public {
    _approveOperatorBAYCToRecipient(false);
  }

  function test_approveOperatorERC721_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.approveOperatorERC721(ERC721OperatorData(BAYC, BAYC_WHALE, true));
  }

  // batch approve operator ERC721 unit tests
  function test_batchApproveOperatorERC721_ApproveBAYCAndNOUNS() public {
    ERC721OperatorData[] memory erc721OperatorData = new ERC721OperatorData[](2);
    erc721OperatorData[0] = ERC721OperatorData(BAYC, BAYC_WHALE, true);
    erc721OperatorData[1] = ERC721OperatorData(NOUNS, NOUNS_WHALE, true);

    // Approve NFTs from account to whale
    vm.startPrank(address(core));
    account1.batchApproveOperatorERC721(erc721OperatorData);
    assertEq(BAYC.isApprovedForAll(account1Addr, BAYC_WHALE), true);
    assertEq(NOUNS.isApprovedForAll(account1Addr, NOUNS_WHALE), true);
    vm.stopPrank();
  }

  function test_batchApproveOperatorERC721_RevertIfNotVertexMsgSender() public {
    ERC721OperatorData[] memory erc721OperatorData = new ERC721OperatorData[](2);

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchApproveOperatorERC721(erc721OperatorData);
  }

  // transfer ERC1155 unit tests
  function test_transferERC1155_TransferRARI() public {
    _transferRARIToAccount(RARI_ID_1, RARI_ID_1_AMOUNT);

    uint256 accountNFTBalance = RARI.balanceOf(account1Addr, RARI_ID_1);
    uint256 whaleNFTBalance = RARI.balanceOf(RARI_WHALE, RARI_ID_1);

    // Transfer NFT from account to whale
    vm.startPrank(address(core));
    account1.transferERC1155(ERC1155Data(RARI, RARI_WHALE, RARI_ID_1, RARI_ID_1_AMOUNT, ""));
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), 0);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), accountNFTBalance - RARI_ID_1_AMOUNT);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_1), whaleNFTBalance + RARI_ID_1_AMOUNT);
    vm.stopPrank();
  }

  function test_transferERC1155_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.transferERC1155(ERC1155Data(RARI, RARI_WHALE, RARI_ID_1, RARI_ID_1_AMOUNT, ""));
  }

  function test_transferERC1155_RevertIfToZeroAddress() public {
    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.transferERC1155(ERC1155Data(RARI, address(0), RARI_ID_1, RARI_ID_1_AMOUNT, ""));
    vm.stopPrank();
  }

  // batch transfer single ERC1155 unit tests
  function test_batchTransferSingleERC1155_TransferRARI() public {
    _transferRARIToAccount(RARI_ID_1, RARI_ID_1_AMOUNT);
    _transferRARIToAccount(RARI_ID_2, RARI_ID_2_AMOUNT);

    uint256 accountNFTBalance1 = RARI.balanceOf(account1Addr, RARI_ID_1);
    uint256 whaleNFTBalance1 = RARI.balanceOf(RARI_WHALE, RARI_ID_1);
    uint256 accountNFTBalance2 = RARI.balanceOf(account1Addr, RARI_ID_2);
    uint256 whaleNFTBalance2 = RARI.balanceOf(RARI_WHALE, RARI_ID_2);

    uint256[] memory tokenIDs = new uint256[](2);
    tokenIDs[0] = RARI_ID_1;
    tokenIDs[1] = RARI_ID_2;

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = RARI_ID_1_AMOUNT;
    amounts[1] = RARI_ID_2_AMOUNT;

    // Transfer NFT from account to whale
    vm.startPrank(address(core));
    account1.batchTransferSingleERC1155(ERC1155BatchData(RARI, RARI_WHALE, tokenIDs, amounts, ""));
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), 0);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), accountNFTBalance1 - RARI_ID_1_AMOUNT);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_1), whaleNFTBalance1 + RARI_ID_1_AMOUNT);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_2), 0);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_2), accountNFTBalance2 - RARI_ID_2_AMOUNT);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_2), whaleNFTBalance2 + RARI_ID_2_AMOUNT);
    vm.stopPrank();
  }

  function test_batchTransferSingleERC1155_RevertIfNotVertexMsgSender() public {
    uint256[] memory tokenIDs = new uint256[](2);
    tokenIDs[0] = RARI_ID_1;
    tokenIDs[1] = RARI_ID_2;

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = RARI_ID_1_AMOUNT;
    amounts[1] = RARI_ID_2_AMOUNT;

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchTransferSingleERC1155(ERC1155BatchData(RARI, RARI_WHALE, tokenIDs, amounts, ""));
  }

  function test_batchTransferSingleERC1155_RevertIfToZeroAddress() public {
    uint256[] memory tokenIDs = new uint256[](2);
    tokenIDs[0] = RARI_ID_1;
    tokenIDs[1] = RARI_ID_2;

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = RARI_ID_1_AMOUNT;
    amounts[1] = RARI_ID_2_AMOUNT;

    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.batchTransferSingleERC1155(ERC1155BatchData(RARI, address(0), tokenIDs, amounts, ""));
    vm.stopPrank();
  }

  // batch transfer multiple ERC1155 unit tests
  function test_batchTransferMultipleERC1155_TransferRARIAndOPENSTORE() public {
    _transferRARIToAccount(RARI_ID_1, RARI_ID_1_AMOUNT);
    _transferRARIToAccount(RARI_ID_2, RARI_ID_2_AMOUNT);
    _transferOPENSTOREToAccount(OPENSTORE_ID_1, OPENSTORE_ID_1_AMOUNT);
    _transferOPENSTOREToAccount(OPENSTORE_ID_2, OPENSTORE_ID_2_AMOUNT);

    uint256 whaleRARIBalance1 = RARI.balanceOf(RARI_WHALE, RARI_ID_1);
    uint256 whaleRARIBalance2 = RARI.balanceOf(RARI_WHALE, RARI_ID_2);
    uint256 whaleOPENSTOREBalance1 = OPENSTORE.balanceOf(OPENSTORE_WHALE, OPENSTORE_ID_1);
    uint256 whaleOPENSTOREBalance2 = OPENSTORE.balanceOf(OPENSTORE_WHALE, OPENSTORE_ID_2);

    uint256[] memory tokenIDs1 = new uint256[](2);
    tokenIDs1[0] = RARI_ID_1;
    tokenIDs1[1] = RARI_ID_2;

    uint256[] memory tokenIDs2 = new uint256[](2);
    tokenIDs2[0] = OPENSTORE_ID_1;
    tokenIDs2[1] = OPENSTORE_ID_2;

    uint256[] memory amounts1 = new uint256[](2);
    amounts1[0] = RARI_ID_1_AMOUNT;
    amounts1[1] = RARI_ID_2_AMOUNT;

    uint256[] memory amounts2 = new uint256[](2);
    amounts2[0] = OPENSTORE_ID_1_AMOUNT;
    amounts2[1] = OPENSTORE_ID_2_AMOUNT;

    ERC1155BatchData[] memory erc1155BatchData = new ERC1155BatchData[](2);
    erc1155BatchData[0] = ERC1155BatchData(RARI, RARI_WHALE, tokenIDs1, amounts1, "");
    erc1155BatchData[1] = ERC1155BatchData(OPENSTORE, OPENSTORE_WHALE, tokenIDs2, amounts2, "");

    // Transfer NFT from account to whale
    vm.startPrank(address(core));
    account1.batchTransferMultipleERC1155(erc1155BatchData);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), 0);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_1), whaleRARIBalance1 + RARI_ID_1_AMOUNT);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_2), 0);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_2), whaleRARIBalance2 + RARI_ID_2_AMOUNT);
    assertEq(OPENSTORE.balanceOf(account1Addr, OPENSTORE_ID_1), 0);
    assertEq(OPENSTORE.balanceOf(OPENSTORE_WHALE, OPENSTORE_ID_1), whaleOPENSTOREBalance1 + OPENSTORE_ID_1_AMOUNT);
    assertEq(OPENSTORE.balanceOf(account1Addr, OPENSTORE_ID_2), 0);
    assertEq(OPENSTORE.balanceOf(OPENSTORE_WHALE, OPENSTORE_ID_2), whaleOPENSTOREBalance2 + OPENSTORE_ID_2_AMOUNT);
    vm.stopPrank();
  }

  function test_batchTransferMultipleERC1155_RevertIfNotVertexMsgSender() public {
    ERC1155BatchData[] memory erc1155BatchData = new ERC1155BatchData[](2);
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchTransferMultipleERC1155(erc1155BatchData);
  }

  function test_batchTransferMultipleERC1155_RevertIfToZeroAddress() public {
    uint256[] memory tokenIDs = new uint256[](1);
    uint256[] memory amounts = new uint256[](1);
    ERC1155BatchData[] memory erc1155BatchData = new ERC1155BatchData[](1);
    erc1155BatchData[0] = ERC1155BatchData(RARI, address(0), tokenIDs, amounts, "");

    vm.startPrank(address(core));
    vm.expectRevert(VertexAccount.Invalid0xRecipient.selector);
    account1.batchTransferMultipleERC1155(erc1155BatchData);
    vm.stopPrank();
  }

  // approve operator ERC1155 unit tests
  function test_approveOperatorERC1155_ApproveRARI() public {
    _approveRARIToRecipient(true);
  }

  function test_approveOperatorERC1155_DisapproveRARI() public {
    _approveRARIToRecipient(false);
  }

  function test_approveOperatorERC1155_RevertIfNotVertexMsgSender() public {
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.approveOperatorERC1155(ERC1155OperatorData(RARI, RARI_WHALE, true));
  }

  // batch approve operator ERC1155 unit tests
  function test_batchApproveOperatorERC1155_ApproveRARIAndOPENSTORE() public {
    ERC1155OperatorData[] memory erc1155OperatorData = new ERC1155OperatorData[](2);
    erc1155OperatorData[0] = ERC1155OperatorData(RARI, RARI_WHALE, true);
    erc1155OperatorData[1] = ERC1155OperatorData(OPENSTORE, OPENSTORE_WHALE, true);

    vm.startPrank(address(core));
    account1.batchApproveOperatorERC1155(erc1155OperatorData);
    assertEq(RARI.isApprovedForAll(account1Addr, RARI_WHALE), true);
    assertEq(OPENSTORE.isApprovedForAll(account1Addr, OPENSTORE_WHALE), true);
    vm.stopPrank();
  }

  function test_batchApproveOperatorERC1155_RevertIfNotVertexMsgSender() public {
    ERC1155OperatorData[] memory erc1155OperatorData = new ERC1155OperatorData[](2);
    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.batchApproveOperatorERC1155(erc1155OperatorData);
  }

  // generic execute unit tests
  function test_execute_CallCryptoPunk() public {
    // Transfer Punk to Account to have it stuck in the Vertex Account
    _transferPUNKToAccount(PUNK_ID);

    uint256 accountNFTBalance = PUNK.balanceOf(account1Addr);
    uint256 whaleNFTBalance = PUNK.balanceOf(PUNK_WHALE);

    // Rescue Punk by calling execute call
    vm.startPrank(address(core));
    account1.execute(
      address(PUNK), abi.encodeWithSelector(ICryptoPunk.transferPunk.selector, PUNK_WHALE, PUNK_ID), false
    );
    assertEq(PUNK.balanceOf(account1Addr), 0);
    assertEq(PUNK.balanceOf(account1Addr), accountNFTBalance - 1);
    assertEq(PUNK.balanceOf(PUNK_WHALE), whaleNFTBalance + 1);
    assertEq(PUNK.punkIndexToAddress(PUNK_ID), PUNK_WHALE);
    vm.stopPrank();
  }

  function test_execute_DelegateCallTestScript() public {
    TestScript testScript = new TestScript();

    vm.startPrank(address(core));
    bytes memory result =
      account1.execute(address(testScript), abi.encodePacked(TestScript.testFunction.selector, ""), true);
    assertEq(10, uint256(bytes32(result)));
    vm.stopPrank();
  }

  function test_execute_RevertIfNotVertexMsgSender() public {
    TestScript testScript = new TestScript();

    vm.expectRevert(VertexAccount.OnlyVertex.selector);
    account1.execute(address(testScript), abi.encodePacked(TestScript.testFunction.selector, ""), true);
  }

  function test_execute_RevertIfNotSuccess() public {
    TestScript testScript = new TestScript();

    vm.startPrank(address(core));
    vm.expectRevert(abi.encodeWithSelector(VertexAccount.FailedExecution.selector, ""));
    account1.execute(address(testScript), abi.encodePacked("", ""), true);
    vm.stopPrank();
  }

  /*///////////////////////////////////////////////////////////////
                            Integration tests
    //////////////////////////////////////////////////////////////*/

  // Test that VertexAccount can receive ETH
  function test_ReceiveETH() public {
    _transferETHToAccount(ETH_AMOUNT);
  }

  // Test that VertexAccount can receive ERC20 tokens
  function test_ReceiveERC20() public {
    _transferUSDCToAccount(USDC_AMOUNT);
  }

  // Test that approved ERC20 tokens can be transferred from VertexAccount to a recipient
  function test_TransferApprovedERC20() public {
    _transferUSDCToAccount(USDC_AMOUNT);
    _approveUSDCToRecipient(USDC_AMOUNT);

    uint256 accountUSDCBalance = USDC.balanceOf(account1Addr);
    uint256 whaleUSDCBalance = USDC.balanceOf(USDC_WHALE);

    // Transfer USDC from account to whale
    vm.startPrank(USDC_WHALE);
    USDC.transferFrom(account1Addr, USDC_WHALE, USDC_AMOUNT);
    assertEq(USDC.balanceOf(account1Addr), 0);
    assertEq(USDC.balanceOf(account1Addr), accountUSDCBalance - USDC_AMOUNT);
    assertEq(USDC.balanceOf(USDC_WHALE), whaleUSDCBalance + USDC_AMOUNT);
    vm.stopPrank();
  }

  // Test that VertexAccount can receive ERC721 tokens
  function test_ReceiveERC721() public {
    _transferBAYCToAccount(BAYC_ID);
  }

  // Test that VertexAccount can safe receive ERC721 tokens
  function test_SafeReceiveERC721() public {
    assertEq(BAYC.balanceOf(account1Addr), 0);
    assertEq(BAYC.ownerOf(BAYC_ID), BAYC_WHALE);

    vm.startPrank(BAYC_WHALE);
    BAYC.safeTransferFrom(BAYC_WHALE, account1Addr, BAYC_ID);
    assertEq(BAYC.balanceOf(account1Addr), 1);
    assertEq(BAYC.ownerOf(BAYC_ID), account1Addr);
    vm.stopPrank();
  }

  // Test that approved ERC721 tokens can be transferred from VertexAccount to a recipient
  function test_TransferApprovedERC721() public {
    _transferBAYCToAccount(BAYC_ID);
    _approveBAYCToRecipient(BAYC_ID);

    uint256 accountNFTBalance = BAYC.balanceOf(account1Addr);
    uint256 whaleNFTBalance = BAYC.balanceOf(BAYC_WHALE);

    // Transfer NFT from account to whale
    vm.startPrank(BAYC_WHALE);
    BAYC.transferFrom(account1Addr, BAYC_WHALE, BAYC_ID);
    assertEq(BAYC.balanceOf(account1Addr), 0);
    assertEq(BAYC.balanceOf(account1Addr), accountNFTBalance - 1);
    assertEq(BAYC.balanceOf(BAYC_WHALE), whaleNFTBalance + 1);
    assertEq(BAYC.ownerOf(BAYC_ID), BAYC_WHALE);
    vm.stopPrank();
  }

  // Test that approved Operator ERC721 tokens can be transferred from VertexAccount to a recipient
  function test_TransferApprovedOperatorERC721() public {
    vm.startPrank(BAYC_WHALE);
    BAYC.transferFrom(BAYC_WHALE, account1Addr, BAYC_ID);
    BAYC.transferFrom(BAYC_WHALE, account1Addr, BAYC_ID_2);
    vm.stopPrank();
    _approveOperatorBAYCToRecipient(true);

    uint256 accountNFTBalance = BAYC.balanceOf(account1Addr);
    uint256 whaleNFTBalance = BAYC.balanceOf(BAYC_WHALE);

    // Transfer NFT from account to whale
    vm.startPrank(BAYC_WHALE);
    BAYC.transferFrom(account1Addr, BAYC_WHALE, BAYC_ID);
    BAYC.transferFrom(account1Addr, BAYC_WHALE, BAYC_ID_2);
    assertEq(BAYC.balanceOf(account1Addr), 0);
    assertEq(BAYC.balanceOf(account1Addr), accountNFTBalance - 2);
    assertEq(BAYC.balanceOf(BAYC_WHALE), whaleNFTBalance + 2);
    assertEq(BAYC.ownerOf(BAYC_ID), BAYC_WHALE);
    assertEq(BAYC.ownerOf(BAYC_ID_2), BAYC_WHALE);
    vm.stopPrank();
  }

  // Test that VertexAccount can receive ERC1155 tokens
  function test_ReceiveERC1155() public {
    _transferRARIToAccount(RARI_ID_1, RARI_ID_1_AMOUNT);
  }

  // Test that approved ERC1155 tokens can be transferred from VertexAccount to a recipient
  function test_TransferApprovedERC1155() public {
    _transferRARIToAccount(RARI_ID_1, RARI_ID_1_AMOUNT);
    _transferRARIToAccount(RARI_ID_2, RARI_ID_2_AMOUNT);
    _approveRARIToRecipient(true);

    uint256 accountNFTBalance1 = RARI.balanceOf(account1Addr, RARI_ID_1);
    uint256 whaleNFTBalance1 = RARI.balanceOf(RARI_WHALE, RARI_ID_1);
    uint256 accountNFTBalance2 = RARI.balanceOf(account1Addr, RARI_ID_2);
    uint256 whaleNFTBalance2 = RARI.balanceOf(RARI_WHALE, RARI_ID_2);

    uint256[] memory tokenIDs = new uint256[](2);
    tokenIDs[0] = RARI_ID_1;
    tokenIDs[1] = RARI_ID_2;

    uint256[] memory amounts = new uint256[](2);
    amounts[0] = RARI_ID_1_AMOUNT;
    amounts[1] = RARI_ID_2_AMOUNT;

    // Transfer NFT from account to whale
    vm.startPrank(address(RARI_WHALE));
    RARI.safeBatchTransferFrom(account1Addr, RARI_WHALE, tokenIDs, amounts, "");
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), 0);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_1), accountNFTBalance1 - RARI_ID_1_AMOUNT);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_1), whaleNFTBalance1 + RARI_ID_1_AMOUNT);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_2), 0);
    assertEq(RARI.balanceOf(account1Addr, RARI_ID_2), accountNFTBalance2 - RARI_ID_2_AMOUNT);
    assertEq(RARI.balanceOf(RARI_WHALE, RARI_ID_2), whaleNFTBalance2 + RARI_ID_2_AMOUNT);
    vm.stopPrank();
  }

  /*///////////////////////////////////////////////////////////////
                            Helpers
    //////////////////////////////////////////////////////////////*/

  function _transferETHToAccount(uint256 amount) public {
    assertEq(account1Addr.balance, 0);

    vm.startPrank(ETH_WHALE);
    (bool success,) = account1Addr.call{value: amount}("");
    assertTrue(success);
    assertEq(account1Addr.balance, amount);
    vm.stopPrank();
  }

  function _transferUSDCToAccount(uint256 amount) public {
    assertEq(USDC.balanceOf(account1Addr), 0);

    vm.startPrank(USDC_WHALE);
    USDC.transfer(account1Addr, amount);
    assertEq(USDC.balanceOf(account1Addr), amount);
    vm.stopPrank();
  }

  function _approveUSDCToRecipient(uint256 amount) public {
    vm.startPrank(address(core));
    account1.approveERC20(ERC20Data(USDC, USDC_WHALE, amount));
    assertEq(USDC.allowance(account1Addr, USDC_WHALE), amount);
    vm.stopPrank();
  }

  function _approveUSDTToRecipient(uint256 amount) public {
    vm.startPrank(address(core));
    account1.approveERC20(ERC20Data(USDT, USDT_WHALE, amount));
    assertEq(USDT.allowance(account1Addr, USDT_WHALE), amount);
    vm.stopPrank();
  }

  function _transferUNIToAccount(uint256 amount) public {
    assertEq(UNI.balanceOf(account1Addr), 0);

    vm.startPrank(UNI_WHALE);
    UNI.transfer(account1Addr, amount);
    assertEq(UNI.balanceOf(account1Addr), amount);
    vm.stopPrank();
  }

  function _transferBAYCToAccount(uint256 id) public {
    assertEq(BAYC.balanceOf(account1Addr), 0);
    assertEq(BAYC.ownerOf(id), BAYC_WHALE);

    vm.startPrank(BAYC_WHALE);
    BAYC.transferFrom(BAYC_WHALE, account1Addr, id);
    assertEq(BAYC.balanceOf(account1Addr), 1);
    assertEq(BAYC.ownerOf(id), account1Addr);
    vm.stopPrank();
  }

  function _approveBAYCToRecipient(uint256 id) public {
    vm.startPrank(address(core));
    account1.approveERC721(ERC721Data(BAYC, BAYC_WHALE, id));
    assertEq(BAYC.getApproved(id), BAYC_WHALE);
    vm.stopPrank();
  }

  function _approveOperatorBAYCToRecipient(bool approved) public {
    vm.startPrank(address(core));
    account1.approveOperatorERC721(ERC721OperatorData(BAYC, BAYC_WHALE, approved));
    assertEq(BAYC.isApprovedForAll(account1Addr, BAYC_WHALE), approved);
    vm.stopPrank();
  }

  function _transferNOUNSToAccount(uint256 id) public {
    assertEq(NOUNS.balanceOf(account1Addr), 0);
    assertEq(NOUNS.ownerOf(id), NOUNS_WHALE);

    vm.startPrank(NOUNS_WHALE);
    NOUNS.transferFrom(NOUNS_WHALE, account1Addr, id);
    assertEq(NOUNS.balanceOf(account1Addr), 1);
    assertEq(NOUNS.ownerOf(id), account1Addr);
    vm.stopPrank();
  }

  function _transferPUNKToAccount(uint256 id) public {
    assertEq(PUNK.balanceOf(account1Addr), 0);
    assertEq(PUNK.punkIndexToAddress(id), PUNK_WHALE);

    vm.startPrank(PUNK_WHALE);
    PUNK.transferPunk(account1Addr, id);
    assertEq(PUNK.balanceOf(account1Addr), 1);
    assertEq(PUNK.punkIndexToAddress(id), account1Addr);
    vm.stopPrank();
  }

  function _transferRARIToAccount(uint256 id, uint256 amount) public {
    assertEq(RARI.balanceOf(account1Addr, id), 0);

    vm.startPrank(RARI_WHALE);
    RARI.safeTransferFrom(RARI_WHALE, account1Addr, id, amount, "");
    assertEq(RARI.balanceOf(account1Addr, id), amount);
    vm.stopPrank();
  }

  function _transferOPENSTOREToAccount(uint256 id, uint256 amount) public {
    assertEq(OPENSTORE.balanceOf(account1Addr, id), 0);

    vm.startPrank(OPENSTORE_WHALE);
    OPENSTORE.safeTransferFrom(OPENSTORE_WHALE, account1Addr, id, amount, "");
    assertEq(OPENSTORE.balanceOf(account1Addr, id), amount);
    vm.stopPrank();
  }

  function _approveRARIToRecipient(bool approved) public {
    vm.startPrank(address(core));
    account1.approveOperatorERC1155(ERC1155OperatorData(RARI, RARI_WHALE, approved));
    assertEq(RARI.isApprovedForAll(account1Addr, RARI_WHALE), approved);
    vm.stopPrank();
  }
}