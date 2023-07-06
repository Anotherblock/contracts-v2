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
import {ERC721ABBase} from "src/token/ERC721/ERC721ABBase.sol";

contract DeployPlatform is Script {
    uint256 public constant DROP_ID_OFFSET = 20_000;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        ERC721ABBase erc721Impl = new ERC721ABBase();
        ERC1155AB erc1155Impl = new ERC1155AB();
        ABRoyalty royaltyImpl = new ABRoyalty();
        ABVerifier abVerifier = new ABVerifier(admin);

        ProxyAdmin proxyAdmin = new ProxyAdmin();

        TransparentUpgradeableProxy abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABDataRegistry.initialize.selector, DROP_ID_OFFSET, admin)
        );

        // Deploy AnotherCloneFactory
        TransparentUpgradeableProxy anotherCloneFactoryProxy = new TransparentUpgradeableProxy(
            address(new AnotherCloneFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(AnotherCloneFactory.initialize.selector,
            address(abDataRegistryProxy), 
            address(abVerifier), 
            address(erc721Impl), 
            address(erc1155Impl), 
            address(royaltyImpl), 
            admin)
        );

        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        ABDataRegistry(address(abDataRegistryProxy)).grantRole(
            keccak256("FACTORY_ROLE"), address(anotherCloneFactoryProxy)
        );

        // Grant AB_ADMIN_ROLE to the deployer address
        AnotherCloneFactory(address(anotherCloneFactoryProxy)).grantRole(keccak256("AB_ADMIN_ROLE"), admin);

        vm.stopBroadcast();
    }
}
