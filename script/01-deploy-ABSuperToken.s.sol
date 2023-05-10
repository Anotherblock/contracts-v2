// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../test/mocks/ABSuperToken.sol";

contract DeployMockSuperToken is Script {
    error INCORRECT_NETWORK();

    address SF_HOST_OPTIMISM_GOERLI = 0xE40983C2476032A0915600b9472B3141aA5B5Ba9;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new ABSuperToken(SF_HOST_OPTIMISM_GOERLI);

        vm.stopBroadcast();
    }
}
