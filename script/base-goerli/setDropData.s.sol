// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {ABClaim} from "src/royalty/ABClaim.sol";

contract SetDropData is Script {
    string constant PROXY_ADMIN_PATH = "deployment/84531/ProxyAdmin/address";
    string constant AB_KYC_MODULE_PATH = "deployment/84531/ABDataRegistry/address";

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ABClaim abClaim = ABClaim(0x47Af0b5B9175001A769B8d36416577778706E112);

        abClaim.setDropData(20073, 0x2b5974e07331f3D1dCff454C1ff4b4481e5385de, false, 15);
        abClaim.depositRoyalty(20073, 15e6);

        vm.stopBroadcast();
    }
}
