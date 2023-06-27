// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {ERC721ABWrapper} from "src/token/ERC721/ERC721ABWrapper.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC1155ABWrapper} from "src/token/ERC1155/ERC1155ABWrapper.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {ABRoyaltyTestData} from "test/_testdata/ABRoyalty.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    ERC721ABWrapper public erc721WrapperImpl;
    ERC1155AB public erc1155Impl;
    ERC1155ABWrapper public erc1155WrapperImpl;

    ABRoyalty public abRoyalty;

    /* Environment Variables */
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(OPTIMISM_RPC_URL, 10271943));

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
        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        royaltyToken.mint(publisher, 100e18);
        vm.label(address(royaltyToken), "royaltyToken");

        abVerifier = new ABVerifier(abSigner);
        vm.label(address(abVerifier), "abVerifier");

        erc1155Impl = new ERC1155AB();
        vm.label(address(erc1155Impl), "erc1155Impl");

        erc1155WrapperImpl = new ERC1155ABWrapper();
        vm.label(address(erc1155WrapperImpl), "erc1155WrapperImpl");

        erc721Impl = new ERC721AB();
        vm.label(address(erc721Impl), "erc721Impl");

        erc721WrapperImpl = new ERC721ABWrapper();
        vm.label(address(erc721WrapperImpl), "erc721WrapperImpl");

        abRoyaltyImpl = new ABRoyalty();
        vm.label(address(abRoyaltyImpl), "abRoyaltyImpl");

        abDataRegistry = new ABDataRegistry(DROP_ID_OFFSET, treasury);
        vm.label(address(abDataRegistry), "abDataRegistry");

        anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry),
            address(abVerifier),
            address(erc721Impl),
            address(erc721WrapperImpl),
            address(erc1155Impl),
            address(erc1155WrapperImpl),
            address(abRoyaltyImpl)
        );
        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher, PUBLISHER_FEE);

        address abRoyaltyAddr = abDataRegistry.publishers(publisher);

        abRoyalty = ABRoyalty(abRoyaltyAddr);
    }

    function test_initPayoutIndex_correctRole(address _sender, uint256 _dropId) public {
        vm.assume(_sender != address(0));

        vm.prank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);

        assertEq(abRoyalty.nftPerDropId(_dropId), address(0));

        vm.prank(_sender);
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);

        assertEq(abRoyalty.nftPerDropId(_dropId), _sender);
    }

    function test_initPayoutIndex_incorrectRole(address _sender, uint256 _dropId) public {
        vm.assume(_sender != address(0));
        vm.assume(abRoyalty.hasRole(COLLECTION_ROLE_HASH, _sender) == false);
        vm.assume(abRoyalty.hasRole(REGISTRY_ROLE_HASH, _sender) == false);
        vm.prank(_sender);
        vm.expectRevert();
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
    }

    function test_updatePayout721_correctRole_minting(
        address _sender,
        address _newHolder,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _newHolder, _dropId, _quantity);

        assertEq(abRoyalty.getUserSubscription(_dropId, _newHolder), _quantity * UNITS_PRECISION);
        vm.stopPrank();
    }

    function test_updatePayout721_correctRole_burning(
        address _sender,
        address _previousHolder,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);

        abRoyalty.updatePayout721(address(0), _previousHolder, _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), _quantity * UNITS_PRECISION);

        abRoyalty.updatePayout721(_previousHolder, address(0), _dropId, _quantity);
        assertEq(abRoyalty.getUserSubscription(_dropId, _previousHolder), 0);

        vm.stopPrank();
    }

    function test_updatePayout721_correctRole_transfer(
        address _sender,
        address _newHolder,
        address _previousHolder,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);

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
        abRoyalty.initPayoutIndex(address(royaltyToken), dropIds[0]);
        abRoyalty.initPayoutIndex(address(royaltyToken), dropIds[1]);
        abRoyalty.updatePayout1155(address(0), _newHolder, dropIds, quantities);

        assertEq(abRoyalty.getUserSubscription(0, _newHolder), _quantityA * UNITS_PRECISION);
        assertEq(abRoyalty.getUserSubscription(1, _newHolder), _quantityB * UNITS_PRECISION);
        vm.stopPrank();
    }

    function test_updatePayout1155_correctRole_burning(
        address _sender,
        address _previousHolder,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), dropIds[0]);
        abRoyalty.initPayoutIndex(address(royaltyToken), dropIds[1]);
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
        abRoyalty.initPayoutIndex(address(royaltyToken), dropIds[0]);
        abRoyalty.initPayoutIndex(address(royaltyToken), dropIds[1]);
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

    function test_distribute_correctRole_notPrepaid(
        address _sender,
        address _holderA,
        address _holderB,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, _quantityA);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, _quantityB);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), 100e18);

        vm.startPrank(publisher);
        royaltyToken.approve(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, NOT_PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), 0);
    }

    function test_distribute_correctRole_prepaid(
        address _sender,
        address _holderA,
        address _holderB,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, _quantityA);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, _quantityB);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), 100e18);

        vm.startPrank(publisher);
        royaltyToken.transfer(address(abRoyalty), 100e18);
        abRoyalty.distribute(_dropId, 100e18, PREPAID);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), 0);
    }

    function test_distribute_correctRole_prepaid_noFunds(
        address _sender,
        address _holderA,
        address _holderB,
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
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _holderA, _dropId, _quantityA);
        abRoyalty.updatePayout721(address(0), _holderB, _dropId, _quantityB);
        vm.stopPrank();

        assertEq(royaltyToken.balanceOf(publisher), 100e18);

        vm.prank(publisher);
        // royaltyToken.transfer(address(abRoyalty), 100e18);
        vm.expectRevert();
        abRoyalty.distribute(_dropId, 100e18, PREPAID);

        // assertEq(royaltyToken.balanceOf(publisher), 0);
    }

    function test_claimPayout(address _sender, address _holder, uint256 _dropId, uint256 _quantity) public {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != publisher);
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
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

    function test_grantCollectionRole_correctRole(address _sender, address _collection) public {
        vm.prank(publisher);
        abRoyalty.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abRoyalty.grantCollectionRole(_collection);

        assertEq(abRoyalty.hasRole(COLLECTION_ROLE_HASH, _collection), true);
    }

    function test_grantCollectionRole_incorrectRole(address _sender, address _publisher) public {
        vm.assume(abRoyalty.hasRole(FACTORY_ROLE_HASH, _sender) == false);
        vm.expectRevert();
        vm.prank(_sender);
        abRoyalty.grantCollectionRole(_publisher);
    }

    function test_getUserSubscription(address _sender, address _user, uint256 _dropId, uint256 _quantity) public {
        vm.assume(_user != address(0));
        vm.assume(_quantity > 0 && _quantity < 10_000);

        vm.startPrank(publisher);
        abRoyalty.grantRole(COLLECTION_ROLE_HASH, _sender);
        abRoyalty.grantRole(REGISTRY_ROLE_HASH, _sender);
        vm.stopPrank();

        vm.startPrank(_sender);
        abRoyalty.initPayoutIndex(address(royaltyToken), _dropId);
        abRoyalty.updatePayout721(address(0), _user, _dropId, _quantity);

        assertEq(abRoyalty.getUserSubscription(_dropId, _user), _quantity * UNITS_PRECISION);
        vm.stopPrank();
    }
}
