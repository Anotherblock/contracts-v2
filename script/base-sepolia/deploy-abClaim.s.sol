// SPDX-License-Identifier: MIT

/*
forge script script/base-sepolia/deploy-abClaim.s.sol:DeployABClaim --rpc-url base-sepolia --sig "run(bool)" false --etherscan-api-key $BASE_ETHERSCAN_API_KEY
forge script script/base-sepolia/deploy-abClaim.s.sol:DeployABClaim --rpc-url base-sepolia --broadcast --verify --sig "run(bool)" true --etherscan-api-key $BASE_ETHERSCAN_API_KEY
*/
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ABClaim} from "src/royalty/ABClaim.sol";

contract DeployABClaim is Script {
    string constant PROXY_ADMIN_PATH = "deployment/84532/ProxyAdmin/address";
    string constant AB_CLAIM_PATH = "deployment/84532/ABClaim/address";
    string constant AB_KYC_MODULE_PATH = "deployment/84532/ABKYCModule/address";

    ProxyAdmin public proxyAdmin;

    function run(bool isBroadcasted) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Read deployed address

        address abKycModule = address(0);
        address baseSepoliaUSDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

        vm.startBroadcast(deployerPrivateKey);

        // Check if a Proxy Admin has already been deployed
        try vm.readFile(PROXY_ADMIN_PATH) returns (string memory proxyAdminAddr) {
            proxyAdmin = ProxyAdmin(vm.parseAddress(proxyAdminAddr));
        } catch {
            proxyAdmin = new ProxyAdmin();
            if (isBroadcasted) {
                vm.writeFile(PROXY_ADMIN_PATH, vm.toString(address(proxyAdmin)));
            }
        }

        // Deploy Implementation Contracts
        TransparentUpgradeableProxy abClaimProxy = new TransparentUpgradeableProxy(
            address(new ABClaim()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                ABClaim.initialize.selector, baseSepoliaUSDC, abKycModule, vm.addr(deployerPrivateKey)
            )
        );

        if (isBroadcasted) {
            vm.writeFile(AB_CLAIM_PATH, vm.toString(address(abClaimProxy)));
        }

        vm.stopBroadcast();
    }
}
