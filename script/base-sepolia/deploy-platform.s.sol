/*
forge script script/base-sepolia/deploy-platform.s.sol --rpc-url base-sepolia --sig "run(bool)" false
forge script script/base-sepolia/deploy-platform.s.sol --rpc-url base-sepolia --sig "run(bool)" true --broadcast --verify --etherscan-api-key ${BASE_ETHERSCAN_API_KEY}
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABMockRoyalty} from "src/royalty/ABMockRoyalty.sol";
import {ABKYCModule} from "src/utils/ABKYCModule.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";

contract DeployPlatform is Script {
    uint256 public constant DROP_ID_OFFSET = 30_000;

    string public constant VERIFIER_PATH = "deployment/84532/ABVerifier/address";
    string public constant DATA_REGISTRY_PATH = "deployment/84532/ABDataRegistry/address";
    string public constant FACTORY_PATH = "deployment/84532/AnotherCloneFactory/address";
    string public constant PROXY_ADMIN_PATH = "deployment/84532/ProxyAdmin/address";
    string public constant KYC_MODULE_PATH = "deployment/84532/ABKYCModule/address";

    ERC721ABLE public erc721Impl;
    ERC721ABOE public erc721OEImpl;
    ERC1155AB public erc1155Impl;
    ABMockRoyalty public royaltyImpl;
    ProxyAdmin public proxyAdmin;

    TransparentUpgradeableProxy public abKycModuleProxy;
    TransparentUpgradeableProxy public abVerifierProxy;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;

    function run(bool isBroadcasted) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address admin = BASE_GOERLI_MULTISIG;
        address admin = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        erc721Impl = new ERC721ABLE();
        erc721OEImpl = new ERC721ABOE();
        erc1155Impl = new ERC1155AB();
        royaltyImpl = new ABMockRoyalty();

        // Check if a Proxy Admin has already been deployed
        try vm.readFile(PROXY_ADMIN_PATH) returns (string memory proxyAdminAddr) {
            proxyAdmin = ProxyAdmin(vm.parseAddress(proxyAdminAddr));
        } catch {
            proxyAdmin = new ProxyAdmin();
            if (isBroadcasted) {
                _writeAddressToFile(address(proxyAdmin), PROXY_ADMIN_PATH);
            }
        }

        // Deploy ABVerifier
        abVerifierProxy = new TransparentUpgradeableProxy(
            address(new ABVerifier()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABVerifier.initialize.selector, admin)
        );
        if (isBroadcasted) {
            _writeAddressToFile(address(abVerifierProxy), VERIFIER_PATH);
        }

        // Deploy ABDataRegistry
        abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABDataRegistry.initialize.selector, DROP_ID_OFFSET, admin)
        );
        if (isBroadcasted) {
            _writeAddressToFile(address(abDataRegistryProxy), DATA_REGISTRY_PATH);
        }

        // Deploy ABVerifier
        abKycModuleProxy = new TransparentUpgradeableProxy(
            address(new ABKYCModule()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABKYCModule.initialize.selector, admin)
        );
        if (isBroadcasted) {
            _writeAddressToFile(address(abKycModuleProxy), KYC_MODULE_PATH);
        }

        // Deploy AnotherCloneFactory
        anotherCloneFactoryProxy = new TransparentUpgradeableProxy(
            address(new AnotherCloneFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                AnotherCloneFactory.initialize.selector,
                address(abDataRegistryProxy),
                address(abVerifierProxy),
                address(erc721Impl),
                address(erc1155Impl),
                address(royaltyImpl)
            )
        );
        if (isBroadcasted) {
            _writeAddressToFile(address(anotherCloneFactoryProxy), FACTORY_PATH);
        }
        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        ABDataRegistry(address(abDataRegistryProxy)).grantRole(
            keccak256("FACTORY_ROLE"), address(anotherCloneFactoryProxy)
        );

        // Grant AB_ADMIN_ROLE to the deployer address
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).grantRole(keccak256("AB_ADMIN_ROLE"), admin);
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).setABKYCModule(address(abKycModuleProxy));
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).approveERC721Implementation(address(erc721Impl));
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).approveERC721Implementation(address(erc721OEImpl));

        vm.stopBroadcast();
    }

    function _writeAddressToFile(address _addr, string memory _path) internal {
        vm.writeFile(_path, vm.toString(_addr));
    }
}
