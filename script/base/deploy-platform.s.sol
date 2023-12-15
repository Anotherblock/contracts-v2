// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";

contract DeployPlatformBase is Script {
    uint256 public constant DROP_ID_OFFSET = 10_000;

    address public constant BASE_MAINNET_MULTISIG_TREASURY = 0x6367DF7dCed8fE1E8B55d0e7b2e4a5EC3E149D38;
    address public constant BASE_MAINNET_MULTISIG_DEV = 0xC46a3eafbb0296cc8A30Ed264156C81646ba116E;
    address public constant BASE_MAINNET_VERIFIER_SIGNER = 0x350821361673980851763F37Ae8E7C19D4f2C44E;

    string public constant VERIFIER_PATH = "deployment/8453/ABVerifier/address";
    string public constant DATA_REGISTRY_PATH = "deployment/8453/ABDataRegistry/address";
    string public constant FACTORY_PATH = "deployment/8453/AnotherCloneFactory/address";
    string public constant PROXY_ADMIN_PATH = "deployment/8453/ProxyAdmin/address";

    ERC721ABLE public erc721Impl;
    ERC1155AB public erc1155Impl;
    ABRoyalty public royaltyImpl;
    ProxyAdmin public proxyAdmin;

    TransparentUpgradeableProxy public abVerifierProxy;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;

    function run(bool isDryRun) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        erc721Impl = new ERC721ABLE();
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
            abi.encodeWithSelector(ABVerifier.initialize.selector, BASE_MAINNET_VERIFIER_SIGNER)
        );
        if (!isDryRun) {
            _writeAddressToFile(address(abVerifierProxy), VERIFIER_PATH);
        }

        // Deploy ABDataRegistry
        abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABDataRegistry.initialize.selector, DROP_ID_OFFSET, BASE_MAINNET_MULTISIG_TREASURY)
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
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).grantRole(
            keccak256("AB_ADMIN_ROLE"), BASE_MAINNET_MULTISIG_DEV
        );

        vm.stopBroadcast();
    }

    function _writeAddressToFile(address _addr, string memory _path) internal {
        vm.writeFile(_path, vm.toString(_addr));
    }
}
