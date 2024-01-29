// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ABClaim} from "src/royalty/ABClaim.sol";

contract DeployABClaim is Script {
    string constant PROXY_ADMIN_PATH = "deployment/84531/ProxyAdmin/address";
    string constant AB_KYC_MODULE_PATH = "deployment/84531/ABKYCModule/address";

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Read deployed address
        address proxyAdmin = vm.parseAddress(vm.readFile(PROXY_ADMIN_PATH));
        address abKycModule = vm.parseAddress(vm.readFile(AB_KYC_MODULE_PATH));
        address baseGoerliUSDC = 0x5d1c51346908e017dDE0007A5DB8F1394dFFAaD5;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        new TransparentUpgradeableProxy(
            address(new ABClaim()),
            proxyAdmin,
            abi.encodeWithSelector(
                ABClaim.initialize.selector, baseGoerliUSDC, abKycModule, vm.addr(deployerPrivateKey)
            )
        );

        vm.stopBroadcast();
    }
}
