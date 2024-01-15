/* 
op run --env-file=".env" -- forge script script/base/deploy-v1_2.s.sol --rpc-url base --sig "run(bool)" true --gas-price 345 --base-fee 50 --with-gas-price 345
op run --env-file=".env" -- forge script script/base/deploy-v1_2.s.sol --rpc-url base --sig "run(bool)" false --broadcast --verify --gas-price 345 --base-fee 50 --with-gas-price 345
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ABKYCModule} from "src/utils/ABKYCModule.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";
import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";

contract DeployV1_2 is Script {
    string public constant KYC_MODULE_PATH = "deployment/8453/ABKYCModule/address";
    string public constant PROXY_ADMIN_PATH = "deployment/8453/ProxyAdmin/address";

    ABRoyalty public abRoyalty;
    ERC721ABLE public erc721LimitedEditionImpl;
    ERC721ABOE public erc721OpenEditionImpl;
    AnotherCloneFactory public factoryImpl;

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public abKycModuleProxy;
    address payable private anotherCloneFactoryProxy = payable(0x137d7d27af9B4d7b467Ac008AFdcDb8C9Ac4ddd9);

    function run(bool isDryRun) external {
        // Account to deploy from
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Check if a Proxy Admin has already been deployed
        try vm.readFile(PROXY_ADMIN_PATH) returns (string memory proxyAdminAddr) {
            proxyAdmin = ProxyAdmin(vm.parseAddress(proxyAdminAddr));
        } catch {
            proxyAdmin = new ProxyAdmin();
            if (!isDryRun) {
                _writeAddressToFile(address(proxyAdmin), PROXY_ADMIN_PATH);
            }
        }

        // Deploy ABVerifier
        abKycModuleProxy = new TransparentUpgradeableProxy(
            address(new ABKYCModule()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABKYCModule.initialize.selector, admin)
        );
        if (!isDryRun) {
            _writeAddressToFile(address(abKycModuleProxy), KYC_MODULE_PATH);
        }

        // Deploy Implementation Contracts
        abRoyalty = new ABRoyalty();
        erc721LimitedEditionImpl = new ERC721ABLE();
        erc721OpenEditionImpl = new ERC721ABOE();
        factoryImpl = new AnotherCloneFactory();

        vm.stopBroadcast();
    }

    function _writeAddressToFile(address _addr, string memory _path) internal {
        vm.writeFile(_path, vm.toString(_addr));
    }
}

/*
TODO Manually (with multisig):

1 - Upgrade AnotherCloneFactory Proxy with new implementation 
2 - Set ABKYCModule contracts address in AnotherCloneFactory
3 - approve ERC721 Limited Edition implementation
4 - approve ERC721 Open Edition implementation
5 - set new royalty implementation
*/
