// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {ERC721ABWrapper} from "src/token/ERC721/ERC721ABWrapper.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC1155ABWrapper} from "src/token/ERC1155/ERC1155ABWrapper.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABHolderRegistry} from "src/utils/ABHolderRegistry.sol";

import {ABHolderRegistryTestData} from "test/_testdata/ABHolderRegistry.td.sol";

contract ABHolderRegistryTest is Test, ABHolderRegistryTestData {
    /* Users */
    address payable public publisher;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    address public genesisRecipient;
    address payable public treasury;

    /* Contracts */
    ABHolderRegistry public abHolderRegistryImpl;
    ABVerifier public abVerifier;
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ERC721AB public erc721Impl;
    ERC721ABWrapper public erc721WrapperImpl;
    ERC1155AB public erc1155Impl;
    ERC1155ABWrapper public erc1155WrapperImpl;

    ABHolderRegistry public abHolderRegistry;

    function setUp() public {
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

        abHolderRegistryImpl = new ABHolderRegistry();
        vm.label(address(abHolderRegistryImpl), "abHolderRegistryImpl");

        abDataRegistry = new ABDataRegistry(DROP_ID_OFFSET, treasury);
        vm.label(address(abDataRegistry), "abDataRegistry");

        anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry),
            address(abVerifier),
            address(erc721Impl),
            address(erc721WrapperImpl),
            address(erc1155Impl),
            address(erc1155WrapperImpl),
            address(abHolderRegistryImpl)
        );
        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher, PUBLISHER_FEE);

        address holderRegistryAddr = abDataRegistry.publishers(publisher);

        abHolderRegistry = ABHolderRegistry(holderRegistryAddr);
    }

    function test_initPayoutIndex_correctRole(address _sender, address _placeholder, uint256 _dropId) public {
        vm.assume(_sender != address(0));

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        assertEq(abHolderRegistry.nftPerDropId(_dropId), address(0));

        vm.prank(_sender);
        abHolderRegistry.initPayoutIndex(_placeholder, _dropId);

        assertEq(abHolderRegistry.nftPerDropId(_dropId), _sender);
    }

    function test_initPayoutIndex_incorrectRole(address _sender, address _placeholder, uint256 _dropId) public {
        vm.assume(_sender != address(0));
        vm.assume(abHolderRegistry.hasRole(COLLECTION_ROLE_HASH, _sender) == false);
        vm.prank(_sender);
        vm.expectRevert();
        abHolderRegistry.initPayoutIndex(_placeholder, _dropId);
    }

    function test_updatePayout721_correctRole_minting(
        address _sender,
        address _newHolder,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantity > 0);

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.prank(_sender);
        abHolderRegistry.updatePayout721(address(0), _newHolder, _dropId, _quantity);

        assertEq(abHolderRegistry.userUnitsPerDrop(_newHolder, _dropId), _quantity);
    }

    function test_updatePayout721_correctRole_burning(
        address _sender,
        address _previousHolder,
        uint256 _dropId,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_quantity > 0);

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.startPrank(_sender);

        abHolderRegistry.updatePayout721(address(0), _previousHolder, _dropId, _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, _dropId), _quantity);

        abHolderRegistry.updatePayout721(_previousHolder, address(0), _dropId, _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, _dropId), 0);

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
        vm.assume(_quantity > 0);

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.startPrank(_sender);

        abHolderRegistry.updatePayout721(address(0), _previousHolder, _dropId, _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, _dropId), _quantity);

        abHolderRegistry.updatePayout721(_previousHolder, _newHolder, _dropId, _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, _dropId), 0);
        assertEq(abHolderRegistry.userUnitsPerDrop(_newHolder, _dropId), _quantity);

        vm.stopPrank();
    }

    function test_updatePayout721_incorrectRole(address _sender, address _newHolder, uint256 _dropId, uint256 _quantity)
        public
    {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantity > 0);
        vm.assume(abHolderRegistry.hasRole(COLLECTION_ROLE_HASH, _sender) == false);

        vm.expectRevert();
        abHolderRegistry.updatePayout721(address(0), _newHolder, _dropId, _quantity);
    }

    function test_updatePayout1155_correctRole_minting(address _sender, address _newHolder, uint256 _quantity) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantity > 1);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantity;
        quantities[1] = _quantity / 2;

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.prank(_sender);
        abHolderRegistry.updatePayout1155(address(0), _newHolder, dropIds, quantities);

        assertEq(abHolderRegistry.userUnitsPerDrop(_newHolder, 0), _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_newHolder, 1), _quantity / 2);
    }

    function test_updatePayout1155_correctRole_burning(address _sender, address _previousHolder, uint256 _quantity)
        public
    {
        vm.assume(_sender != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_quantity > 1);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantity;
        quantities[1] = _quantity / 2;

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abHolderRegistry.updatePayout1155(address(0), _previousHolder, dropIds, quantities);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 0), _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 1), _quantity / 2);

        abHolderRegistry.updatePayout1155(_previousHolder, address(0), dropIds, quantities);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 0), 0);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 1), 0);

        vm.stopPrank();
    }

    function test_updatePayout1155_correctRole_transfer(
        address _sender,
        address _newHolder,
        address _previousHolder,
        uint256 _quantity
    ) public {
        vm.assume(_sender != address(0));
        vm.assume(_previousHolder != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_previousHolder != _newHolder);
        vm.assume(_quantity > 1);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantity;
        quantities[1] = _quantity / 2;

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abHolderRegistry.updatePayout1155(address(0), _previousHolder, dropIds, quantities);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 0), _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 1), _quantity / 2);

        abHolderRegistry.updatePayout1155(_previousHolder, _newHolder, dropIds, quantities);
        assertEq(abHolderRegistry.userUnitsPerDrop(_newHolder, 0), _quantity);
        assertEq(abHolderRegistry.userUnitsPerDrop(_newHolder, 1), _quantity / 2);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 0), 0);
        assertEq(abHolderRegistry.userUnitsPerDrop(_previousHolder, 1), 0);

        vm.stopPrank();
    }

    function test_updatePayout1155_incorrectRole(address _sender, address _newHolder, uint256 _quantity) public {
        vm.assume(_sender != address(0));
        vm.assume(_newHolder != address(0));
        vm.assume(_quantity > 1);
        vm.assume(abHolderRegistry.hasRole(COLLECTION_ROLE_HASH, _sender) == false);

        uint256[] memory dropIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);

        dropIds[0] = 0;
        dropIds[1] = 1;
        quantities[0] = _quantity;
        quantities[1] = _quantity / 2;

        vm.prank(_sender);
        vm.expectRevert();
        abHolderRegistry.updatePayout1155(address(0), _newHolder, dropIds, quantities);
    }

    function test_grantCollectionRole_correctRole(address _sender, address _collection) public {
        vm.prank(publisher);
        abHolderRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abHolderRegistry.grantCollectionRole(_collection);

        assertEq(abHolderRegistry.hasRole(COLLECTION_ROLE_HASH, _collection), true);
    }

    function test_grantCollectionRole_incorrectRole(address _sender, address _publisher) public {
        vm.assume(abHolderRegistry.hasRole(FACTORY_ROLE_HASH, _sender) == false);
        vm.expectRevert();
        vm.prank(_sender);
        abHolderRegistry.grantCollectionRole(_publisher);
    }

    function test_getUserSubscription(address _sender, address _user, uint256 _dropId, uint256 _quantity) public {
        vm.assume(_user != address(0));
        vm.assume(_quantity > 0);

        vm.prank(publisher);
        abHolderRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.prank(_sender);
        abHolderRegistry.updatePayout721(address(0), _user, _dropId, _quantity);

        assertEq(abHolderRegistry.getUserSubscription(_user, _dropId), _quantity);
    }
}
