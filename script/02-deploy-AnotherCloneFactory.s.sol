// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/ABRoyalty.sol";
import "../src/ABVerifier.sol";
import "../src/ABDataRegistry.sol";
import "../src/AnotherCloneFactory.sol";
import "../src/ERC721AB.sol";
import "../src/ERC1155AB.sol";

contract DeployAnotherCloneFactory is Script {
    uint256 public constant OPTIMISM_GOERLI_CHAIN_ID = 420;
    uint256 public constant DROP_ID_OFFSET = 10_000;

    function run() external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address allowlistSigner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Implementation Contracts
        ERC721AB erc721Impl = new ERC721AB();
        ERC1155AB erc1155Impl = new ERC1155AB();
        ABRoyalty royaltyImpl = new ABRoyalty();
        ABVerifier abVerifier = new ABVerifier(allowlistSigner);
        ABDataRegistry abDataRegistry = new ABDataRegistry(OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET);

        // Deploy AnotherCloneFactory
        AnotherCloneFactory anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry), 
            address(abVerifier), 
            address(erc721Impl), 
            address(erc1155Impl), 
            address(royaltyImpl)
        );

        // Set AnotherCloneFactory address in ABDataRegistry contract
        abDataRegistry.setAnotherCloneFactory(address(anotherCloneFactory));

        vm.stopBroadcast();
    }
}
