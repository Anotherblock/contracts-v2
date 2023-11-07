/* 
forge script script/base/deploy-v1_1.s.sol:DeployUpgrade --rpc-url base
forge script script/base/deploy-v1_1.s.sol:DeployUpgrade --rpc-url base --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract DeployUpgrade is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new ERC721ABLE();
        new ERC721ABOE();
        new ABDataRegistry();
        new AnotherCloneFactory();

        vm.stopBroadcast();

        /* 
        TODO Manually 
            1) Update Proxy Implementation (thru Proxy Admin) of ABDataRegistry contract
            2) Update Proxy Implementation (thru Proxy Admin) of AnotherCloneFactory contract
            3) setERC721ABImplementation of AnotherCloneFactory (using erc721LimitedEditionImpl address as parameter)
            4) Update theGraph on Base (added some checks on maxSupply)
        */
    }
}
