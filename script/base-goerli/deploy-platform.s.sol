// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";

contract DeployPlatformBaseGoerli is Script {
    uint256 public constant DROP_ID_OFFSET = 20_000;

    string public constant VERIFIER_PATH = "deployment/84531/ABVerifier/address";
    string public constant DATA_REGISTRY_PATH = "deployment/84531/ABDataRegistry/address";
    string public constant FACTORY_PATH = "deployment/84531/AnotherCloneFactory/address";
    string public constant PROXY_ADMIN_PATH = "deployment/84531/ProxyAdmin/address";

    ERC721ABLE public erc721Impl;
    ERC721ABOE public erc721OEImpl;
    ERC1155AB public erc1155Impl;
    ABRoyalty public royaltyImpl;
    ProxyAdmin public proxyAdmin;

    // address public constant BASE_GOERLI_MULTISIG = 0x34447e8b81e657F7d8fF80070c24b1320AcF4013;

    TransparentUpgradeableProxy public abVerifierProxy;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;

    function run(bool isDryRun) external {
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
        royaltyImpl = new ABRoyalty();

        // Check if a Proxy Admin has already been deployed
        try vm.readFile(PROXY_ADMIN_PATH) returns (string memory proxyAdminAddr) {
            proxyAdmin = ProxyAdmin(vm.parseAddress(proxyAdminAddr));
        } catch {
            proxyAdmin = new ProxyAdmin();
            if (!isDryRun) {
                _writeAddressToFile(address(proxyAdmin), PROXY_ADMIN_PATH);
            }
        }

        // Deploy ABVerifier
        abVerifierProxy = new TransparentUpgradeableProxy(
            address(new ABVerifier()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABVerifier.initialize.selector, admin)
        );
        if (!isDryRun) {
            _writeAddressToFile(address(abVerifierProxy), VERIFIER_PATH);
        }

        // Deploy ABDataRegistry
        abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABDataRegistry.initialize.selector, DROP_ID_OFFSET, admin)
        );
        if (!isDryRun) {
            _writeAddressToFile(address(abDataRegistryProxy), DATA_REGISTRY_PATH);
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
        if (!isDryRun) {
            _writeAddressToFile(address(anotherCloneFactoryProxy), FACTORY_PATH);
        }
        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        ABDataRegistry(address(abDataRegistryProxy)).grantRole(
            keccak256("FACTORY_ROLE"), address(anotherCloneFactoryProxy)
        );

        // Grant AB_ADMIN_ROLE to the deployer address
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).grantRole(keccak256("AB_ADMIN_ROLE"), admin);

        vm.stopBroadcast();
    }

    function _writeAddressToFile(address _addr, string memory _path) internal {
        vm.writeFile(_path, vm.toString(_addr));
    }
}
