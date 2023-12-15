/* 
forge script script/base-goerli/deploy-upgrade.s.sol:DeployUpgrade --rpc-url base-goerli
forge script script/base-goerli/deploy-upgrade.s.sol:DeployUpgrade --rpc-url base-goerli --broadcast --verify
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract DeployUpgradeBaseGoerli is Script {
    ERC721ABLE public erc721LimitedEditionImpl;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new ABDataRegistry();

        // Deploy Implementation Contracts
        erc721LimitedEditionImpl = new ERC721ABLE();
        new ERC721ABOE();

        // Set new implementation contracts addresses in AnotherCloneFactory
        AnotherCloneFactory(0x9BE7E2B13f70f170B63c0379663313EcdB527294).setERC721Implementation(
            address(erc721LimitedEditionImpl)
        );

        vm.stopBroadcast();
    }
}
