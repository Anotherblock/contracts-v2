// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {MockToken} from "test/_mocks/MockToken.sol";
import {ERC721ABTestData} from "test/_testdata/ERC721AB.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ERC721ABTest is Test, ERC721ABTestData {
    using ECDSA for bytes32;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    address public genesisRecipient;
    address payable public treasury;

    /* Users */
    address payable public alice;
    address payable public bob;
    address payable public karen;
    address payable public dave;
    address payable public publisher;

    /* Contracts */
    ABVerifier public abVerifier;
    ABSuperToken public royaltyToken;
    MockToken public mockToken;
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;
    TransparentUpgradeableProxy public abVerifierProxy;

    ERC721AB public nft;

    uint256 public constant DROP_ID_OFFSET = 10_000;

    /* Environment Variables */
    string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(OPTIMISM_RPC_URL));

        /* Setup admins */
        abSigner = vm.addr(abSignerPkey);
        genesisRecipient = vm.addr(100);

        /* Setup users */
        alice = payable(vm.addr(1));
        bob = payable(vm.addr(2));
        karen = payable(vm.addr(3));
        dave = payable(vm.addr(4));
        publisher = payable(vm.addr(5));
        treasury = payable(vm.addr(1000));

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(karen, 100 ether);
        vm.deal(dave, 100 ether);
        vm.deal(publisher, 100 ether);

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(karen, "karen");
        vm.label(dave, "dave");
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

        erc1155Impl = new ERC1155AB();
        vm.label(address(erc1155Impl), "erc1155Impl");

        erc721Impl = new ERC721AB();
        vm.label(address(erc721Impl), "erc721Impl");

        royaltyImpl = new ABRoyalty();
        vm.label(address(royaltyImpl), "royaltyImpl");

        abDataRegistry = new ABDataRegistry();
        abDataRegistry.initialize(DROP_ID_OFFSET, treasury);
        vm.label(address(abDataRegistry), "abDataRegistry");

        anotherCloneFactoryProxy = new TransparentUpgradeableProxy(
            address(new AnotherCloneFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(AnotherCloneFactory.initialize.selector,
                address(abDataRegistry),
                address(abVerifier),
                address(erc721Impl),
                address(erc1155Impl),
                address(royaltyImpl)
            )
        );

        anotherCloneFactory = AnotherCloneFactory(address(anotherCloneFactoryProxy));

        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher, PUBLISHER_FEE);

        vm.prank(publisher);
        anotherCloneFactory.createCollection721(NAME, SALT);

        (address nftAddr,) = anotherCloneFactory.collections(0);

        nft = ERC721AB(nftAddr);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        nft.initialize(address(this), address(abDataRegistry), address(abVerifier), NAME);
    }

    function test_initDrop_owner() public {
        vm.prank(publisher);

        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        uint256 maxSupply = nft.maxSupply();
        assertEq(maxSupply, SUPPLY);

        uint256 dropId = nft.dropId();
        assertEq(dropId, DROP_ID_OFFSET + 1);

        assertEq(nft.balanceOf(genesisRecipient), MINT_GENESIS);

        string memory currentURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "1")));
    }

    function test_initDrop_noRoyaltyNFT() public {
        vm.prank(publisher);

        nft.initDrop(SUPPLY, 0, MINT_GENESIS, genesisRecipient, address(0), URI);

        uint256 maxSupply = nft.maxSupply();
        assertEq(maxSupply, SUPPLY);

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
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        vm.expectRevert(ABErrors.DROP_ALREADY_INITIALIZED.selector);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);
        vm.stopPrank();
    }

    function test_initDrop_noGenesisMint() public {
        vm.prank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), URI);

        uint256 maxSupply = nft.maxSupply();

        assertEq(maxSupply, SUPPLY);
        assertEq(nft.balanceOf(genesisRecipient), 0);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);
    }

    function test_initDrop_supplyToGenesisRatio() public {
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        vm.prank(publisher);

        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, SUPPLY + 1, genesisRecipient, address(royaltyToken), URI);
    }

    function test_initDrop_invalidSharePerToken() public {
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        vm.prank(publisher);

        nft.initDrop(SUPPLY, 0, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);
    }

    function test_initDrop_invalidRoyaltyCurrency() public {
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        vm.prank(publisher);

        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(0), URI);
    }

    function test_setBaseURI_owner() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

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
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(alice);

        vm.expectRevert();
        nft.setBaseURI(newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 = ABDataTypes.Phase(P1_START, P1_END, P1_PRICE, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 = ABDataTypes.Phase(P2_START, P2_END, P2_PRICE, P2_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _P0_START, uint256 _P0_END, uint256 _P0_PRICE, uint256 _P0_MAX_MINT, bool _P0_PHASE_STATUS) =
            nft.phases(0);
        (uint256 _P1_START, uint256 _P1_END, uint256 _P1_PRICE, uint256 _P1_MAX_MINT, bool _P1_PHASE_STATUS) =
            nft.phases(1);
        (uint256 _P2_START, uint256 _P2_END, uint256 _P2_PRICE, uint256 _P2_MAX_MINT, bool _P2_PHASE_STATUS) =
            nft.phases(2);

        assertEq(_P0_START, P0_START);
        assertEq(_P0_END, P0_END);
        assertEq(_P0_PRICE, P0_PRICE);
        assertEq(_P0_MAX_MINT, P0_MAX_MINT);
        assertEq(_P0_PHASE_STATUS, PRIVATE_PHASE);

        assertEq(_P1_START, P1_START);
        assertEq(_P1_END, P1_END);
        assertEq(_P1_PRICE, P1_PRICE);
        assertEq(_P1_MAX_MINT, P1_MAX_MINT);
        assertEq(_P1_PHASE_STATUS, PRIVATE_PHASE);

        assertEq(_P2_START, P2_START);
        assertEq(_P2_END, P2_END);
        assertEq(_P2_PRICE, P2_PRICE);
        assertEq(_P2_MAX_MINT, P2_MAX_MINT);
        assertEq(_P2_PHASE_STATUS, PRIVATE_PHASE);
    }

    function test_setDropPhases_owner_onePhase() public {
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _P0_START, uint256 _P0_END, uint256 _P0_PRICE, uint256 _P0_MAX_MINT, bool _P0_PHASE_STATUS) =
            nft.phases(0);

        assertEq(_P0_START, P0_START);
        assertEq(_P0_END, P0_END);
        assertEq(_P0_PRICE, P0_PRICE);
        assertEq(_P0_MAX_MINT, P0_MAX_MINT);
        assertEq(_P0_PHASE_STATUS, PRIVATE_PHASE);
    }

    function test_setDropPhases_owner_rewritePhasesManyToOne() public {
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 = ABDataTypes.Phase(P1_START, P1_END, P1_PRICE, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 = ABDataTypes.Phase(P2_START, P2_END, P2_PRICE, P2_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _START, uint256 _END, uint256 _PRICE, uint256 _MAX_MINT, bool _PHASE_STATUS) = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE, P0_PRICE);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);

        assertEq(_START, P1_START);
        assertEq(_END, P1_END);
        assertEq(_PRICE, P1_PRICE);
        assertEq(_MAX_MINT, P1_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(2);

        assertEq(_START, P2_START);
        assertEq(_END, P2_END);
        assertEq(_PRICE, P2_PRICE);
        assertEq(_MAX_MINT, P2_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE, P0_PRICE);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        vm.expectRevert();
        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);
    }

    function test_setDropPhases_owner_rewritePhasesOneToMany() public {
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _START, uint256 _END, uint256 _PRICE, uint256 _MAX_MINT, bool _PHASE_STATUS) = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE, P0_PRICE);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        ABDataTypes.Phase memory phase1 = ABDataTypes.Phase(P1_START, P1_END, P1_PRICE, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 = ABDataTypes.Phase(P2_START, P2_END, P2_PRICE, P2_MAX_MINT, PRIVATE_PHASE);
        phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(0);

        assertEq(_START, P0_START);
        assertEq(_END, P0_END);
        assertEq(_PRICE, P0_PRICE);
        assertEq(_MAX_MINT, P0_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(1);

        assertEq(_START, P1_START);
        assertEq(_END, P1_END);
        assertEq(_PRICE, P1_PRICE);
        assertEq(_MAX_MINT, P1_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);

        (_START, _END, _PRICE, _MAX_MINT, _PHASE_STATUS) = nft.phases(2);

        assertEq(_START, P2_START);
        assertEq(_END, P2_END);
        assertEq(_PRICE, P2_PRICE);
        assertEq(_MAX_MINT, P2_MAX_MINT);
        assertEq(_PHASE_STATUS, PRIVATE_PHASE);
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 = ABDataTypes.Phase(P1_START, P1_END, P1_PRICE, P1_MAX_MINT, PRIVATE_PHASE);

        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.prank(publisher);
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        nft.setDropPhases(phases);
    }

    function test_setDropPhases_nonOwner() public {
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(bob);

        vm.expectRevert();
        nft.setDropPhases(phases);
    }

    function test_mint() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        // Impersonate `alice`
        vm.prank(alice);
        nft.mint{value: PRICE}(alice, PHASE_ID_0, 1, signature);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mint_dropSoldOut() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 4, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        uint256 mintQty = 4;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        vm.prank(alice);
        nft.mint{value: PRICE * mintQty}(alice, PHASE_ID_0, mintQty, signature);

        signature = _generateBackendSignature(bob, address(nft), PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: PRICE}(bob, PHASE_ID_0, 1, signature);
    }

    function test_mint_notEnoughTokenAvailable() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        vm.prank(alice);
        nft.mint{value: PRICE * aliceMintQty}(alice, PHASE_ID_0, aliceMintQty, signature);

        uint256 bobMintQty = 2;
        signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: PRICE * bobMintQty}(bob, PHASE_ID_0, bobMintQty, signature);
    }

    function test_mint_noPhaseSet() public {
        vm.prank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        vm.prank(alice);
        vm.expectRevert();
        nft.mint{value: PRICE * aliceMintQty}(alice, PHASE_ID_0, aliceMintQty, signature);
    }

    function test_mint_incorrectETHSent() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        uint256 tooHighPrice = PRICE * (mintQty + 1);
        uint256 tooLowPrice = PRICE * (mintQty - 1);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooHighPrice}(alice, PHASE_ID_0, mintQty, signature);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooLowPrice}(alice, PHASE_ID_0, mintQty, signature);

        vm.stopPrank();
    }

    function test_mint_maxMintPerAddress() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = P0_MAX_MINT + 1;

        vm.expectRevert(ABErrors.MAX_MINT_PER_ADDRESS.selector);
        nft.mint{value: PRICE * mintQty}(alice, PHASE_ID_0, mintQty, signature);

        vm.stopPrank();
    }

    function test_mint_phaseNotActive() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be before the start of Phase 0
        vm.warp(P0_START - 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        vm.expectRevert(ABErrors.PHASE_NOT_ACTIVE.selector);
        nft.mint{value: PRICE * mintQty}(alice, PHASE_ID_0, mintQty, signature);

        vm.stopPrank();
    }

    function test_mint_notEligible() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        bytes memory invalidSignature = _generateInvalidSignature(alice, address(nft), PHASE_ID_0);

        vm.expectRevert(ABErrors.NOT_ELIGIBLE.selector);
        nft.mint{value: PRICE * mintQty}(alice, PHASE_ID_0, mintQty, invalidSignature);

        vm.stopPrank();
    }

    function test_mint_public() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 10, PUBLIC_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);

        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        nft.mint{value: PRICE * mintQty}(alice, PHASE_ID_0, mintQty, "");

        assertEq(nft.balanceOf(alice), mintQty);

        vm.stopPrank();
    }

    function test_setSharePerToken_admin(uint256 _newShare) public {
        vm.assume(_newShare != SHARE_PER_TOKEN);
        vm.assume(_newShare < 1_000_000);

        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

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
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

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

    function test_setMaxSupply_alreadyMinted(uint256 _maxSupply) public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        // Impersonate `alice`
        vm.prank(alice);
        nft.mint{value: PRICE}(alice, PHASE_ID_0, 1, signature);
        assertEq(nft.balanceOf(alice), 1);
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
