/* 
forge script script/base-goerli/deploy-implementations.s.sol:DeployImplementation --rpc-url base-goerli
forge script script/base-goerli/deploy-implementations.s.sol:DeployImplementation --rpc-url base-goerli --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract DeployImplementation is Script {
    ERC721AB public erc721Impl;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        erc721Impl = new ERC721AB();

        // Set new implementation contracts addresses in AnotherCloneFactory
        AnotherCloneFactory(0x9BE7E2B13f70f170B63c0379663313EcdB527294).setERC721Implementation(address(erc721Impl));

        vm.stopBroadcast();
    }
}
