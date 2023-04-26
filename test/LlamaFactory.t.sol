// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";

import {Solarray} from "@solarray/Solarray.sol";

import {SolarrayLlama} from "test/utils/SolarrayLlama.sol";
import {LlamaTestSetup} from "test/utils/LlamaTestSetup.sol";

import {ILlamaStrategy} from "src/interfaces/ILlamaStrategy.sol";
import {Action, RoleHolderData, RolePermissionData, RelativeStrategyConfig, PermissionData} from "src/lib/Structs.sol";
import {RoleDescription} from "src/lib/UDVTs.sol";
import {LlamaAccount} from "src/LlamaAccount.sol";
import {LlamaCore} from "src/LlamaCore.sol";
import {LlamaFactory} from "src/LlamaFactory.sol";
import {LlamaPolicy} from "src/LlamaPolicy.sol";
import {LlamaPolicyTokenURI} from "src/LlamaPolicyTokenURI.sol";

contract LlamaFactoryTest is LlamaTestSetup {
  uint128 constant DEFAULT_QUANTITY = 1;

  event LlamaInstanceCreated(
    uint256 indexed id, string indexed name, address llamaCore, address llamaPolicy, uint256 chainId
  );
  event StrategyAuthorized(ILlamaStrategy indexed strategy, address indexed strategyLogic, bytes initializationData);
  event AccountAuthorized(LlamaAccount indexed account, address indexed accountLogic, string name);
  event PolicyTokenURISet(LlamaPolicyTokenURI indexed llamaPolicyTokenURI);

  event ActionCreated(
    uint256 id,
    address indexed creator,
    ILlamaStrategy indexed strategy,
    address target,
    uint256 value,
    bytes4 selector,
    bytes data
  );
  event ActionCanceled(uint256 id);
  event ActionQueued(
    uint256 id, address indexed caller, ILlamaStrategy indexed strategy, address indexed creator, uint256 executionTime
  );
  event ApprovalCast(uint256 id, address indexed policyholder, uint256 quantity, string reason);
  event DisapprovalCast(uint256 id, address indexed policyholder, uint256 quantity, string reason);
  event StrategiesAuthorized(RelativeStrategyConfig[] strategies);
  event StrategiesUnauthorized(ILlamaStrategy[] strategies);
  event StrategyLogicAuthorized(ILlamaStrategy indexed relativeStrategyLogic);
  event AccountLogicAuthorized(LlamaAccount indexed accountLogic);
}

contract Constructor is LlamaFactoryTest {
  function deployLlamaFactory() internal returns (LlamaFactory) {
    bytes[] memory strategyConfigs = relativeStrategyConfigs();
    string[] memory accounts = Solarray.strings("Account 1", "Account 2", "Account 3");

    RoleDescription[] memory roleDescriptionStrings = SolarrayLlama.roleDescription(
      "AllHolders", "ActionCreator", "Approver", "Disapprover", "TestRole1", "TestRole2", "MadeUpRole"
    );
    RoleHolderData[] memory roleHolders = defaultActionCreatorRoleHolder(actionCreatorAaron);
    return new LlamaFactory(
      coreLogic,
      relativeStrategyLogic,
      accountLogic,
      policyLogic,
      policyTokenURI,
      "Root Llama",
      strategyConfigs,
      accounts,
      roleDescriptionStrings,
      roleHolders,
      new RolePermissionData[](0)
    );
  }

  function test_SetsLlamaCoreLogicAddress() public {
    assertEq(address(factory.LLAMA_CORE_LOGIC()), address(coreLogic));
  }

  function test_SetsLlamaPolicyLogicAddress() public {
    assertEq(address(factory.LLAMA_POLICY_LOGIC()), address(policyLogic));
  }

  function test_SetsLlamaAccountLogicAddress() public {
    assertEq(address(factory.LLAMA_ACCOUNT_LOGIC()), address(accountLogic));
  }

  function test_SetsLlamaPolicyTokenURIAddress() public {
    assertEq(address(factory.llamaPolicyTokenURI()), address(policyTokenURI));
  }

  function test_EmitsPolicyTokenURIUpdatedEvent() public {
    vm.expectEmit();
    emit PolicyTokenURISet(policyTokenURI);
    deployLlamaFactory();
  }

  function test_SetsLlamaStrategyLogicAddress() public {
    assertTrue(factory.authorizedStrategyLogics(relativeStrategyLogic));
  }

  function test_EmitsStrategyLogicAuthorizedEvent() public {
    vm.expectEmit();
    emit StrategyLogicAuthorized(relativeStrategyLogic);
    deployLlamaFactory();
  }

  function test_SetsRootLlamaAddress() public {
    assertEq(address(factory.ROOT_LLAMA()), address(rootCore));
  }

  function test_DeploysRootLlamaViaInternalDeployMethod() public {
    // The internal `_deploy` method is tested in the `Deploy` contract, so here we just check
    // one side effect of that method as a sanity check it was called. If it was called, the
    // llama count should no longer be zero.
    assertEq(factory.llamaCount(), 2);
  }
}

