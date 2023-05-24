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
import {ABHolderRegistry} from "src/utils/ABHolderRegistryV2.sol";

import {ABHolderRegistryTestData} from "test/_testdata/ABHolderRegistry.td.sol";

contract ABHolderRegistryTest is Test, ABHolderRegistryTestData {
    /* Users */
    address payable public alice;
    address payable public bob;
    address payable public karen;
    address payable public dave;
    address payable public publisher;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    address public genesisRecipient;

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

        abDataRegistry = new ABDataRegistry(BASE_GOERLI_CHAIN_ID * DROP_ID_OFFSET);
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

        anotherCloneFactory.createPublisherProfile(publisher);

        address holderRegistryAddr = abDataRegistry.publishers(publisher);

        abHolderRegistry = ABHolderRegistry(holderRegistryAddr);
    }

    function test_initPayoutIndex_correctRole(address _placeholder, uint256 _dropId) public {}
    function test_initPayoutIndex_incorrectRole(address _placeholder, uint256 _dropId) public {}

    function test_updatePayout721_correctRole(
        address _previousHolder,
        address _newHolder,
        uint256 _dropId,
        uint256 _quantity
    ) public {}
    function test_updatePayout721_incorrectRole(
        address _previousHolder,
        address _newHolder,
        uint256 _dropId,
        uint256 _quantity
    ) public {}

    function test_updatePayout1155_correctRole(
        address _previousHolder,
        address _newHolder,
        uint256[] calldata _dropIds,
        uint256[] calldata _quantities
    ) public {}
    function test_updatePayout1155_incorrectRole(
        address _previousHolder,
        address _newHolder,
        uint256[] calldata _dropIds,
        uint256[] calldata _quantities
    ) public {}

    function test_grantCollectionRole_correctRole(address _collection) public {}
    function test_grantCollectionRole_incorrectRole(address _collection) public {}

    function test_getUserSubscription(address _user, uint256 _dropId) public {}
}
