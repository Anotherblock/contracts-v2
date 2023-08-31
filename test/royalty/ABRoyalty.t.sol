// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {ABRoyaltyTestData} from "test/_testdata/ABRoyalty.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ABRoyaltyTest is Test, ABRoyaltyTestData {
    /* Users */
    address payable public publisher;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    address public genesisRecipient;
    address payable public treasury;

    /* Contracts */
    ABSuperToken public royaltyToken;
    ABRoyalty public abRoyaltyImpl;
    ABVerifier public abVerifier;
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public abVerifierProxy;

    ABRoyalty public abRoyalty;

    /* Environment Variables */
    string public BASE_RPC_URL = vm.envString("BASE_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(BASE_RPC_URL, 1445932));

        /* Setup admins */
        abSigner = vm.addr(abSignerPkey);
        genesisRecipient = vm.addr(100);
        treasury = payable(vm.addr(1000));
        vm.label(treasury, "treasury");

        /* Setup users */
        publisher = payable(vm.addr(5));
        vm.deal(publisher, 100 ether);
        vm.label(publisher, "publisher");

        /* Contracts Deployments */
        proxyAdmin = new ProxyAdmin();

        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        royaltyToken.mint(publisher, 1000e18);
        vm.label(address(royaltyToken), "royaltyToken");

        abVerifierProxy = new TransparentUpgradeableProxy(
            address(new ABVerifier()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABVerifier.initialize.selector,abSigner)
        );
        abVerifier = ABVerifier(address(abVerifierProxy));
        vm.label(address(abVerifier), "abVerifier");

        erc1155Impl = new ERC1155AB();
        vm.label(address(erc1155Impl), "erc1155Impl");

        erc721Impl = new ERC721AB();
        vm.label(address(erc721Impl), "erc721Impl");

        abRoyaltyImpl = new ABRoyalty();
        vm.label(address(abRoyaltyImpl), "abRoyaltyImpl");

        abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABDataRegistry.initialize.selector, DROP_ID_OFFSET, treasury)
        );

        abDataRegistry = ABDataRegistry(address(abDataRegistryProxy));
        vm.label(address(abDataRegistry), "abDataRegistry");

        anotherCloneFactoryProxy = new TransparentUpgradeableProxy(
            address(new AnotherCloneFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(AnotherCloneFactory.initialize.selector,
                address(abDataRegistry),
                address(abVerifier),
                address(erc721Impl),
                address(erc1155Impl),
                address(abRoyaltyImpl)
            )
        );

        anotherCloneFactory = AnotherCloneFactory(address(anotherCloneFactoryProxy));

        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher, PUBLISHER_FEE);

        address abRoyaltyAddr = abDataRegistry.publishers(publisher);

        abRoyalty = ABRoyalty(abRoyaltyAddr);
    }

    function test_initialize() public {
        TransparentUpgradeableProxy abRoyaltyProxy = new TransparentUpgradeableProxy(
            address(new ABRoyalty()),
            address(proxyAdmin),
            ""
        );

        abRoyalty = ABRoyalty(address(abRoyaltyProxy));
        abRoyalty.initialize(publisher, address(abDataRegistry));

        assertEq(abRoyalty.publisher(), publisher);
        assertEq(abRoyalty.hasRole(DEFAULT_ADMIN_ROLE_HASH, publisher), true);
        assertEq(abRoyalty.hasRole(DEFAULT_ADMIN_ROLE_HASH, address(this)), false);
        assertEq(abRoyalty.hasRole(REGISTRY_ROLE_HASH, address(abDataRegistry)), true);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        abRoyalty.initialize(publisher, address(abDataRegistry));
    }

    function test_initPayoutIndex_correctRole(address _sender, address _nft, uint256 _dropId) public {
        vm.assume(_sender != address(0));

        vm.prank(publisher);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);

        assertEq(abRoyalty.nftPerDropId(_dropId), address(0));

        vm.prank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);

        assertEq(abRoyalty.nftPerDropId(_dropId), _nft);
    }

    function test_initPayoutIndex_incorrectRole(address _sender, address _nft, uint256 _dropId) public {
        vm.assume(_sender != address(0));
        vm.assume(abRoyalty.hasRole(REGISTRY_ROLE_HASH, _sender) == false);
        vm.prank(_sender);
        vm.expectRevert();
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
    }

    function test_updatePayout721_correctRole_minting(
        address _sender,
        address _newHolder,
        address _nft,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _newHolder, _dropId, _quantity);

        assertEq(abRoyalty.getUserSubscription(_dropId, _newHolder), _quantity * UNITS_PRECISION);
        vm.stopPrank();
    }

    function test_updatePayout721_correctRole_burning(
        address _sender,
        address _previousHolder,
        address _nft,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);

        abRoyalty.updatePayout721(address(0), _previousHolder, _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), _quantity * UNITS_PRECISION);

        abRoyalty.updatePayout721(_previousHolder, address(0), _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), 0);

        vm.stopPrank();
    }

    function test_updatePayout721_correctRole_transferPartially(
        address _sender,
        address _newHolder,
        address _previousHolder,
        address _nft,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_quantity > 1 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);

        abRoyalty.updatePayout721(address(0), _previousHolder, _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), _quantity * UNITS_PRECISION);

        abRoyalty.updatePayout721(_previousHolder, _newHolder, _dropId, _quantity - 1);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), 1 * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(_dropId, _newHolder), (_quantity - 1) * UNITS_PRECISION);

        vm.stopPrank();
    }

    function test_updatePayout721_correctRole_transferAll(
        address _sender,
        address _newHolder,
        address _previousHolder,
        address _nft,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);

        abRoyalty.updatePayout721(address(0), _previousHolder, _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), _quantity * UNITS_PRECISION);

        abRoyalty.updatePayout721(_previousHolder, _newHolder, _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), 0);
        assertEq(abRoyalty.getUserSubscription(_dropId, _newHolder), _quantity * UNITS_PRECISION);

        vm.stopPrank();
    }

    function test_updatePayout721_incorrectRole(address _sender, address _newHolder, uint256 _dropId, uint256 _quantity)
        public
    {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);
        vm.assume(abRoyalty.hasRole(COLLECTION_ROLE_HASH, _sender) == false);
        vm.assume(abRoyalty.hasRole(REGISTRY_ROLE_HASH, _sender) == false);

        vm.expectRevert();
        abRoyalty.updatePayout721(address(0), _newHolder, _dropId, _quantity);
    }

    function test_updatePayout1155_correctRole_minting(
        address _sender,
        address _newHolder,
        address _nft,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantityA > 1 && _quantityA < 10_000);
        vm.assume(_quantityB > 1 && _quantityB < 10_000);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantityA;
        quantities[1] = _quantityB;

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), dropIds[0]);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), dropIds[1]);
        abRoyalty.updatePayout1155(address(0), _newHolder, dropIds, quantities);

        assertEq(abRoyalty.getUserSubscription(0, _newHolder), _quantityA * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(1, _newHolder), _quantityB * UNITS_PRECISION);
        vm.stopPrank();
    }

    function test_updatePayout1155_correctRole_burning(
        address _sender,
        address _previousHolder,
        address _nft,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_quantityA > 1 && _quantityA < 10_000);
        vm.assume(_quantityB > 1 && _quantityB < 10_000);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantityA;
        quantities[1] = _quantityB;

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), dropIds[0]);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), dropIds[1]);
        abRoyalty.updatePayout1155(address(0), _previousHolder, dropIds, quantities);
        assertEq(abRoyalty.getUserSubscription(0, _previousHolder), _quantityA * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(1, _previousHolder), _quantityB * UNITS_PRECISION);

        abRoyalty.updatePayout1155(_previousHolder, address(0), dropIds, quantities);
        assertEq(abRoyalty.getUserSubscription(0, _previousHolder), 0);
        assertEq(abRoyalty.getUserSubscription(1, _previousHolder), 0);

        vm.stopPrank();
    }

    function test_updatePayout1155_correctRole_transfer(
        address _sender,
        address _newHolder,
        address _previousHolder,
        address _nft,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_previousHolder != _newHolder);
        vm.assume(_quantityA > 1 && _quantityA < 10_000);
        vm.assume(_quantityB > 1 && _quantityB < 10_000);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantityA;
        quantities[1] = _quantityB;

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), dropIds[0]);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), dropIds[1]);
        abRoyalty.updatePayout1155(address(0), _previousHolder, dropIds, quantities);
        assertEq(abRoyalty.getUserSubscription(0, _previousHolder), _quantityA * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(1, _previousHolder), _quantityB * UNITS_PRECISION);

        abRoyalty.updatePayout1155(_previousHolder, _newHolder, dropIds, quantities);
        assertEq(abRoyalty.getUserSubscription(0, _newHolder), _quantityA * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(1, _newHolder), _quantityB * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(0, _previousHolder), 0);
        assertEq(abRoyalty.getUserSubscription(1, _previousHolder), 0);

        vm.stopPrank();
    }

    function test_updatePayout1155_incorrectRole(
        address _sender,
        address _newHolder,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantityA > 1 && _quantityA < 10_000);
        vm.assume(_quantityB > 1 && _quantityB < 10_000);
        vm.assume(abRoyalty.hasRole(COLLECTION_ROLE_HASH, _sender) == false);
        vm.assume(abRoyalty.hasRole(REGISTRY_ROLE_HASH, _sender) == false);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantityA;
        quantities[1] = _quantityB;

        vm.prank(_sender);
        vm.expectRevert();
        abRoyalty.updatePayout1155(address(0), _newHolder, dropIds, quantities);
    }

    function test_updatePayout1155_invalidParameter(
        address _sender,
        address _newHolder,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantityA > 1 && _quantityA < 10_000);
        vm.assume(_quantityB > 1 && _quantityB < 10_000);
        vm.assume(abRoyalty.hasRole(COLLECTION_ROLE_HASH, _sender) == false);
        vm.assume(abRoyalty.hasRole(REGISTRY_ROLE_HASH, _sender) == false);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](3);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantityA;
        quantities[1] = _quantityB;
        quantities[2] = 0;

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.prank(_sender);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abRoyalty.updatePayout1155(address(0), _newHolder, dropIds, quantities);
    }

    function test_distribute_correctRole_notPrepaid(
        address _sender,
        address _holderA,
        address _holderB,
        address _nft,
        uint256 _dropId,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holderA != address(0));
        vm.assume(_holderB != address(0));
        vm.assume(_quantityA > 0 && _quantityA < 10_000);
        vm.assume(_quantityB > 0 && _quantityB < 10_000);

        uint256 publisherBalanceBefore = royaltyToken.balanceOf(publisher);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, _quantityA);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, _quantityB);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), publisherBalanceBefore - 100e18);
    }

    function test_distribute_correctRole_prepaid(
        address _sender,
        address _holderA,
        address _holderB,
        address _nft,
        uint256 _dropId,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holderA != address(0));
        vm.assume(_holderB != address(0));
        vm.assume(_quantityA > 0 && _quantityA < 10_000);
        vm.assume(_quantityB > 0 && _quantityB < 10_000);

        uint256 publisherBalanceBefore = royaltyToken.balanceOf(publisher);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, _quantityA);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, _quantityB);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.transfer(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), publisherBalanceBefore - 100e18);
    }

    function test_distribute_correctRole_prepaid_noFunds(
        address _sender,
        address _holderA,
        address _holderB,
        address _nft,
        uint256 _dropId,
        uint256 _quantityA,
        uint256 _quantityB
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holderA != address(0));
        vm.assume(_holderB != address(0));
        vm.assume(_quantityA > 0 && _quantityA < 10_000);
        vm.assume(_quantityB > 0 && _quantityB < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, _quantityA);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, _quantityB);
        vm.stopPrank();

        vm.prank(publisher);
        vm.expectRevert();
        abRoyalty.distribute(_dropId, 100e18, PREPAID);
    }

    function test_claimPayout(address _sender, address _holder, address _nft, uint256 _dropId, uint256 _quantity)
        public
    {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != publisher);
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holder, _dropId, _quantity);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(_holder), 0);

        vm.prank(_holder);
        abRoyalty.claimPayout(_dropId);

        assertEq(royaltyToken.balanceOf(_holder), 100e18 - (100e18 % (_quantity * UNITS_PRECISION)));
    }

    function test_claimPayouts(
        address _sender,
        address _holder,
        address _nft,
        uint256 _dropId1,
        uint256 _dropId2,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != publisher);
        vm.assume(_holder != _sender);
        vm.assume(_quantity > 0 && _quantity < 10_000);
        vm.assume(_dropId1 < type(uint32).max);
        vm.assume(_dropId2 < type(uint32).max);
        vm.assume(_dropId1 != _dropId2);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId1);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId2);
        abRoyalty.updatePayout721(address(0), _holder, _dropId1, _quantity);
        abRoyalty.updatePayout721(address(0), _holder, _dropId2, _quantity);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 200e18);
        abRoyalty.distribute(_dropId1, 100e18, NOT_PREPAID);
        abRoyalty.distribute(_dropId2, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(_holder), 0);

        uint256[] memory dropIds = new uint256[](2);
        dropIds[0] = _dropId1;
        dropIds[1] = _dropId2;

        vm.prank(_holder);
        abRoyalty.claimPayouts(dropIds);

        assertEq(royaltyToken.balanceOf(_holder), 2 * (100e18 - (100e18 % (_quantity * UNITS_PRECISION))));
    }

    function test_claimPayoutsOnBehalf(
        address _sender,
        address _holder,
        address _nft,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != publisher);
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        abRoyalty.grantRole(AB_ADMIN_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holder, _dropId, _quantity);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(_holder), 0);

        vm.prank(_sender);
        abRoyalty.claimPayoutsOnBehalf(_dropId, _holder);

        assertEq(royaltyToken.balanceOf(_holder), 100e18 - (100e18 % (_quantity * UNITS_PRECISION)));
    }

    function test_claimPayoutsOnMultipleBehalf(
        address _sender,
        address _holderA,
        address _holderB,
        address _nft,
        uint256 _dropId
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holderA != _holderB);
        vm.assume(_holderA != address(0));
        vm.assume(_holderA != publisher);
        vm.assume(_holderB != address(0));
        vm.assume(_holderB != publisher);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        abRoyalty.grantRole(AB_ADMIN_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, 1);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, 1);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(_holderA), 0);
        assertEq(royaltyToken.balanceOf(_holderB), 0);

        address[] memory holders = new address[](2);

        holders[0] = _holderA;
        holders[1] = _holderB;

        vm.prank(_sender);
        abRoyalty.claimPayoutsOnMultipleBehalf(_dropId, holders);

        assertEq(royaltyToken.balanceOf(_holderA), 50e18);
        assertEq(royaltyToken.balanceOf(_holderB), 50e18);
    }

    function test_claimPayouts_multiDrop(
        address _sender,
        address _holder,
        address _nft,
        uint256 _dropId1,
        uint256 _dropId2,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != publisher);
        vm.assume(_quantity > 0 && _quantity < 10_000);
        vm.assume(_dropId1 < type(uint32).max);
        vm.assume(_dropId2 < type(uint32).max);
        vm.assume(_dropId1 != _dropId2);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        abRoyalty.grantRole(AB_ADMIN_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId1);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId2);
        abRoyalty.updatePayout721(address(0), _holder, _dropId1, _quantity);
        abRoyalty.updatePayout721(address(0), _holder, _dropId2, _quantity);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 200e18);
        abRoyalty.distribute(_dropId1, 100e18, NOT_PREPAID);
        abRoyalty.distribute(_dropId2, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(_holder), 0);

        uint256[] memory dropIds = new uint256[](2);
        dropIds[0] = _dropId1;
        dropIds[1] = _dropId2;

        vm.prank(_sender);
        abRoyalty.claimPayoutsOnBehalf(dropIds, _holder);

        assertEq(royaltyToken.balanceOf(_holder), 2 * (100e18 - (100e18 % (_quantity * UNITS_PRECISION))));
    }

    function test_claimPayoutsOnMultipleBehalf_multiDrop(
        address _sender,
        address _holderA,
        address _holderB,
        address _nft,
        uint256 _dropId1,
        uint256 _dropId2
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_holderA != _holderB);
        vm.assume(_holderA != address(0));
        vm.assume(_holderA != publisher);
        vm.assume(_holderB != address(0));
        vm.assume(_holderB != publisher);
        vm.assume(_dropId1 < type(uint32).max);
        vm.assume(_dropId2 < type(uint32).max);
        vm.assume(_dropId1 != _dropId2);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        abRoyalty.grantRole(AB_ADMIN_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId1);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId2);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId1, 1);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId2, 1);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId1, 1);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId2, 1);
        vm.stopPrank();

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 200e18);
        abRoyalty.distribute(_dropId1, 100e18, NOT_PREPAID);
        abRoyalty.distribute(_dropId2, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(_holderA), 0);
        assertEq(royaltyToken.balanceOf(_holderB), 0);

        uint256[] memory dropIds = new uint256[](2);
        dropIds[0] = _dropId1;
        dropIds[1] = _dropId2;

        address[] memory users = new address[](2);
        users[0] = _holderA;
        users[1] = _holderB;

        vm.prank(_sender);
        abRoyalty.claimPayoutsOnMultipleBehalf(dropIds, users);

        assertEq(royaltyToken.balanceOf(_holderA), 100e18);
        assertEq(royaltyToken.balanceOf(_holderB), 100e18);
    }

    function test_getUserSubscription(address _sender, address _user, address _nft, uint256 _dropId, uint256 _quantity)
        public
    {
        vm.assume(_user != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _user, _dropId, _quantity);

        assertEq(abRoyalty.getUserSubscription(_dropId, _user), _quantity * UNITS_PRECISION);
        vm.stopPrank();
    }

    function test_getIndexInfo(address _sender, address _user, address _nft, uint256 _dropId, uint256 _quantity)
        public
    {
        vm.assume(_user != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(_nft, address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _user, _dropId, _quantity);
        vm.stopPrank();

        (uint128 indexValue, uint128 totalUnitsApproved, uint128 totalUnitsPending) = abRoyalty.getIndexInfo(_dropId);

        assertEq(indexValue, 0);
        assertEq(totalUnitsApproved, 0);
        assertEq(totalUnitsPending, _quantity * UNITS_PRECISION);
    }
}