contract Deploy is LlamaFactoryTest {
  function deployLlama() internal returns (LlamaCore) {
    bytes[] memory strategyConfigs = relativeStrategyConfigs();
    string[] memory accounts = Solarray.strings("Account1", "Account2");
    RoleDescription[] memory roleDescriptionStrings = SolarrayLlama.roleDescription(
      "AllHolders", "ActionCreator", "Approver", "Disapprover", "TestRole1", "TestRole2", "MadeUpRole"
    );
    RoleHolderData[] memory roleHolders = defaultActionCreatorRoleHolder(actionCreatorAaron);

    vm.prank(address(rootCore));
    return factory.deploy(
      "NewProject",
      relativeStrategyLogic,
      strategyConfigs,
      accounts,
      roleDescriptionStrings,
      roleHolders,
      new RolePermissionData[](0)
    );
  }

  function test_RevertIf_CallerIsNotRootLlama(address caller) public {
    vm.assume(caller != address(rootCore));
    bytes[] memory strategyConfigs = relativeStrategyConfigs();
    string[] memory accounts = Solarray.strings("Account1", "Account2");
    RoleHolderData[] memory roleHolders = defaultActionCreatorRoleHolder(actionCreatorAaron);

    vm.prank(address(caller));
    vm.expectRevert(LlamaFactory.OnlyRootLlama.selector);
    factory.deploy(
      "NewProject",
      relativeStrategyLogic,
      strategyConfigs,
      accounts,
      new RoleDescription[](0),
      roleHolders,
      new RolePermissionData[](0)
    );
  }

  function test_RevertIf_InstanceDeployedWithSameName(string memory name) public {
    bytes[] memory strategyConfigs = relativeStrategyConfigs();
    string[] memory accounts = Solarray.strings("Account1", "Account2");
    RoleDescription[] memory roleDescriptionStrings = SolarrayLlama.roleDescription(
      "AllHolders", "ActionCreator", "Approver", "Disapprover", "TestRole1", "TestRole2", "MadeUpRole"
    );
    RoleHolderData[] memory roleHolders = defaultActionCreatorRoleHolder(actionCreatorAaron);

    vm.prank(address(rootCore));
    factory.deploy(
      name,
      relativeStrategyLogic,
      strategyConfigs,
      accounts,
      roleDescriptionStrings,
      roleHolders,
      new RolePermissionData[](0)
    );

    vm.expectRevert();
    factory.deploy(
      name,
      relativeStrategyLogic,
      strategyConfigs,
      accounts,
      new RoleDescription[](0),
      roleHolders,
      new RolePermissionData[](0)
    );
  }

  function test_IncrementsLlamaCountByOne() public {
    uint256 initialLlamaCount = factory.llamaCount();
    deployLlama();
    assertEq(factory.llamaCount(), initialLlamaCount + 1);
  }

  function test_DeploysPolicy() public {
    LlamaPolicy _policy = lens.computeLlamaPolicyAddress("NewProject", address(policyLogic), address(factory));
    assertEq(address(_policy).code.length, 0);
    deployLlama();
    assertGt(address(_policy).code.length, 0);
  }

  function test_InitializesLlamaPolicy() public {
    LlamaPolicy _policy = lens.computeLlamaPolicyAddress("NewProject", address(policyLogic), address(factory));

    assertEq(address(_policy).code.length, 0);
    deployLlama();
    assertGt(address(_policy).code.length, 0);

    vm.expectRevert("Initializable: contract is already initialized");
    _policy.initialize("Test", new RoleDescription[](0), new RoleHolderData[](0), new RolePermissionData[](0));
  }

  function test_DeploysLlamaCore() public {
    LlamaCore _llama = lens.computeLlamaCoreAddress("NewProject", address(coreLogic), address(factory));
    assertEq(address(_llama).code.length, 0);
    deployLlama();
    assertGt(address(_llama).code.length, 0);
    assertGt(address(_llama.policy()).code.length, 0);
    LlamaCore(address(_llama)).name(); // Sanity check that this doesn't revert.
    LlamaCore(address(_llama.policy())).name(); // Sanity check that this doesn't revert.
  }

  function test_InitializesLlamaCore() public {
    LlamaCore _llama = deployLlama();
    assertEq(_llama.name(), "NewProject");

    bytes[] memory strategyConfigs = relativeStrategyConfigs();
    string[] memory accounts = Solarray.strings("Account1", "Account2");

    LlamaPolicy _policy = _llama.policy();
    vm.expectRevert("Initializable: contract is already initialized");
    _llama.initialize("NewProject", _policy, relativeStrategyLogic, accountLogic, strategyConfigs, accounts);
  }

  function test_SetsLlamaCoreOnThePolicy() public {
    LlamaCore _llama = deployLlama();
    LlamaPolicy _policy = _llama.policy();
    LlamaCore _llamaFromPolicy = LlamaCore(_policy.llamaCore());
    assertEq(address(_llamaFromPolicy), address(_llama));
  }

  function test_SetsPolicyAddressOnLlamaCore() public {
    LlamaPolicy computedPolicy = lens.computeLlamaPolicyAddress("NewProject", address(policyLogic), address(factory));
    LlamaCore _llama = deployLlama();
    assertEq(address(_llama.policy()), address(computedPolicy));
  }

  function test_SetsAccountLogicAddressOnLlamaCore() public {
    LlamaCore _llama = deployLlama();
    assertEq(address(_llama.llamaAccountLogic()), address(accountLogic));
  }

  function test_EmitsLlamaInstanceCreatedEvent() public {
    vm.expectEmit();
    LlamaCore computedLlama = lens.computeLlamaCoreAddress("NewProject", address(coreLogic), address(factory));
    LlamaPolicy computedPolicy = lens.computeLlamaPolicyAddress("NewProject", address(policyLogic), address(factory));
    emit LlamaInstanceCreated(2, "NewProject", address(computedLlama), address(computedPolicy), block.chainid);
    deployLlama();
  }

  function test_ReturnsAddressOfTheNewLlamaCoreContract() public {
    LlamaCore computedLlama = lens.computeLlamaCoreAddress("NewProject", address(coreLogic), address(factory));
    LlamaCore newLlama = deployLlama();
    assertEq(address(newLlama), address(computedLlama));
    assertEq(address(computedLlama), LlamaPolicy(computedLlama.policy()).llamaCore());
    assertEq(address(computedLlama), LlamaPolicy(newLlama.policy()).llamaCore());
  }
}

