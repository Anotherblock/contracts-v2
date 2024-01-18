// SPDX-License-Identifier: MIT

/*
forge script script/base-goerli/deploy-royalty-helper.s.sol:DeployRoyaltyHelper --rpc-url base-goerli
forge script script/base-goerli/deploy-royalty-helper.s.sol:DeployRoyaltyHelper --rpc-url base-goerli --broadcast --verify
*/

pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABRoyaltyHelper} from "src/royalty/ABRoyaltyHelper.sol";

contract DeployRoyaltyHelper is Script {
    string constant DATAREGISTRY_PATH = "deployment/84531/ABDataRegistry/address";

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Read deployed address
        address abDataRegistry = vm.parseAddress(vm.readFile(DATAREGISTRY_PATH));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new ABRoyaltyHelper(abDataRegistry);

        vm.stopBroadcast();
    }
}
