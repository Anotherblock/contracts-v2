// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721ABOE} from "src/token/ERC721/ERC721ABOE.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABKYCModule} from "src/utils/ABKYCModule.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {MockToken} from "test/_mocks/MockToken.sol";
import {ERC721ABOETestData} from "test/_testdata/ERC721ABOE.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ERC721ABOETest is Test, ERC721ABOETestData {
    using ECDSA for bytes32;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    uint256 public kycSignerPkey = 420;
    address public kycSigner;
    address public genesisRecipient;
    address payable public treasury;

    /* Users */
    address payable public alice;
    uint256 public alicePkey = 1;
    address payable public bob;
    uint256 public bobPkey = 2;

    address payable public publisher;

    /* Contracts */
    ABVerifier public abVerifier;
    ABSuperToken public royaltyToken;
    MockToken public mockToken;
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ABKYCModule public abKYCModule;
    ABRoyalty public royaltyImpl;
    ERC721ABOE public erc721Impl;
    ERC721ABOE public erc721OEImpl;
    ERC1155AB public erc1155Impl;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;
    TransparentUpgradeableProxy public abDataRegistryProxy;
    TransparentUpgradeableProxy public abVerifierProxy;
    TransparentUpgradeableProxy public abKYCModuleProxy;

    ERC721ABOE public nft;

    uint256 public constant DROP_ID_OFFSET = 10_000;
    bytes32 public constant DOMAIN_SEPARATOR = 0x02fa7265e7c5d81118673727957699e4d68f74cd74b7db77da710fe8a2c7834f;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    address public constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    /* Environment Variables */
    string BASE_RPC_URL = vm.envString("BASE_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(BASE_RPC_URL));

        /* Setup admins */
        abSigner = vm.addr(abSignerPkey);
        kycSigner = vm.addr(kycSignerPkey);
        genesisRecipient = vm.addr(100);

        /* Setup users */
        alice = payable(vm.addr(alicePkey));
        bob = payable(vm.addr(bobPkey));
        publisher = payable(vm.addr(5));
        treasury = payable(vm.addr(1000));

        vm.deal(alice, 100 ether);
        deal(address(BASE_USDC), alice, 1000e6);
        vm.deal(bob, 100 ether);
        deal(address(BASE_USDC), bob, 1000e6);

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(publisher, "publisher");
        vm.label(treasury, "treasury");

        /* Contracts Deployments */
        proxyAdmin = new ProxyAdmin();

        mockToken = new MockToken(MOCK_TOKEN_NAME, MOCK_TOKEN_SYMBOL);
        vm.label(address(mockToken), "mockToken");
        mockToken.mint(alice, 100e18);
        mockToken.mint(bob, 100e18);

        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        vm.label(address(royaltyToken), "royaltyToken");

        abVerifierProxy = new TransparentUpgradeableProxy(
            address(new ABVerifier()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABVerifier.initialize.selector, abSigner)
        );
        abVerifier = ABVerifier(address(abVerifierProxy));
        vm.label(address(abVerifier), "abVerifier");

        abKYCModuleProxy = new TransparentUpgradeableProxy(
            address(new ABKYCModule()),
            address(proxyAdmin),
            abi.encodeWithSelector(ABKYCModule.initialize.selector, kycSigner)
        );
        abKYCModule = ABKYCModule(address(abKYCModuleProxy));
        vm.label(address(abKYCModule), "abKYCModule");

        erc1155Impl = new ERC1155AB();
        vm.label(address(erc1155Impl), "erc1155Impl");

        erc721Impl = new ERC721ABOE();
        vm.label(address(erc721Impl), "erc721Impl");

        erc721OEImpl = new ERC721ABOE();
        vm.label(address(erc721OEImpl), "erc721OEImpl");

        royaltyImpl = new ABRoyalty();
        vm.label(address(royaltyImpl), "royaltyImpl");

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
                address(erc721Impl),
                address(erc1155Impl),
                address(royaltyImpl)
            )
        );

        anotherCloneFactory = AnotherCloneFactory(address(anotherCloneFactoryProxy));

        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        abVerifier.setDefaultSigner(abSigner);

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        anotherCloneFactory.setABKYCModule(address(abKYCModule));
        anotherCloneFactory.createPublisherProfile(publisher, PUBLISHER_FEE);
        uint256 oeImplementationId = anotherCloneFactory.approveERC721Implementation(address(erc721Impl));

        vm.prank(publisher);
        anotherCloneFactory.createCollection721(oeImplementationId, NAME, SALT);

        (address nftAddr,) = anotherCloneFactory.collections(0);

        nft = ERC721ABOE(nftAddr);
    }

    function test_initialize() public {
        TransparentUpgradeableProxy erc721proxy =
            new TransparentUpgradeableProxy(address(new ERC721ABOE()), address(proxyAdmin), "");

        nft = ERC721ABOE(address(erc721proxy));
        nft.initialize(publisher, address(abDataRegistry), address(abVerifier), address(abKYCModule), NAME);

        assertEq(address(nft.abDataRegistry()), address(abDataRegistry));
        assertEq(address(nft.abVerifier()), address(abVerifier));
        assertEq(nft.publisher(), publisher);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        nft.initialize(address(this), address(abDataRegistry), address(abVerifier), address(abKYCModule), NAME);
    }

    function test_initDrop_owner() public {
        vm.prank(publisher);

        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        uint256 dropId = nft.dropId();
        assertEq(dropId, DROP_ID_OFFSET + 1);

        assertEq(nft.balanceOf(genesisRecipient), MINT_GENESIS);

        string memory currentURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "1")));
    }

    function test_initDrop_noRoyaltyNFT() public {
        vm.prank(publisher);

        nft.initDrop(0, MINT_GENESIS, genesisRecipient, address(0), address(0), URI);

        uint256 dropId = nft.dropId();
        assertEq(dropId, DROP_ID_OFFSET + 1);

        uint256 sharePerToken = nft.sharePerToken();
        assertEq(sharePerToken, 0);

        assertEq(nft.balanceOf(genesisRecipient), MINT_GENESIS);

        string memory currentURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "1")));
    }

    function test_initDrop_alreadyInitialized() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        vm.expectRevert(ABErrors.DROP_ALREADY_INITIALIZED.selector);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);
        vm.stopPrank();
    }

    function test_initDrop_noGenesisMint() public {
        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), address(0), URI);

        assertEq(nft.balanceOf(genesisRecipient), 0);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);
    }

    function test_initDrop_invalidSharePerToken() public {
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        vm.prank(publisher);

        nft.initDrop(0, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);
    }

    function test_initDrop_invalidRoyaltyCurrency() public {
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        vm.prank(publisher);

        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(0), address(0), URI);
    }

    function test_setBaseURI_owner() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        string memory currentURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "1")));

        string memory newURI = "http://new-uri.ipfs/";

        nft.setBaseURI(newURI);
        currentURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI, "1")));

        vm.stopPrank();
    }

    function test_setBaseURI_nonOwner() public {
        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(alice);

        vm.expectRevert();
        nft.setBaseURI(newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 =
            ABDataTypes.Phase(P1_START, P1_END, P1_PRICE_ETH, P1_PRICE_ERC20, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 =
            ABDataTypes.Phase(P2_START, P2_END, P2_PRICE_ETH, P2_PRICE_ERC20, P2_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _START, uint256 _END, uint256 _PRICE_ETH, uint256 _PRICE_ERC20, uint256 _MAX_MINT, bool _PHASE_STATUS)
        = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE_ETH, P0_PRICE_ETH);
        assertEq(_PRICE_ERC20, P0_PRICE_ERC20);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);

        assertEq(_START, P1_START);
        assertEq(_END, P1_END);
        assertEq(_PRICE_ETH, P1_PRICE_ETH);
        assertEq(_PRICE_ERC20, P1_PRICE_ERC20);
        assertEq(_MAX_MINT, P1_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(2);

        assertEq(_START, P2_START);
        assertEq(_END, P2_END);
        assertEq(_PRICE_ETH, P2_PRICE_ETH);
        assertEq(_PRICE_ERC20, P2_PRICE_ERC20);
        assertEq(_MAX_MINT, P2_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);
    }

    function test_setDropPhases_owner_onePhase() public {
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (
            uint256 _P0_START,
            uint256 _P0_END,
            uint256 _P0_PRICE_ETH,
            uint256 _P0_PRICE_ERC20,
            uint256 _P0_MAX_MINT,
            bool _P0_PHASE_STATUS
        ) = nft.phases(0);

        assertEq(_P0_START, P0_START);
        assertEq(_P0_END, P0_END);
        assertEq(_P0_PRICE_ETH, P0_PRICE_ETH);
        assertEq(_P0_PRICE_ERC20, P0_PRICE_ERC20);
        assertEq(_P0_MAX_MINT, P0_MAX_MINT);
        assertEq(_P0_PHASE_STATUS, PRIVATE_PHASE);
    }

    function test_setDropPhases_owner_rewritePhasesManyToOne() public {
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 =
            ABDataTypes.Phase(P1_START, P1_END, P1_PRICE_ETH, P1_PRICE_ERC20, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 =
            ABDataTypes.Phase(P2_START, P2_END, P2_PRICE_ETH, P2_PRICE_ERC20, P2_MAX_MINT, PRIVATE_PHASE);

        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _START, uint256 _END, uint256 _PRICE_ETH, uint256 _PRICE_ERC20, uint256 _MAX_MINT, bool _PHASE_STATUS)
        = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE_ETH, P0_PRICE_ETH);
        assertEq(_PRICE_ERC20, P0_PRICE_ERC20);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);

        assertEq(_START, P1_START);
        assertEq(_END, P1_END);
        assertEq(_PRICE_ETH, P1_PRICE_ETH);
        assertEq(_PRICE_ERC20, P1_PRICE_ERC20);
        assertEq(_MAX_MINT, P1_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(2);

        assertEq(_START, P2_START);
        assertEq(_END, P2_END);
        assertEq(_PRICE_ETH, P2_PRICE_ETH);
        assertEq(_PRICE_ERC20, P2_PRICE_ERC20);
        assertEq(_MAX_MINT, P2_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE_ETH, P0_PRICE_ETH);
        assertEq(_PRICE_ERC20, P0_PRICE_ERC20);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        vm.expectRevert();
        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);
    }

    function test_setDropPhases_owner_rewritePhasesOneToMany() public {
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _START, uint256 _END, uint256 _PRICE_ETH, uint256 _PRICE_ERC20, uint256 _MAX_MINT, bool _PHASE_STATUS)
        = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE_ETH, P0_PRICE_ETH);
        assertEq(_PRICE_ERC20, P0_PRICE_ERC20);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        ABDataTypes.Phase memory phase1 =
            ABDataTypes.Phase(P1_START, P1_END, P1_PRICE_ETH, P1_PRICE_ERC20, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 =
            ABDataTypes.Phase(P2_START, P2_END, P2_PRICE_ETH, P2_PRICE_ERC20, P2_MAX_MINT, PRIVATE_PHASE);

        phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE_ETH, P0_PRICE_ETH);
        assertEq(_PRICE_ERC20, P0_PRICE_ERC20);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);

        assertEq(_START, P1_START);
        assertEq(_END, P1_END);
        assertEq(_PRICE_ETH, P1_PRICE_ETH);
        assertEq(_PRICE_ERC20, P1_PRICE_ERC20);
        assertEq(_MAX_MINT, P1_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE_ETH, _PRICE_ERC20, _MAX_MINT, _PHASE_STATUS) = nft.phases(2);

        assertEq(_START, P2_START);
        assertEq(_END, P2_END);
        assertEq(_PRICE_ETH, P2_PRICE_ETH);
        assertEq(_PRICE_ERC20, P2_PRICE_ERC20);
        assertEq(_MAX_MINT, P2_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 =
            ABDataTypes.Phase(P1_START, P1_END, P1_PRICE_ETH, P1_PRICE_ERC20, P1_MAX_MINT, PRIVATE_PHASE);

        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.prank(publisher);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        nft.setDropPhases(phases);
    }

    function test_setDropPhases_nonOwner() public {
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(bob);

        vm.expectRevert();
        nft.setDropPhases(phases);
    }

    function test_mintWithETH() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.prank(alice);
        nft.mintWithETH{value: P0_PRICE_ETH}(alice, PHASE_ID_0, 1, signature, kycSignature);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mintWithETH_noPhaseSet() public {
        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        vm.prank(alice);
        vm.expectRevert();
        nft.mintWithETH{value: P0_PRICE_ETH * aliceMintQty}(alice, PHASE_ID_0, aliceMintQty, signature, kycSignature);
    }

    function test_mintWithETH_incorrectETHSent() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        uint256 tooHighPrice = P0_PRICE_ETH * (mintQty + 1);
        uint256 tooLowPrice = P0_PRICE_ETH * (mintQty - 1);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mintWithETH{value: tooHighPrice}(alice, PHASE_ID_0, mintQty, signature, kycSignature);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mintWithETH{value: tooLowPrice}(alice, PHASE_ID_0, mintQty, signature, kycSignature);

        vm.stopPrank();
    }

    function test_mintWithETH_phaseNotActive() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        // Set block.timestamp to be before the start of Phase 0
        vm.warp(P0_START - 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        vm.expectRevert(ABErrors.PHASE_NOT_ACTIVE.selector);
        nft.mintWithETH{value: P0_PRICE_ETH * mintQty}(alice, PHASE_ID_0, mintQty, signature, kycSignature);

        vm.stopPrank();
    }

    function test_mintWithETH_notEligible() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        bytes memory invalidSignature = _generateInvalidSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        vm.expectRevert(ABErrors.NOT_ELIGIBLE.selector);
        nft.mintWithETH{value: P0_PRICE_ETH * mintQty}(alice, PHASE_ID_0, mintQty, invalidSignature, kycSignature);

        vm.stopPrank();
    }

    function test_mintWithETH_public() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PUBLIC_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        nft.mintWithETH{value: P0_PRICE_ETH * mintQty}(alice, PHASE_ID_0, mintQty, "", kycSignature);

        assertEq(nft.balanceOf(alice), mintQty);

        vm.stopPrank();
    }

    function test_mintWithERC20() public {
        vm.startPrank(publisher);

        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(BASE_USDC), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.startPrank(alice);
        IERC20(BASE_USDC).approve(address(nft), P0_PRICE_ERC20);
        nft.mintWithERC20(alice, PHASE_ID_0, 1, signature, kycSignature);
        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mintWithERC20_noPhaseSet() public {
        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), BASE_USDC, URI);

        uint256 aliceMintQty = 3;

        // Create signature for `bob` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        vm.startPrank(alice);
        IERC20(BASE_USDC).approve(address(nft), P0_PRICE_ERC20 * aliceMintQty);
        vm.expectRevert();
        nft.mintWithERC20(alice, PHASE_ID_0, aliceMintQty, signature, kycSignature);
        vm.stopPrank();
    }

    function test_mintWithERC20_phaseNotActive() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(BASE_USDC), URI);

        // Set block.timestamp to be before the start of Phase 0
        vm.warp(P0_START - 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        IERC20(BASE_USDC).approve(address(nft), P0_PRICE_ERC20 * mintQty);
        vm.expectRevert(ABErrors.PHASE_NOT_ACTIVE.selector);
        nft.mintWithERC20(alice, PHASE_ID_0, mintQty, signature, kycSignature);

        vm.stopPrank();
    }

    function test_mintWithERC20_notEligible() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(BASE_USDC), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        bytes memory invalidSignature = _generateInvalidSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        IERC20(BASE_USDC).approve(address(nft), P0_PRICE_ERC20 * mintQty);

        vm.expectRevert(ABErrors.NOT_ELIGIBLE.selector);
        nft.mintWithERC20(alice, PHASE_ID_0, mintQty, invalidSignature, kycSignature);

        vm.stopPrank();
    }

    function test_mintWithERC20_public() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(BASE_USDC), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, 10, PUBLIC_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        bytes memory kycSignature = _generateKycSignature(alice, 0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;
        IERC20(BASE_USDC).approve(address(nft), P0_PRICE_ERC20 * mintQty);
        nft.mintWithERC20(alice, PHASE_ID_0, mintQty, "", kycSignature);

        assertEq(nft.balanceOf(alice), mintQty);

        vm.stopPrank();
    }

    function test_mintWithERC20Permit() public {
        vm.startPrank(publisher);

        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), BASE_USDC, URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 =
            ABDataTypes.Phase(P0_START, P0_END, P0_PRICE_ETH, P0_PRICE_ERC20, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);
        bytes memory kycSignature = _generateKycSignature(alice, 0);

        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, alice, address(nft), P0_PRICE_ERC20, 0, 1e18 days));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePkey, digest);

        // Impersonate `alice`
        vm.prank(alice);
        nft.mintWithERC20Permit(alice, PHASE_ID_0, 1, 1e18 days, v, r, s, signature, kycSignature);

        assertEq(nft.balanceOf(alice), 1);
    }

    function test_setSharePerToken_admin(uint256 _newShare) public {
        vm.assume(_newShare != SHARE_PER_TOKEN);
        vm.assume(_newShare < 1_000_000);

        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        assertEq(nft.sharePerToken(), SHARE_PER_TOKEN);

        nft.setSharePerToken(_newShare);

        assertEq(nft.sharePerToken(), _newShare);
        vm.stopPrank();
    }

    function test_setSharePerToken_nonAdmin(address _nonAdmin, uint256 _newShare) public {
        vm.assume(_newShare != SHARE_PER_TOKEN);
        vm.assume(_newShare < 1_000_000);
        vm.assume(_nonAdmin != address(this));
        vm.assume(_nonAdmin != publisher);

        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), URI);

        assertEq(nft.sharePerToken(), SHARE_PER_TOKEN);

        vm.prank(_nonAdmin);
        vm.expectRevert();
        nft.setSharePerToken(_newShare);
    }

    function test_withdrawERC20_admin() public {
        vm.prank(alice);
        mockToken.transfer(address(nft), 10e18);

        assertEq(mockToken.balanceOf(publisher), 0);
        assertEq(mockToken.balanceOf(address(nft)), 10e18);

        vm.prank(publisher);
        nft.withdrawERC20(address(mockToken), 10e18);

        assertEq(mockToken.balanceOf(publisher), 10e18);
        assertEq(mockToken.balanceOf(address(nft)), 0);
    }

    function test_withdrawERC20_nonAdmin(address _nonAdmin) public {
        vm.assume(_nonAdmin != address(this));
        vm.assume(_nonAdmin != publisher);

        vm.prank(alice);
        mockToken.transfer(address(nft), 10e18);

        vm.prank(_nonAdmin);
        vm.expectRevert();
        nft.withdrawERC20(address(mockToken), 10e18);
    }

    function test_withdrawToRightholder(uint256 _amount) public {
        vm.assume(_amount > 10);
        vm.assume(_amount < 1e30);
        vm.deal(address(nft), _amount);

        vm.prank(publisher);
        nft.withdrawToRightholder();

        uint256 expectedPublisherBalance = _amount * PUBLISHER_FEE / 10_000;
        uint256 expectedTreasuryBalance = _amount - expectedPublisherBalance;

        assertEq(treasury.balance, expectedTreasuryBalance);
        assertEq(publisher.balance, expectedPublisherBalance);
    }

    function test_withdrawToRightholder_allToPublisher(uint256 _amount) public {
        vm.assume(_amount > 10);
        vm.assume(_amount < 1e30);
        vm.deal(address(nft), _amount);

        abDataRegistry.setPublisherFee(publisher, 10_000);

        vm.prank(publisher);
        nft.withdrawToRightholder();

        uint256 expectedPublisherBalance = _amount;
        uint256 expectedTreasuryBalance = 0;

        assertEq(treasury.balance, expectedTreasuryBalance);
        assertEq(publisher.balance, expectedPublisherBalance);
    }

    function test_withdrawToRightholder_allToTreasury(uint256 _amount) public {
        vm.assume(_amount > 10);
        vm.assume(_amount < 1e30);
        vm.deal(address(nft), _amount);

        abDataRegistry.setPublisherFee(publisher, 0);

        vm.prank(publisher);
        nft.withdrawToRightholder();

        uint256 expectedPublisherBalance = 0;
        uint256 expectedTreasuryBalance = _amount;

        assertEq(treasury.balance, expectedTreasuryBalance);
        assertEq(publisher.balance, expectedPublisherBalance);
    }

    function test_withdrawToRightholder_invalidParameter(uint256 _amount) public {
        vm.assume(_amount > 10);
        vm.assume(_amount < 1e30);
        vm.deal(address(nft), _amount);

        abDataRegistry.setTreasury(address(0));

        vm.prank(publisher);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        nft.withdrawToRightholder();
    }

    function test_withdrawToRightholder_nonAdmin(address _sender, uint256 _amount) public {
        vm.assume(_amount > 10);
        vm.assume(_amount < 1e30);
        vm.assume(nft.owner() != _sender);

        vm.deal(address(nft), _amount);

        vm.prank(_sender);
        vm.expectRevert();
        nft.withdrawToRightholder();
    }

    function test_symbol_initialized() public {
        vm.startPrank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, 2, genesisRecipient, address(royaltyToken), address(0), URI);

        string memory symbol = nft.symbol();

        assertEq(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("AB10001")), true);
    }

    function test_symbol_notInitialized() public {
        string memory symbol = nft.symbol();

        assertEq(keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("")), true);
    }

    function test_tokenURI_nonUnique() public {
        string memory tokenURI = "metadata.io/";

        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), tokenURI);

        string memory returnedTokenURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(returnedTokenURI)) == keccak256(abi.encodePacked("metadata.io/1")), true);
    }

    function test_tokenURI_unique() public {
        string memory tokenURI = "metadata.io";

        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), tokenURI);

        string memory returnedTokenURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(returnedTokenURI)) == keccak256(abi.encodePacked("metadata.io")), true);
    }

    function test_tokenURI_empty() public {
        string memory tokenURI = "";

        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), address(0), tokenURI);

        string memory returnedTokenURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(returnedTokenURI)) == keccak256(abi.encodePacked("")), true);
    }

    function test_tokenURI_unminted() public {
        string memory tokenURI = "metadata.io/";

        vm.prank(publisher);
        nft.initDrop(SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), address(0), tokenURI);

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        nft.tokenURI(1);
    }

    /* ******************************************************************************************/
    /*                                    UTILITY FUNCTIONS                                     */
    /* ******************************************************************************************/

    function _generateBackendSignature(address _signFor, address _collection, uint256 _phaseId)
        internal
        view
        returns (bytes memory signature)
    {
        // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
        bytes32 msgHash = keccak256(abi.encodePacked(_signFor, _collection, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(abSignerPkey, msgHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _generateKycSignature(address _signFor, uint256 _nonce) internal view returns (bytes memory signature) {
        // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
        bytes32 msgHash = keccak256(abi.encodePacked(_signFor, _nonce)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(kycSignerPkey, msgHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _generateInvalidSignature(address _signFor, address _collection, uint256 _phaseId)
        internal
        pure
        returns (bytes memory signature)
    {
        // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
        bytes32 msgHash = keccak256(abi.encodePacked(_signFor, _collection, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1000, msgHash);
        signature = abi.encodePacked(r, s, v);
    }
}
