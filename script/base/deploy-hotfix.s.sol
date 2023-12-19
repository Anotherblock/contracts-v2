/* 
forge script script/base/deploy-hotfix.s.sol:DeployHotFix --rpc-url base
forge script script/base/deploy-hotfix.s.sol:DeployHotFix --rpc-url base --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";

contract DeployHotFix is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new ABDataRegistry();

        vm.stopBroadcast();

        /* 
        TODO Manually 
            - Update Proxy Implementation (thru Proxy Admin) of ABDataRegistry contract
        */
    }
}
