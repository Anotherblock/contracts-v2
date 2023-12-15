// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract CreatePublisherBaseGoerli is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        AnotherCloneFactory anotherCloneFactory = AnotherCloneFactory(0x3d92216eBe9Ce3D5FdCcF74990602C9D1D9D1B77);

        anotherCloneFactory.createPublisherProfile(vm.addr(deployerPrivateKey), 9000);

        vm.stopBroadcast();
    }
}
