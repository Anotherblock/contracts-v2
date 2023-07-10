// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ABDataRegistryTest is Test {
    /* Constants */
    uint256 public constant DROP_ID_OFFSET = 100;
    bytes32 public constant COLLECTION_ROLE_HASH = keccak256("COLLECTION_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0;
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Addresses */
    address payable public abTreasury;
    address public publisher;

    /* Contracts */
    ABDataRegistry public abDataRegistry;
    ABSuperToken public royaltyToken;
    ABRoyalty public abRoyalty;

    /* Environment Variables */
    string public OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(OPTIMISM_RPC_URL, 10271943));
        abTreasury = payable(vm.addr(1000));
        publisher = payable(vm.addr(2000));

        /* Contracts Deployments & Initialization */
        abDataRegistry = new ABDataRegistry();
        abDataRegistry.initialize(DROP_ID_OFFSET, abTreasury);
        vm.label(address(abDataRegistry), "abDataRegistry");

        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        vm.label(address(royaltyToken), "royaltyToken");

        abRoyalty = new ABRoyalty();
        abRoyalty.initialize(publisher, address(abDataRegistry));
        vm.label(address(abRoyalty), "abRoyalty");
    }

    function test_registerDrop_correctRole(address _sender, uint256 _tokenId, uint256 _fee) public {
        vm.assume(_sender != address(0));
        abDataRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abDataRegistry.registerPublisher(publisher, address(abRoyalty), _fee);
        uint256 allocatedDropId = abDataRegistry.registerDrop(publisher, address(royaltyToken), _tokenId);

        (uint256 dropId, uint256 tokenId, address publisherAddr, address nft) = abDataRegistry.drops(0);

        vm.stopPrank();

        assertEq(allocatedDropId, DROP_ID_OFFSET + 1);
        assertEq(dropId, allocatedDropId);
        assertEq(tokenId, _tokenId);
        assertEq(publisherAddr, publisher);
        assertEq(nft, _sender);
    }

    function test_registerDrop_incorrectRole(address _sender, uint256 _tokenId) public {
        vm.assume(abDataRegistry.hasRole(COLLECTION_ROLE_HASH, _sender) == false);

        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.registerDrop(publisher, address(royaltyToken), _tokenId);
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

    function test_registerPublisher_alreadyPublisher(
        address _sender,
        address _publisher,
        address _royalty,
        uint256 _fee
    ) public {
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        address royalty = abDataRegistry.publishers(_publisher);

        assertEq(royalty, _royalty);

        vm.expectRevert(ABErrors.ACCOUNT_ALREADY_PUBLISHER.selector);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        vm.stopPrank();
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

    function test_setTreasury_correctRole(address _sender, address _newTreasury) public {
        vm.assume(_newTreasury != abDataRegistry.abTreasury());

        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.setTreasury(_newTreasury);

        assertEq(abDataRegistry.abTreasury(), _newTreasury);
    }

    function test_setTreasury_incorrectRole(address _sender, address _newTreasury) public {
        vm.assume(abDataRegistry.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);
        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.setTreasury(_newTreasury);
    }

    function test_getPublisherFee(address _sender, address _publisher, address _royalty, uint256 _fee) public {
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        uint256 fee = abDataRegistry.getPublisherFee(_publisher);

        assertEq(fee, _fee);
    }

    function test_getPayoutDetails(address _sender, address _publisher, address _royalty, uint256 _fee) public {
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        (address treasury, uint256 fee) = abDataRegistry.getPayoutDetails(_publisher);

        assertEq(fee, _fee);
        assertEq(treasury, abTreasury);
    }
}
