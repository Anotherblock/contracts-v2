/* 
forge script script/base/deploy-implementations.s.sol:DeployImplementation --rpc-url base
forge script script/base/deploy-implementations.s.sol:DeployImplementation --rpc-url base --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract DeployImplementationBase is Script {
    ERC721ABLE public erc721Impl;
    ERC1155AB public erc1155Impl;
    address public anotherCloneFactory = 0x137d7d27af9B4d7b467Ac008AFdcDb8C9Ac4ddd9;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        erc721Impl = new ERC721ABLE();
        erc1155Impl = new ERC1155AB();

        // Set new implementation contracts addresses in AnotherCloneFactory
        AnotherCloneFactory(anotherCloneFactory).setERC721Implementation(address(erc721Impl));
        AnotherCloneFactory(anotherCloneFactory).setERC1155Implementation(address(erc1155Impl));

        vm.stopBroadcast();
    }
}
