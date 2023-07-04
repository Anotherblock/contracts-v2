// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

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
        address allowlistSigner = vm.addr(deployerPrivateKey);
        address treasury = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        ERC721ABBase erc721Impl = new ERC721ABBase();
        ERC1155AB erc1155Impl = new ERC1155AB();
        ABRoyalty royaltyImpl = new ABRoyalty();
        ABVerifier abVerifier = new ABVerifier(allowlistSigner);
        ABDataRegistry abDataRegistry = new ABDataRegistry(DROP_ID_OFFSET, treasury);

        // Deploy AnotherCloneFactory
        AnotherCloneFactory anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry), 
            address(abVerifier), 
            address(erc721Impl), 
            address(erc1155Impl), 
            address(royaltyImpl)
        );

        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        // Grant AB_ADMIN_ROLE to the deployer address
        anotherCloneFactory.grantRole(keccak256("AB_ADMIN_ROLE"), allowlistSigner);

        vm.stopBroadcast();
    }
}
