// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ABKYCModule} from "src/utils/ABKYCModule.sol";
import {ABClaim} from "src/royalty/ABClaim.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {MockNFT} from "test/_mocks/MockNFT.sol";
import {MockToken} from "test/_mocks/MockToken.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* solhint-disable */
contract ABClaimTest is Test {
    ABClaim public abClaim;
    ABKYCModule public abKycModule;
    TransparentUpgradeableProxy public abClaimProxy;
    TransparentUpgradeableProxy public abKycModuleProxy;
    ProxyAdmin public proxyAdmin;
    MockNFT public nft1;
    MockNFT public nft2;
    MockNFT public nft3;
    MockToken public mockUSD;

    address public relayer;
    uint256 public kycSignerPkey = 420;
    address public kycSigner;

    bytes32 public constant RELAYER_ROLE_HASH = keccak256("RELAYER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0;

    function setUp() public {
        relayer = vm.addr(1);
        kycSigner = vm.addr(kycSignerPkey);

        nft1 = new MockNFT("Mock NFT 1", "NFT1");
        nft2 = new MockNFT("Mock NFT 2", "NFT2");
        nft3 = new MockNFT("Mock NFT 3", "NFT3");
        mockUSD = new MockToken("Mock USD", "USD");

        proxyAdmin = new ProxyAdmin();

        abKycModuleProxy = new TransparentUpgradeableProxy(
            address(new ABKYCModule()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABKYCModule.initialize.selector, kycSigner)
        );
        abKycModule = ABKYCModule(address(abKycModuleProxy));
        vm.label(address(abKycModule), "abKycModule");

        abClaimProxy = new TransparentUpgradeableProxy(
            address(new ABClaim()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABClaim.initialize.selector, address(mockUSD), address(abKycModule), relayer)
        );
        abClaim = ABClaim(address(abClaimProxy));
        vm.label(address(abClaim), "abClaim");
    }

    function test_initialize() public {
        abClaimProxy = new TransparentUpgradeableProxy(address(new ABClaim()), address(proxyAdmin), "");

        abClaim = ABClaim(address(abClaimProxy));
        abClaim.initialize(address(mockUSD), address(abKycModule), relayer);

        assertEq(address(abClaim.abKycModule()), address(abKycModule));
        assertEq(abClaim.hasRole(RELAYER_ROLE_HASH, relayer), true);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        abClaim.initialize(address(mockUSD), address(abKycModule), relayer);
    }

    function test_setDropData_correctRole() public {
        uint256[] memory dropIds = new uint256[](2);
        address[] memory nfts = new address[](2);
        uint256[] memory supplies = new uint256[](2);
        bool[] memory isL1s = new bool[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        nfts[0] = vm.addr(10);
        nfts[1] = vm.addr(11);
        supplies[0] = 100;
        supplies[1] = 200;
        isL1s[0] = true;
        isL1s[1] = false;

        abClaim.setDropData(dropIds, nfts, isL1s, supplies);

        (address nft, bool isL1, uint256 supply) = abClaim.dropData(dropIds[0]);

        assertEq(nft, vm.addr(10));
        assertEq(supply, 100);
        assertEq(isL1, true);

        (nft, isL1, supply) = abClaim.dropData(dropIds[1]);

        assertEq(nft, vm.addr(11));
        assertEq(supply, 200);
        assertEq(isL1, false);
    }

    function test_setDropData_incorrectRole(address _sender) public {
        vm.assume(abClaim.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);

        uint256[] memory dropIds = new uint256[](2);
        address[] memory nfts = new address[](2);
        uint256[] memory supplies = new uint256[](2);
        bool[] memory isL1s = new bool[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        nfts[0] = vm.addr(10);
        nfts[1] = vm.addr(11);
        supplies[0] = 100;
        supplies[1] = 200;
        isL1s[0] = true;
        isL1s[1] = false;

        vm.expectRevert();
        vm.prank(_sender);
        abClaim.setDropData(dropIds, nfts, isL1s, supplies);
    }

    function test_setDropData_invalidParam_nftLength() public {
        uint256[] memory dropIds = new uint256[](2);
        address[] memory nfts = new address[](1);
        uint256[] memory supplies = new uint256[](2);
        bool[] memory isL1s = new bool[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        nfts[0] = vm.addr(10);
        supplies[0] = 100;
        supplies[1] = 200;
        isL1s[0] = true;
        isL1s[1] = false;

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abClaim.setDropData(dropIds, nfts, isL1s, supplies);
    }

    function test_setDropData_invalidParam_isL1Length() public {
        uint256[] memory dropIds = new uint256[](2);
        address[] memory nfts = new address[](2);
        uint256[] memory supplies = new uint256[](2);
        bool[] memory isL1s = new bool[](1);

        dropIds[0] = 0;
        dropIds[1] = 1;
        nfts[0] = vm.addr(10);
        nfts[1] = vm.addr(11);
        supplies[0] = 100;
        supplies[1] = 200;
        isL1s[0] = true;

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abClaim.setDropData(dropIds, nfts, isL1s, supplies);
    }

    function test_setDropData_invalidParam_supplyLength() public {
        uint256[] memory dropIds = new uint256[](2);
        address[] memory nfts = new address[](2);
        uint256[] memory supplies = new uint256[](1);
        bool[] memory isL1s = new bool[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        nfts[0] = vm.addr(10);
        nfts[1] = vm.addr(11);
        supplies[0] = 100;
        isL1s[0] = true;
        isL1s[1] = false;

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abClaim.setDropData(dropIds, nfts, isL1s, supplies);
    }

    function test_setDropData_singleDrop_correctRole(uint256 _dropId, uint256 _supply, address _nft, bool _isL1)
        public
    {
        abClaim.setDropData(_dropId, _nft, _isL1, _supply);

        (address nft, bool isL1, uint256 supply) = abClaim.dropData(_dropId);

        assertEq(nft, _nft);
        assertEq(supply, _supply);
        assertEq(isL1, _isL1);
    }

    function test_setDropData_singleDrop_incorrectRole(
        address _sender,
        uint256 _dropId,
        uint256 _supply,
        address _nft,
        bool _isL1
    ) public {
        vm.assume(abClaim.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);

        vm.expectRevert();
        vm.prank(_sender);
        abClaim.setDropData(_dropId, _nft, _isL1, _supply);
    }

    function test_batchUpdateL1Holdings_correctRole() public {
        uint256 dropId = 0;

        uint256[] memory tokenIds = new uint256[](3);
        address[] memory owners = new address[](3);

        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        owners[0] = vm.addr(100);
        owners[1] = vm.addr(101);
        owners[2] = vm.addr(102);

        vm.prank(relayer);
        abClaim.batchUpdateL1Holdings(dropId, tokenIds, owners);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(abClaim.ownerOf(dropId, tokenIds[i]), owners[i]);
        }
    }

    function test_batchUpdateL1Holdings_invalidParam_tokenIdsLength() public {
        uint256 dropId = 0;

        uint256[] memory tokenIds = new uint256[](2);
        address[] memory owners = new address[](3);

        tokenIds[0] = 0;
        tokenIds[1] = 1;

        owners[0] = vm.addr(100);
        owners[1] = vm.addr(101);
        owners[2] = vm.addr(102);

        vm.prank(relayer);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abClaim.batchUpdateL1Holdings(dropId, tokenIds, owners);
    }

    function test_batchUpdateL1Holdings_incorrectRole(address _sender) public {
        vm.assume(abClaim.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);
        uint256 dropId = 0;

        uint256[] memory tokenIds = new uint256[](3);
        address[] memory owners = new address[](3);

        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        owners[0] = vm.addr(100);
        owners[1] = vm.addr(101);
        owners[2] = vm.addr(102);

        vm.prank(_sender);
        vm.expectRevert();
        abClaim.batchUpdateL1Holdings(dropId, tokenIds, owners);
    }

    function test_updateL1Holdings_correctRole(uint256 _dropId, uint256 _tokenId, address _owner) public {
        vm.prank(relayer);
        abClaim.updateL1Holdings(_dropId, _tokenId, _owner);
        assertEq(abClaim.ownerOf(_dropId, _tokenId), _owner);
    }

    function test_updateL1Holdings_incorrectRole(address _sender, uint256 _dropId, uint256 _tokenId, address _owner)
        public
    {
        vm.assume(abClaim.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);

        vm.prank(_sender);
        vm.expectRevert();
        abClaim.updateL1Holdings(_dropId, _tokenId, _owner);
    }

    function test_depositRoyalty_correctRole(address _sender, uint256 _dropId, uint256 _amount) public {
        abClaim.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        mockUSD.mint(_sender, _amount);

        vm.startPrank(_sender);
        mockUSD.approve(address(abClaim), _amount);
        abClaim.depositRoyalty(_dropId, _amount);

        assertEq(mockUSD.balanceOf(address(abClaim)), _amount);
        assertEq(abClaim.totalDepositedPerDrop(_dropId), _amount);
    }

    function test_depositRoyalty_incorrectRole() public {}

    // function _generateKycSignature(address _signFor, uint256 _nonce) internal view returns (bytes memory signature) {
    //     // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
    //     bytes32 msgHash = keccak256(abi.encodePacked(_signFor, _nonce)).toEthSignedMessageHash();
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(kycSignerPkey, msgHash);
    //     signature = abi.encodePacked(r, s, v);
    // }
}
