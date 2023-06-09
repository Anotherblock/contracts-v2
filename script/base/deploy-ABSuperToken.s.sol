// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMockSuperToken is Script {
    address public constant SF_HOST_BASE_GOERLI = 0x507c3a7C6Ccc253884A2e3a3ee2A211cC7E796a6;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ABSuperToken abSuperToken = new ABSuperToken(SF_HOST_BASE_GOERLI);

        abSuperToken.initialize(IERC20(address(0)), 18, "anotherblock USDx", "abUSDx");

        abSuperToken.mint(vm.addr(deployerPrivateKey), 1000e18);

        vm.stopBroadcast();
    }
}