contract AuthorizeStrategyLogic is LlamaFactoryTest {
  function testFuzz_RevertIf_CallerIsNotRootLlama(address _caller) public {
    vm.assume(_caller != address(rootCore));
    vm.expectRevert(LlamaFactory.OnlyRootLlama.selector);
    vm.prank(_caller);
    factory.authorizeStrategyLogic(ILlamaStrategy(randomLogicAddress));
  }

  function test_SetsValueInStorageMappingToTrue() public {
    assertEq(factory.authorizedStrategyLogics(ILlamaStrategy(randomLogicAddress)), false);
    vm.prank(address(rootCore));
    factory.authorizeStrategyLogic(ILlamaStrategy(randomLogicAddress));
    assertEq(factory.authorizedStrategyLogics(ILlamaStrategy(randomLogicAddress)), true);
  }

  function test_EmitsStrategyLogicAuthorizedEvent() public {
    vm.prank(address(rootCore));
    vm.expectEmit();
    emit StrategyLogicAuthorized(ILlamaStrategy(randomLogicAddress));
    factory.authorizeStrategyLogic(ILlamaStrategy(randomLogicAddress));
  }
}

contract SetPolicyTokenURI is LlamaFactoryTest {
  function testFuzz_RevertIf_CallerIsNotRootLlama(address _caller, address _policyTokenURI) public {
    vm.assume(_caller != address(rootCore));
    vm.prank(address(_caller));
    vm.expectRevert(LlamaFactory.OnlyRootLlama.selector);
    factory.setPolicyTokenURI(LlamaPolicyTokenURI(_policyTokenURI));
  }

  function testFuzz_WritesMetadataAddressToStorage(address _policyTokenURI) public {
    vm.prank(address(rootCore));
    vm.expectEmit();
    emit PolicyTokenURISet(LlamaPolicyTokenURI(_policyTokenURI));
    factory.setPolicyTokenURI(LlamaPolicyTokenURI(_policyTokenURI));
    assertEq(address(factory.llamaPolicyTokenURI()), _policyTokenURI);
  }
}

