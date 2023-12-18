// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

contract DeployRoyaltyBaseGoerliFireBlock is Script {
    string constant PROXY_ADMIN_PATH = "deployment/84531/ProxyAdmin/address";
    string constant DATAREGISTRY_PATH = "deployment/84531/ABDataRegistry/address";

    function run(address _publisher) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Read deployed address
        address proxyAdmin = vm.parseAddress(vm.readFile(PROXY_ADMIN_PATH));
        address abDataRegistry = vm.parseAddress(vm.readFile(DATAREGISTRY_PATH));

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
