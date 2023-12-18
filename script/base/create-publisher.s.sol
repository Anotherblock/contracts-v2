// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract CreatePublisherBase is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        AnotherCloneFactory anotherCloneFactory = AnotherCloneFactory(0x0B16Ae22bB605fA9964Feb36987aD15124504656);

        anotherCloneFactory.createPublisherProfile(vm.addr(deployerPrivateKey), 9000);

        vm.stopBroadcast();
    }
}
