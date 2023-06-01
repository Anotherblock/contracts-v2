// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABHolderRegistry} from "src/utils/ABHolderRegistry.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABWrapper} from "src/token/ERC721/ERC721ABWrapper.sol";
import {ERC721ABBase} from "src/token/ERC721/ERC721ABBase.sol";
import {ERC1155ABWrapper} from "src/token/ERC1155/ERC1155ABWrapper.sol";

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
        ERC721ABWrapper erc721WrapperImpl = new ERC721ABWrapper();
        ERC1155AB erc1155Impl = new ERC1155AB();
        ERC1155ABWrapper erc1155WrapperImpl = new ERC1155ABWrapper();
        ABHolderRegistry royaltyImpl = new ABHolderRegistry();
        ABVerifier abVerifier = new ABVerifier(allowlistSigner);
        ABDataRegistry abDataRegistry = new ABDataRegistry(DROP_ID_OFFSET, treasury);

        // Deploy AnotherCloneFactory
        AnotherCloneFactory anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry), 
            address(abVerifier), 
            address(erc721Impl), 
            address(erc721WrapperImpl), 
            address(erc1155Impl), 
            address(erc1155WrapperImpl), 
            address(royaltyImpl)
        );

        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        // Grant AB_ADMIN_ROLE to the deployer address
        anotherCloneFactory.grantRole(keccak256("AB_ADMIN_ROLE"), allowlistSigner);

        vm.stopBroadcast();
    }
}
