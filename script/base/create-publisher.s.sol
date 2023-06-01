// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABHolderRegistry} from "src/utils/ABHolderRegistry.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC721ABWrapper} from "src/token/ERC721/ERC721ABWrapper.sol";
import {ERC721ABBase} from "src/token/ERC721/ERC721ABBase.sol";
import {ERC1155ABWrapper} from "src/token/ERC1155/ERC1155ABWrapper.sol";

contract CreatePublisher is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        AnotherCloneFactory anotherCloneFactory = AnotherCloneFactory(0x607DefF3Bb9A93de1340544F8C5044C94637ACC8);

        anotherCloneFactory.createPublisherProfile(vm.addr(deployerPrivateKey), 9000);

        vm.stopBroadcast();
    }
}
