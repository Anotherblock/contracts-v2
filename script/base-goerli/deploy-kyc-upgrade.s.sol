/* 
forge script script/base-goerli/deploy-kyc-upgrade.s.sol --rpc-url base-goerli --sig "run(bool)" true
forge script script/base-goerli/deploy-kyc-upgrade.s.sol --rpc-url base-goerli --sig "run(bool)" false --broadcast --verify
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

contract DeployKYCUpgrade is Script {
    string public constant KYC_MODULE_PATH = "deployment/84531/ABKYCModule/address";
    string public constant PROXY_ADMIN_PATH = "deployment/84531/ProxyAdmin/address";

    ABRoyalty public abRoyalty;
    ERC721ABLE public erc721LimitedEditionImpl;
    ERC721ABOE public erc721OpenEditionImpl;
    AnotherCloneFactory public factoryImpl;

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public abKycModuleProxy;
    address payable private anotherCloneFactoryProxy = payable(0x9BE7E2B13f70f170B63c0379663313EcdB527294);

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

        // proxyAdmin.upgrade(TransparentUpgradeableProxy(anotherCloneFactoryProxy), address(factoryImpl));

        // // Set new implementation contracts addresses in AnotherCloneFactory
        // AnotherCloneFactory(anotherCloneFactoryProxy).setABKYCModule(address(abKycModuleProxy));

        // AnotherCloneFactory(anotherCloneFactoryProxy).approveERC721Implementation(address(erc721LimitedEditionImpl));

        // AnotherCloneFactory(anotherCloneFactoryProxy).approveERC721Implementation(address(erc721OpenEditionImpl));

        // AnotherCloneFactory(anotherCloneFactoryProxy).setABRoyaltyImplementation(address(abRoyalty));

        vm.stopBroadcast();
    }

    function _writeAddressToFile(address _addr, string memory _path) internal {
        vm.writeFile(_path, vm.toString(_addr));
    }
}
