// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";

contract ABDataRegistryTest is Test {
    /* Constants */
    uint256 public constant DROP_ID_OFFSET = 100;
    bytes32 public constant COLLECTION_ROLE_HASH = keccak256("COLLECTION_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    /* Contracts */
    ABDataRegistry public abDataRegistry;

    function setUp() public {
        /* Contracts Deployments & Initialization */
        abDataRegistry = new ABDataRegistry(DROP_ID_OFFSET);
        vm.label(address(abDataRegistry), "abDataRegistry");
    }

    function test_registerDrop_correctRole(address _sender, address _publisher, uint256 _tokenId) public {
        abDataRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);

        vm.prank(_sender);
        uint256 allocatedDropId = abDataRegistry.registerDrop(_publisher, _tokenId);

        (uint256 dropId, uint256 tokenId, address publisher, address nft) = abDataRegistry.drops(0);

        assertEq(allocatedDropId, DROP_ID_OFFSET + 1);
        assertEq(dropId, allocatedDropId);
        assertEq(tokenId, _tokenId);
        assertEq(publisher, _publisher);
        assertEq(nft, _sender);
    }

    function test_registerDrop_incorrectRole(address _sender, address _publisher, uint256 _tokenId) public {
        vm.assume(abDataRegistry.hasRole(COLLECTION_ROLE_HASH, _sender) == false);

        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.registerDrop(_publisher, _tokenId);
    }

    function test_registerPublisher_correctRole(address _sender, address _publisher, address _royalty, uint256 _fee)
        public
    {
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        address royalty = abDataRegistry.publishers(_publisher);

        assertEq(royalty, _royalty);
    }

    function test_registerPublisher_incorrectRole(address _sender, address _publisher, address _royalty, uint256 _fee)
        public
    {
        vm.assume(abDataRegistry.hasRole(FACTORY_ROLE_HASH, _sender) == false);
        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);
    }

    function test_grantCollectionRole_correctRole(address _sender, address _collection) public {
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.grantCollectionRole(_collection);

        assertEq(abDataRegistry.hasRole(COLLECTION_ROLE_HASH, _collection), true);
    }

    function test_grantCollectionRole_incorrectRole(address _sender, address _publisher) public {
        vm.assume(abDataRegistry.hasRole(FACTORY_ROLE_HASH, _sender) == false);
        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.grantCollectionRole(_publisher);
    }

    function test_isPublisher(address _publisher, address _nonPublisher, address _royalty, uint256 _fee) public {
        vm.assume(_publisher != _nonPublisher);
        vm.assume(_royalty != address(0));

        abDataRegistry.grantRole(FACTORY_ROLE_HASH, address(this));
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        assertEq(abDataRegistry.isPublisher(_publisher), true);
        assertEq(abDataRegistry.isPublisher(_nonPublisher), false);
    }

    function test_getRoyaltyContract(address _publisher, address _nonPublisher, address _royalty, uint256 _fee)
        public
    {
        vm.assume(_publisher != _nonPublisher);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, address(this));
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        assertEq(abDataRegistry.getRoyaltyContract(_publisher), _royalty);
        assertEq(abDataRegistry.getRoyaltyContract(_nonPublisher), address(0));
    }
}
