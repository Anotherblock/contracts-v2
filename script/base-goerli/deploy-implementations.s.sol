/* 
forge script script/base-goerli/deploy-implementations.s.sol:DeployImplementation --rpc-url base-goerli
forge script script/base-goerli/deploy-implementations.s.sol:DeployImplementation --rpc-url base-goerli --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract DeployImplementation is Script {
    ERC721ABLE public erc721Impl;
    ERC1155AB public erc1155Impl;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        erc721Impl = new ERC721ABLE();
        erc1155Impl = new ERC1155AB();

        // Set new implementation contracts addresses in AnotherCloneFactory
        AnotherCloneFactory(0x4E393A0DD0331cE371d4d6fdd0B97E4b02450514).setERC721Implementation(address(erc721Impl));
        AnotherCloneFactory(0x4E393A0DD0331cE371d4d6fdd0B97E4b02450514).setERC1155Implementation(address(erc1155Impl));

        vm.stopBroadcast();
    }
}
