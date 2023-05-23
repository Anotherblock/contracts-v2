// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABHolderRegistry} from "src/utils/ABHolderRegistry.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {AnotherCloneFactoryBase} from "src/factory/AnotherCloneFactoryBase.sol";
import {ERC1155ABBase} from "src/token/ERC1155/ERC1155ABBase.sol";
import {ERC721ABWrapperBase} from "src/token/ERC721/ERC721ABWrapperBase.sol";
import {ERC721ABBase} from "src/token/ERC721/ERC721ABBase.sol";
import {ERC1155ABWrapperBase} from "src/token/ERC1155/ERC1155ABWrapperBase.sol";

contract DeployAnotherCloneFactory is Script {
    uint256 public constant BASE_GOERLI_CHAIN_ID = 84_531;
    uint256 public constant DROP_ID_OFFSET = 10_000;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Signer used for allowlist
        address allowlistSigner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        ERC721ABBase erc721Impl = new ERC721ABBase();
        ERC721ABWrapperBase erc721WrapperImpl = new ERC721ABWrapperBase();
        ERC1155ABBase erc1155Impl = new ERC1155ABBase();
        ERC1155ABWrapperBase erc1155WrapperImpl = new ERC1155ABWrapperBase();
        ABVerifier abVerifier = new ABVerifier(allowlistSigner);
        ABDataRegistry abDataRegistry = new ABDataRegistry(BASE_GOERLI_CHAIN_ID * DROP_ID_OFFSET);
        ABHolderRegistry abHolderRegistry = new ABHolderRegistry();

        // Deploy AnotherCloneFactory
        AnotherCloneFactoryBase anotherCloneFactory = new AnotherCloneFactoryBase(
            address(abDataRegistry), 
            address(abHolderRegistry),
            address(abVerifier), 
            address(erc721Impl), 
            address(erc721WrapperImpl), 
            address(erc1155Impl), 
            address(erc1155WrapperImpl)
        );

        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        // Grant AB_ADMIN_ROLE to the deployer address
        anotherCloneFactory.grantRole(keccak256("AB_ADMIN_ROLE"), allowlistSigner);

        vm.stopBroadcast();
    }
}
