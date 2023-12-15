// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

contract DeployRoyaltyOptimism is Script {
    function run(address _publisher) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAdmin = 0x1f80B2bF331C4c4C1375ed83ddc773122e2cE7Eb;
        address abDataRegistry = 0x1f80B2bF331C4c4C1375ed83ddc773122e2cE7Eb;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new TransparentUpgradeableProxy(
            address(new ABRoyalty()),
            proxyAdmin,
            abi.encodeWithSelector(ABRoyalty.initialize.selector, _publisher, abDataRegistry)
        );

        vm.stopBroadcast();
    }
}
