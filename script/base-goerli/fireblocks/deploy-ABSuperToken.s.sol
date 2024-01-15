// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMockSuperToken is Script {
    address public constant SF_HOST_BASE_GOERLI = 0x9D469e8515F0cD12E30699B18059Ac8ca3324110;

    function run() external {
        vm.startBroadcast();

        ABSuperToken abSuperToken = new ABSuperToken(SF_HOST_BASE_GOERLI);

        abSuperToken.initialize(IERC20(address(0)), 18, "anotherblock USDx", "abUSDx");

        abSuperToken.mint(0xD71256eC24925873cE9E9F085f89864Ca05970bD, 1000e18);

        vm.stopBroadcast();
    }
}