contract TokenURI is LlamaFactoryTest {
  function setTokenURIMetadata() internal {
    string memory color = "#FF0000";
    string memory logo =
      '<path fill="#fff" fill-rule="evenodd" d="M344.211 459c7.666-3.026 13.093-10.52 13.093-19.284 0-11.441-9.246-20.716-20.652-20.716S316 428.275 316 439.716a20.711 20.711 0 0 0 9.38 17.36c.401-.714 1.144-1.193 1.993-1.193.188 0 .347-.173.3-.353a14.088 14.088 0 0 1-.457-3.58c0-7.456 5.752-13.501 12.848-13.501.487 0 .917-.324 1.08-.777l.041-.111c.334-.882-.223-2.13-1.153-2.341-4.755-1.082-8.528-4.915-9.714-9.825-.137-.564.506-.939.974-.587l18.747 14.067a.674.674 0 0 1 .254.657 12.485 12.485 0 0 0 .102 4.921.63.63 0 0 1-.247.666 5.913 5.913 0 0 1-6.062.332 1.145 1.145 0 0 0-.794-.116 1.016 1.016 0 0 0-.789.986v8.518a.658.658 0 0 1-.663.653h-1.069a.713.713 0 0 1-.694-.629c-.397-2.96-2.819-5.238-5.749-5.238-.186 0-.37.009-.551.028a.416.416 0 0 0-.372.42c0 .234.187.424.423.457 2.412.329 4.275 2.487 4.275 5.099 0 .344-.033.687-.097 1.025-.072.369.197.741.578.741h.541c.003 0 .007.001.01.004.002.003.004.006.004.01l.001.005.003.005.005.003.005.001h4.183a.17.17 0 0 1 .123.05c.124.118.244.24.362.364.248.266.349.64.39 1.163Zm-19.459-22.154c-.346-.272-.137-.788.306-.788h11.799c.443 0 .652.516.306.788a10.004 10.004 0 0 1-6.205 2.162c-2.329 0-4.478-.804-6.206-2.162Zm22.355 3.712c0 .645-.5 1.168-1.118 1.168-.617 0-1.117-.523-1.117-1.168 0-.646.5-1.168 1.117-1.168.618 0 1.118.523 1.118 1.168Z" clip-rule="evenodd"/>';
    vm.startPrank(address(rootCore));
    policyTokenURIParamRegistry.setColor(mpCore, color);
    policyTokenURIParamRegistry.setLogo(mpCore, logo);
    vm.stopPrank();
  }

  function testFuzz_ProxiesToMetadataContract(uint256 _tokenId) public {
    setTokenURIMetadata();

    (string memory _color, string memory _logo) = policyTokenURIParamRegistry.getMetadata(mpCore);
    assertEq(
      factory.tokenURI(mpCore, mpPolicy.name(), mpPolicy.symbol(), _tokenId),
      policyTokenURI.tokenURI(mpPolicy.name(), mpPolicy.symbol(), _tokenId, _color, _logo)
    );
  }
}