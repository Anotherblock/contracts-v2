// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/ABRoyalty.sol";
import "../src/AnotherCloneFactory.sol";
import "../src/ERC721AB.sol";
import "../src/ERC1155AB.sol";

contract DeployAnotherCloneFactory is Script {
    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        ERC721AB erc721Impl = new ERC721AB();
        ERC1155AB erc1155Impl = new ERC1155AB();
        ABRoyalty royaltyImpl = new ABRoyalty();

        // Deploy AnotherCloneFactory
        AnotherCloneFactory anotherCloneFactory =
            new AnotherCloneFactory(address(erc721Impl), address(erc1155Impl), address(royaltyImpl));

        vm.stopBroadcast();
    }
}
