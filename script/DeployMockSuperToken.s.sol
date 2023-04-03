// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Staking.sol";
import "../test/mocks/MockERC20.sol";

contract DeployPoc is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Staking staking = new Staking();
        MockERC20 merc20 = new MockERC20();

        uint256 amount = 10e18;

        merc20.approve(address(staking), amount);
        staking.stake(address(merc20), amount);

        vm.stopBroadcast();
    }
}
