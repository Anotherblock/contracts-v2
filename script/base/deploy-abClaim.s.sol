/*
op run --env-file=".env" -- forge script script/base/deploy-abClaim.s.sol --rpc-url base --sig "run(bool)" false --gas-price 412 --base-fee 309 --with-gas-price 489
op run --env-file=".env" -- forge script script/base/deploy-abClaim.s.sol --rpc-url base --sig "run(bool)" true --broadcast --verify --etherscan-api-key ${BASE_ETHERSCAN_API_KEY} --gas-price 412 --base-fee 309 --with-gas-price 489 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ABClaim} from "src/royalty/ABClaim.sol";

contract DeployABClaim is Script {
    string constant PROXY_ADMIN_PATH = "deployment/8453/ProxyAdmin/address";
    string constant AB_KYC_MODULE_PATH = "deployment/8453/ABKYCModule/address";
    string constant AB_CLAIM_PATH = "deployment/8453/ABClaim/address";

    function run(bool isBroadcasted) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Read deployed address
        address proxyAdmin = vm.parseAddress(vm.readFile(PROXY_ADMIN_PATH));
        address abKycModule = vm.parseAddress(vm.readFile(AB_KYC_MODULE_PATH));
        address baseUSDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        address baseRelayer = 0xE543dc9363E8D1bb0Aff1805ac7D574276266A68;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        TransparentUpgradeableProxy abClaimProxy = new TransparentUpgradeableProxy(
            address(new ABClaim()),
            proxyAdmin,
            abi.encodeWithSelector(ABClaim.initialize.selector, baseUSDC, abKycModule, baseRelayer)
        );

        vm.stopBroadcast();

        if (isBroadcasted) {
            vm.writeFile(AB_CLAIM_PATH, vm.toString(address(abClaimProxy)));
        }
    }
}
