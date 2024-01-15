// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721ABLE} from "src/token/ERC721/ERC721ABLE.sol";
import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {AnotherCloneFactoryTestData} from "test/_testdata/AnotherCloneFactory.td.sol";

/* solhint-disable */
contract AnotherCloneFactoryTest is Test, AnotherCloneFactoryTestData {
    /* Contracts */
    ABVerifier public abVerifier;
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImplementation;
    ERC1155AB public erc1155Implementation;
    ERC721ABLE public erc721LEImplementation;
    ERC721ABOE public erc721OEImplementation;

    uint256 public leImplementationId;
    uint256 public oeImplementationId;

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public abVerifierProxy;

    address public treasury;

    uint256 public constant DROP_ID_OFFSET = 100;

    function setUp() public {
        treasury = vm.addr(1000);

        /* Contracts Deployments & Initialization */
        proxyAdmin = new ProxyAdmin();

        abVerifierProxy = new TransparentUpgradeableProxy(
            address(new ABVerifier()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABVerifier.initialize.selector, vm.addr(10))
        );
        abVerifier = ABVerifier(address(abVerifierProxy));
        vm.label(address(abVerifier), "abVerifier");

        erc1155Implementation = new ERC1155AB();
        vm.label(address(erc1155Implementation), "erc1155Implementation");

        erc721LEImplementation = new ERC721ABLE();
        vm.label(address(erc721LEImplementation), "erc721LEImplementation");

        erc721OEImplementation = new ERC721ABOE();
        vm.label(address(erc721OEImplementation), "erc721OEImplementation");

        royaltyImplementation = new ABRoyalty();
        vm.label(address(royaltyImplementation), "royaltyImplementation");

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
            abi.encodeWithSelector(
                AnotherCloneFactory.initialize.selector,
                address(abDataRegistry),
                address(abVerifier),
                address(erc721LEImplementation),
                address(erc1155Implementation),
                address(royaltyImplementation)
            )
        );

        anotherCloneFactory = AnotherCloneFactory(address(anotherCloneFactoryProxy));

        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        // Grant FACTORY_ROLE to AnotherCloneFactory contract
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));
    }

    function test_initialize() public {
        anotherCloneFactoryProxy =
            new TransparentUpgradeableProxy(address(new AnotherCloneFactory()), address(proxyAdmin), "");

        anotherCloneFactory = AnotherCloneFactory(address(anotherCloneFactoryProxy));
        anotherCloneFactory.initialize(
            address(abDataRegistry),
            address(abVerifier),
            address(erc721LEImplementation),
            address(erc1155Implementation),
            address(royaltyImplementation)
        );

        assertEq(address(anotherCloneFactory.abDataRegistry()), address(abDataRegistry));
        assertEq(anotherCloneFactory.erc721Impl(), address(erc721LEImplementation));
        assertEq(anotherCloneFactory.erc1155Impl(), address(erc1155Implementation));
        assertEq(anotherCloneFactory.royaltyImpl(), address(royaltyImplementation));
        assertEq(anotherCloneFactory.hasRole(DEFAULT_ADMIN_ROLE_HASH, address(this)), true);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        anotherCloneFactory.initialize(
            address(abDataRegistry),
            address(abVerifier),
            address(erc721LEImplementation),
            address(erc1155Implementation),
            address(royaltyImplementation)
        );
    }

    function test_createPublisherProfile_admin(address _sender, address _publisher, uint256 _fee) public {
        vm.assume(_fee <= 10_000);
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false && _publisher != address(0));
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, _sender);

        vm.prank(_sender);
        anotherCloneFactory.createPublisherProfile(_publisher, _fee);

        assertEq(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher), true);
    }

    function test_createPublisherProfile_nonAdmin(address _user, address _publisher, uint256 _fee) public {
        vm.assume(_fee <= 10_000);
        vm.assume(anotherCloneFactory.hasRole(AB_ADMIN_ROLE_HASH, _user) == false && _publisher != address(0));
        vm.expectRevert();
        vm.prank(_user);
        anotherCloneFactory.createPublisherProfile(_publisher, _fee);
    }

    function test_createPublisherProfile_invalidParameter(uint256 _fee) public {
        vm.assume(_fee <= 10_000);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        anotherCloneFactory.createPublisherProfile(address(0), _fee);
    }

    function test_createPublisherProfile_invalidFee(address _publisher, uint256 _fee) public {
        vm.assume(_fee > 10_000);
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false && _publisher != address(0));

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        anotherCloneFactory.createPublisherProfile(_publisher, _fee);
    }

    function test_createPublisherProfile_noRoyalty_admin(address _publisher, uint256 _fee) public {
        vm.assume(_fee <= 10_000);
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, vm.addr(50), _fee);

        assertEq(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher), true);
    }

    function test_createPublisherProfile_noRoyalty_nonAdmin(address _user, address _publisher, uint256 _fee) public {
        vm.assume(_fee <= 10_000);
        vm.assume(anotherCloneFactory.hasRole(AB_ADMIN_ROLE_HASH, _user) == false && _publisher != address(0));
        vm.expectRevert();
        vm.prank(_user);
        anotherCloneFactory.createPublisherProfile(_publisher, vm.addr(50), _fee);
    }

    function test_createPublisherProfile_noRoyalty_invalidParameter(uint256 _fee) public {
        vm.assume(_fee <= 10_000);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        anotherCloneFactory.createPublisherProfile(address(0), vm.addr(50), _fee);
    }

    function test_createPublisherProfile_noRoyalty_invalidFee(address _publisher, uint256 _fee) public {
        vm.assume(_fee > 10_000);
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false && _publisher != address(0));

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        anotherCloneFactory.createPublisherProfile(_publisher, vm.addr(50), _fee);
    }

    function test_revokePublisherAccess_admin(address _publisher) public {
        vm.assume(_publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        assertEq(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher), true);

        anotherCloneFactory.revokePublisherAccess(_publisher);

        assertEq(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher), false);
    }

    function test_revokePublisherAccess_nonAdmin(address _user, address _publisher) public {
        vm.assume(anotherCloneFactory.hasRole(AB_ADMIN_ROLE_HASH, _user) == false && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        assertEq(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher), true);

        vm.expectRevert();
        vm.prank(_user);
        anotherCloneFactory.revokePublisherAccess(_publisher);
    }

    function test_createCollection721_publisher_limitedEdition(address _publisher) public {
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false);
        vm.assume(_publisher != address(anotherCloneFactory) && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        leImplementationId = anotherCloneFactory.approveERC721Implementation(address(erc721LEImplementation));

        vm.startPrank(_publisher);

        anotherCloneFactory.createCollection721(leImplementationId, NAME, SALT);
        (address nft, address publisher) = anotherCloneFactory.collections(0);

        assertEq(ERC721ABLE(nft).owner(), _publisher);
        assertEq(ERC721ABLE(nft).IMPLEMENTATION_TYPE(), keccak256("LIMITED_EDITION"));
        assertEq(publisher, _publisher);

        vm.stopPrank();
    }

    function test_createCollection721_publisher_openEdition(address _publisher) public {
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false);
        vm.assume(_publisher != address(anotherCloneFactory) && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        oeImplementationId = anotherCloneFactory.approveERC721Implementation(address(erc721OEImplementation));

        vm.startPrank(_publisher);

        anotherCloneFactory.createCollection721(oeImplementationId, NAME, SALT);
        (address nft, address publisher) = anotherCloneFactory.collections(0);

        assertEq(ERC721ABLE(nft).owner(), _publisher);
        assertEq(ERC721ABLE(nft).IMPLEMENTATION_TYPE(), keccak256("OPEN_EDITION"));
        assertEq(publisher, _publisher);

        vm.stopPrank();
    }

    function test_createCollection721_nonPublisher(address _nonPublisher) public {
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _nonPublisher) == false);
        leImplementationId = anotherCloneFactory.approveERC721Implementation(address(erc721LEImplementation));

        vm.prank(_nonPublisher);
        vm.expectRevert();
        anotherCloneFactory.createCollection721(leImplementationId, NAME, SALT);
    }

    function test_createCollection721FromImplementation_adminRole(address _sender, address _publisher) public {
        vm.assume(_sender != address(0));
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false);
        vm.assume(_publisher != address(anotherCloneFactory) && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);

        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, _sender);

        vm.startPrank(_sender);
        anotherCloneFactory.createCollection721FromImplementation(
            address(erc721LEImplementation), _publisher, NAME, SALT
        );
        (address nft, address publisher) = anotherCloneFactory.collections(0);

        assertEq(ERC721ABLE(nft).owner(), _publisher);
        assertEq(publisher, _publisher);

        vm.stopPrank();
    }

    function test_createCollection721FromImplementation_incorrectPublisher(address _sender, address _publisher)
        public
    {
        vm.assume(_sender != address(0));
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false);
        vm.assume(_publisher != address(anotherCloneFactory) && _publisher != address(0));

        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, _sender);

        vm.expectRevert(ABErrors.ACCOUNT_NOT_PUBLISHER.selector);
        vm.prank(_sender);

        anotherCloneFactory.createCollection721FromImplementation(
            address(erc721LEImplementation), _publisher, NAME, SALT
        );
    }

    function test_createCollection721FromImplementation_nonAdminRole(address _sender, address _publisher) public {
        vm.assume(_sender != address(0));
        vm.assume(anotherCloneFactory.hasRole(AB_ADMIN_ROLE_HASH, _sender) == false);
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false);
        vm.assume(_publisher != address(anotherCloneFactory) && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);

        vm.expectRevert();
        vm.prank(_sender);

        anotherCloneFactory.createCollection721FromImplementation(
            address(erc721LEImplementation), _publisher, NAME, SALT
        );
    }

    function test_createCollection1155_publisher(address _publisher) public {
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false);
        vm.assume(_publisher != address(anotherCloneFactory) && _publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);

        vm.startPrank(_publisher);

        anotherCloneFactory.createCollection1155(SALT);
        (address nft, address publisher) = anotherCloneFactory.collections(0);

        assertEq(ERC1155AB(nft).publisher(), _publisher);
        assertEq(publisher, _publisher);

        vm.stopPrank();
    }

    function test_createCollection1155_nonPublisher(address _nonPublisher) public {
        vm.expectRevert();
        vm.prank(_nonPublisher);

        anotherCloneFactory.createCollection1155(SALT);
    }

    function test_approveERC721Implementation_admin(address _dummyImplementation) public {
        uint256 currentImplId = 0;

        uint256 newImplId = anotherCloneFactory.approveERC721Implementation(_dummyImplementation);

        address impl = anotherCloneFactory.erc721ImplAddresses(currentImplId);

        assertEq(currentImplId, newImplId);
        assertEq(impl, _dummyImplementation);
    }

    function test_approveERC721Implementation_nonAdmin(address _nonAdmin, address _dummyImplementation) public {
        vm.assume(_nonAdmin != address(this));
        vm.assume(_nonAdmin != address(proxyAdmin));

        vm.prank(_nonAdmin);

        vm.expectRevert();
        anotherCloneFactory.approveERC721Implementation(_dummyImplementation);
    }

    function test_updateERC721Implementation_admin(address _dummyImplementation, address _dummyImplementation2)
        public
    {
        uint256 implId = anotherCloneFactory.approveERC721Implementation(_dummyImplementation);

        address impl = anotherCloneFactory.erc721ImplAddresses(implId);
        assertEq(impl, _dummyImplementation);

        anotherCloneFactory.updateERC721Implementation(implId, _dummyImplementation2);

        impl = anotherCloneFactory.erc721ImplAddresses(implId);
        assertEq(impl, _dummyImplementation2);
    }

    function test_updateERC721Implementation_nonAdmin(
        address _nonAdmin,
        address _dummyImplementation,
        address _dummyImplementation2
    ) public {
        vm.assume(_nonAdmin != address(this));
        vm.assume(_nonAdmin != address(proxyAdmin));

        uint256 implId = anotherCloneFactory.approveERC721Implementation(_dummyImplementation);

        address impl = anotherCloneFactory.erc721ImplAddresses(implId);
        assertEq(impl, _dummyImplementation);

        vm.prank(_nonAdmin);

        vm.expectRevert();
        anotherCloneFactory.updateERC721Implementation(implId, _dummyImplementation2);
    }

    function test_setERC721Implementation_admin() public {
        ERC721ABLE newErc721Implementation = new ERC721ABLE();

        assertEq(anotherCloneFactory.erc721Impl(), address(erc721LEImplementation));

        anotherCloneFactory.setERC721Implementation(address(newErc721Implementation));

        assertEq(anotherCloneFactory.erc721Impl(), address(newErc721Implementation));
    }

    function test_setERC721Implementation_nonAdmin(address _nonAdmin) public {
        vm.assume(_nonAdmin != address(this));

        ERC721ABLE newErc721Implementation = new ERC721ABLE();

        vm.prank(_nonAdmin);

        vm.expectRevert();
        anotherCloneFactory.setERC721Implementation(address(newErc721Implementation));
    }

    function test_setERC1155Implementation_admin() public {
        ERC1155AB newErc1155Implementation = new ERC1155AB();

        assertEq(anotherCloneFactory.erc1155Impl(), address(erc1155Implementation));

        anotherCloneFactory.setERC1155Implementation(address(newErc1155Implementation));

        assertEq(anotherCloneFactory.erc1155Impl(), address(newErc1155Implementation));
    }

    function test_setERC1155Implementation_nonAdmin(address _nonAdmin) public {
        vm.assume(_nonAdmin != address(this));

        ERC1155AB newErc1155Implementation = new ERC1155AB();

        vm.prank(_nonAdmin);

        vm.expectRevert();
        anotherCloneFactory.setERC1155Implementation(address(newErc1155Implementation));
    }

    function test_setABRoyaltyImplementation_admin() public {
        ABRoyalty newRoyaltyImplementation = new ABRoyalty();

        assertEq(anotherCloneFactory.royaltyImpl(), address(royaltyImplementation));

        anotherCloneFactory.setABRoyaltyImplementation(address(newRoyaltyImplementation));

        assertEq(anotherCloneFactory.royaltyImpl(), address(newRoyaltyImplementation));
    }

    function test_setABRoyaltyImplementation_nonAdmin(address _nonAdmin) public {
        vm.assume(_nonAdmin != address(this));
        ABRoyalty newRoyaltyImplementation = new ABRoyalty();

        vm.prank(_nonAdmin);

        vm.expectRevert();
        anotherCloneFactory.setABRoyaltyImplementation(address(newRoyaltyImplementation));
    }

    function test_predictERC721Address_limitedEdition(address _publisher, bytes32 _salt) public {
        vm.assume(_publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        leImplementationId = anotherCloneFactory.approveERC721Implementation(address(erc721LEImplementation));

        vm.startPrank(_publisher);

        address predictedAddress = anotherCloneFactory.predictERC721Address(leImplementationId, _salt);
        anotherCloneFactory.createCollection721(leImplementationId, NAME, _salt);
        (address nft,) = anotherCloneFactory.collections(0);

        assertEq(predictedAddress, nft);
    }

    function test_predictERC721Address_openEdition(address _publisher, bytes32 _salt) public {
        vm.assume(_publisher != address(0));

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        oeImplementationId = anotherCloneFactory.approveERC721Implementation(address(erc721OEImplementation));

        vm.startPrank(_publisher);

        address predictedAddress = anotherCloneFactory.predictERC721Address(oeImplementationId, _salt);
        anotherCloneFactory.createCollection721(oeImplementationId, NAME, _salt);
        (address nft,) = anotherCloneFactory.collections(0);

        assertEq(predictedAddress, nft);
    }

    function test_predictERC1155Address(address _publisher, bytes32 _salt) public {
        vm.assume(_publisher != address(0));
        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);

        vm.startPrank(_publisher);

        address predictedAddress = anotherCloneFactory.predictERC1155Address(_salt);
        anotherCloneFactory.createCollection1155(_salt);
        (address nft,) = anotherCloneFactory.collections(0);

        assertEq(predictedAddress, nft);
    }

    function test_predictAddressFromImplementation(address _sender, address _publisher, bytes32 _salt) public {
        vm.assume(_publisher != address(0));
        vm.assume(_sender != address(0));
        vm.assume(_sender != _publisher);

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, _sender);

        address predictedAddress =
            anotherCloneFactory.predictAddressFromImplementation(address(erc721OEImplementation), _salt);

        vm.prank(_sender);
        anotherCloneFactory.createCollection721FromImplementation(
            address(erc721OEImplementation), _publisher, NAME, _salt
        );
        (address nft,) = anotherCloneFactory.collections(0);

        assertEq(predictedAddress, nft);
    }

    function test_hasPublisherRole(address _publisher, address _nonPublisher) public {
        vm.assume(_publisher != _nonPublisher);
        vm.assume(anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _publisher) == false && _publisher != address(0));
        vm.assume(
            anotherCloneFactory.hasRole(PUBLISHER_ROLE_HASH, _nonPublisher) == false && _nonPublisher != address(0)
        );

        anotherCloneFactory.createPublisherProfile(_publisher, PUBLISHER_FEE);

        assertEq(anotherCloneFactory.hasPublisherRole(_publisher), true);
        assertEq(anotherCloneFactory.hasPublisherRole(_nonPublisher), false);
    }
}
