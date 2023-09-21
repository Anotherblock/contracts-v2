// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* solhint-disable */
contract ABDataRegistryTest is Test {
    /* Constants */
    uint256 public constant DROP_ID_OFFSET = 100;
    bytes32 public constant COLLECTION_ROLE_HASH = keccak256("COLLECTION_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0;
    address public constant SF_HOST = 0x4C073B3baB6d8826b8C5b229f3cfdC1eC6E47E74;

    /* Addresses */
    address payable public abTreasury;
    address public publisher;

    /* Contracts */
    ABDataRegistry public abDataRegistry;
    ABSuperToken public royaltyToken;
    ABRoyalty public abRoyalty;

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public abRoyaltyProxy;

    /* Environment Variables */
    string public BASE_RPC_URL = vm.envString("BASE_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(BASE_RPC_URL, 1445932));
        abTreasury = payable(vm.addr(1000));
        publisher = payable(vm.addr(2000));

        /* Contracts Deployments & Initialization */
        proxyAdmin = new ProxyAdmin();

        abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABDataRegistry.initialize.selector, DROP_ID_OFFSET, abTreasury)
        );

        abDataRegistry = ABDataRegistry(address(abDataRegistryProxy));
        vm.label(address(abDataRegistry), "abDataRegistry");

        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        vm.label(address(royaltyToken), "royaltyToken");

        abRoyaltyProxy = new TransparentUpgradeableProxy(
            address(new ABRoyalty()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABRoyalty.initialize.selector, publisher, address(abDataRegistry))
        );
        abRoyalty = ABRoyalty(address(abRoyaltyProxy));
        vm.label(address(abRoyalty), "abRoyalty");
    }

    function test_initialize() public {
        abDataRegistryProxy = new TransparentUpgradeableProxy(
            address(new ABDataRegistry()),
            address(proxyAdmin),
            ""
        );

        abDataRegistry = ABDataRegistry(address(abDataRegistryProxy));
        abDataRegistry.initialize(DROP_ID_OFFSET, abTreasury);

        assertEq(abDataRegistry.abTreasury(), abTreasury);
        assertEq(abDataRegistry.hasRole(DEFAULT_ADMIN_ROLE_HASH, address(this)), true);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        abDataRegistry.initialize(DROP_ID_OFFSET, abTreasury);
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

    function test_registerDrop_noRoyaltyDrop(address _sender, uint256 _tokenId, uint256 _fee) public {
        vm.assume(_sender != address(0));
        vm.assume(_sender != address(proxyAdmin));
        abDataRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abDataRegistry.registerPublisher(publisher, address(abRoyalty), _fee);
        uint256 allocatedDropId = abDataRegistry.registerDrop(publisher, address(0), _tokenId);

        (uint256 dropId, uint256 tokenId, address publisherAddr, address nft) = abDataRegistry.drops(0);

        vm.stopPrank();

        assertEq(allocatedDropId, DROP_ID_OFFSET + 1);
        assertEq(dropId, allocatedDropId);
        assertEq(tokenId, _tokenId);
        assertEq(publisherAddr, publisher);
        assertEq(nft, _sender);
    }

    function test_registerDrop_incorrectRole(address _sender, uint256 _tokenId) public {
        vm.assume(_sender != address(proxyAdmin));

        vm.assume(abDataRegistry.hasRole(COLLECTION_ROLE_HASH, _sender) == false);

        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.registerDrop(publisher, address(royaltyToken), _tokenId);
    }

    function test_registerPublisher_correctRole(address _sender, address _publisher, address _royalty, uint256 _fee)
        public
    {
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        address royalty = abDataRegistry.publishers(_publisher);

        assertEq(royalty, _royalty);
    }

    function test_registerPublisher_incorrectRole(address _sender, address _publisher, address _royalty, uint256 _fee)
        public
    {
        vm.assume(_sender != address(proxyAdmin));
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
        vm.assume(_royalty != address(0));
        vm.assume(_sender != address(proxyAdmin));

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
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.grantCollectionRole(_collection);

        assertEq(abDataRegistry.hasRole(COLLECTION_ROLE_HASH, _collection), true);
    }

    function test_grantCollectionRole_incorrectRole(address _sender, address _publisher) public {
        vm.assume(_sender != address(proxyAdmin));
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
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.setTreasury(_newTreasury);

        assertEq(abDataRegistry.abTreasury(), _newTreasury);
    }

    function test_setTreasury_incorrectRole(address _sender, address _newTreasury) public {
        vm.assume(abDataRegistry.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);
        vm.assume(_sender != address(proxyAdmin));

        vm.expectRevert();
        vm.prank(_sender);
        abDataRegistry.setTreasury(_newTreasury);
    }

    function test_getPublisherFee(address _sender, address _publisher, address _royalty, uint256 _fee) public {
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        uint256 fee = abDataRegistry.getPublisherFee(_publisher);

        assertEq(fee, _fee);
    }

    function test_getPayoutDetails(address _sender, address _publisher, address _royalty, uint256 _fee) public {
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _royalty, _fee);

        (address treasury, uint256 fee) = abDataRegistry.getPayoutDetails(_publisher, 0);

        assertEq(fee, _fee);
        assertEq(treasury, abTreasury);
    }

    function test_setPublisherFee_correctRole(address _sender, address _publisher, uint256 _fee) public {
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.setPublisherFee(_publisher, _fee);

        uint256 fee = abDataRegistry.getPublisherFee(_publisher);

        assertEq(fee, _fee);
    }

    function test_updatePublisher_correctRole(
        address _sender,
        address _publisher,
        address _prevRoyalty,
        address _newRoyalty
    ) public {
        vm.assume(_prevRoyalty != address(0));
        vm.assume(_newRoyalty != address(0));
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _prevRoyalty, 10_000);

        assertEq(abDataRegistry.publishers(_publisher), _prevRoyalty);

        vm.prank(_sender);
        abDataRegistry.updatePublisher(_publisher, _newRoyalty);

        assertEq(abDataRegistry.publishers(_publisher), _newRoyalty);
    }

    function test_updatePublisher_incorrectRole(
        address _sender,
        address _publisher,
        address _prevRoyalty,
        address _newRoyalty
    ) public {
        vm.assume(_prevRoyalty != address(0));
        vm.assume(_newRoyalty != address(0));
        vm.assume(abDataRegistry.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) == false);
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _prevRoyalty, 10_000);

        assertEq(abDataRegistry.publishers(_publisher), _prevRoyalty);

        vm.prank(_sender);
        vm.expectRevert();
        abDataRegistry.updatePublisher(_publisher, _newRoyalty);
    }

    function test_updatePublisher_invalidParameter(
        address _sender,
        address _publisher,
        address _prevRoyalty,
        address _newRoyalty
    ) public {
        vm.assume(_prevRoyalty != address(0));
        vm.assume(_newRoyalty != address(0));
        vm.assume(_sender != address(proxyAdmin));

        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.prank(_sender);
        abDataRegistry.registerPublisher(_publisher, _prevRoyalty, 10_000);

        assertEq(abDataRegistry.publishers(_publisher), _prevRoyalty);

        vm.prank(_sender);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abDataRegistry.updatePublisher(_publisher, address(0));
    }

    function test_distributeOnBehalf_correctRole(address _sender, address _holder) public {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != address(abRoyalty));
        vm.assume(_holder != _sender);

        uint256 amount = 100_000e18;
        abDataRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);
        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abDataRegistry.registerPublisher(publisher, address(abRoyalty), 10_000);
        uint256 dropId = abDataRegistry.registerDrop(publisher, address(royaltyToken), 1);
        abDataRegistry.on721TokenTransfer(publisher, address(0), _holder, dropId, 1);
        royaltyToken.mint(address(abRoyalty), amount);
        abDataRegistry.distributeOnBehalf(publisher, dropId, amount);
        vm.stopPrank();

        uint256 claimable = abRoyalty.getClaimableAmount(dropId, _holder);

        assertEq(claimable, amount);
    }

    function test_distributeOnBehalf_incorrectRole(address _sender, address _holder) public {
        vm.assume(_sender != address(0));
        vm.assume(_holder != address(0));
        vm.assume(_holder != address(abRoyalty));
        vm.assume(_holder != _sender);

        uint256 amount = 100_000e18;
        abDataRegistry.grantRole(COLLECTION_ROLE_HASH, _sender);
        abDataRegistry.grantRole(FACTORY_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        abDataRegistry.registerPublisher(publisher, address(abRoyalty), 10_000);
        uint256 dropId = abDataRegistry.registerDrop(publisher, address(royaltyToken), 1);
        abDataRegistry.on721TokenTransfer(publisher, address(0), _holder, dropId, 1);
        royaltyToken.mint(address(abRoyalty), amount);

        vm.expectRevert();
        abDataRegistry.distributeOnBehalf(publisher, dropId, amount);
        vm.stopPrank();
    }

    function test_distributeOnBehalf_invalidParameter(address _sender) public {
        uint256 amount = 100_000e18;
        abDataRegistry.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        abDataRegistry.distributeOnBehalf(publisher, 1, amount);
        vm.stopPrank();
    }
}
