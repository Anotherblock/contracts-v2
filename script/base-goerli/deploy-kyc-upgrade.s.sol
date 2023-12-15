/* 
forge script script/base-goerli/deploy-kyc-upgrade.s.sol --rpc-url base-goerli
forge script script/base-goerli/deploy-kyc-upgrade.s.sol:DeployUpgrade --rpc-url base-goerli --broadcast --verify
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

contract DeployKYCUpgradeBaseGoerli is Script {
    string public constant KYC_MODULE_PATH = "deployment/84531/ABKYCModule/address";
    string public constant PROXY_ADMIN_PATH = "deployment/84531/ProxyAdmin/address";

    ABRoyalty public abRoyalty;
    ERC721ABLE public erc721LimitedEditionImpl;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public abKycModuleProxy;

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
        new ERC721ABOE();

        // Set new implementation contracts addresses in AnotherCloneFactory
        AnotherCloneFactory(0x9BE7E2B13f70f170B63c0379663313EcdB527294).setERC721Implementation(
            address(erc721LimitedEditionImpl)
        );

        AnotherCloneFactory(0x9BE7E2B13f70f170B63c0379663313EcdB527294).setABRoyaltyImplementation(address(abRoyalty));

        // Set new implementation contracts addresses in AnotherCloneFactory
        AnotherCloneFactory(0x9BE7E2B13f70f170B63c0379663313EcdB527294).setABKYCModule(address(abKycModuleProxy));

        vm.stopBroadcast();
    }

    function _writeAddressToFile(address _addr, string memory _path) internal {
        vm.writeFile(_path, vm.toString(_addr));
    }
}
