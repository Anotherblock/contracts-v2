/* 
forge script script/base-goerli/upgrades/deploy-ABDataRegistryImpl.s.sol:DeployABDataRegistryImplementation --rpc-url base-goerli
forge script script/base-goerli/upgrades/deploy-ABDataRegistryImpl.s.sol:DeployABDataRegistryImplementation --rpc-url base-goerli --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";

contract DeployABDataRegistryImplementation is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new ABDataRegistry();

        vm.stopBroadcast();
    }
}
