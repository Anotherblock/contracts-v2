// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721ABBase} from "src/token/ERC721/ERC721ABBase.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {ERC721ABBaseTestData} from "test/_testdata/ERC721ABBase.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ERC721ABBaseTest is Test, ERC721ABBaseTestData {
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
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721ABBase public erc721Impl;
    ERC1155AB public erc1155Impl;

    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public anotherCloneFactoryProxy;

    ERC721ABBase public nft;

    uint256 public constant DROP_ID_OFFSET = 20_000;

    /* Environment Variables */
    string BASE_GOERLI_RPC_URL = vm.envString("BASE_GOERLI_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(BASE_GOERLI_RPC_URL, 5508000));

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

        vm.deal(alice, 10_000 ether);
        vm.deal(bob, 10_000 ether);
        vm.deal(karen, 10_000 ether);
        vm.deal(dave, 10_000 ether);
        vm.deal(publisher, 10_000 ether);

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(karen, "karen");
        vm.label(dave, "dave");
        vm.label(publisher, "publisher");
        vm.label(treasury, "treasury");

        /* Contracts Deployments */

        proxyAdmin = new ProxyAdmin();

        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        vm.label(address(royaltyToken), "royaltyToken");

        abVerifier = new ABVerifier();
        abVerifier.initialize(abSigner);
        vm.label(address(abVerifier), "abVerifier");

        erc1155Impl = new ERC1155AB();
        vm.label(address(erc1155Impl), "erc1155Impl");

        erc721Impl = new ERC721ABBase();
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
            address(royaltyImpl),
            treasury)
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

        nft = ERC721ABBase(nftAddr);
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

        // Impersonate `alice`
        vm.prank(alice);
        nft.mint{value: PRICE}(alice, 1);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mint_phaseNotActive_notStarted(uint256 _timeBeforeSale) public {
        vm.assume(_timeBeforeSale < P0_START);
        vm.assume(_timeBeforeSale > 0);

        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START - _timeBeforeSale);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 4, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        uint256 mintQty = 4;

        vm.prank(alice);
        vm.expectRevert(ABErrors.PHASE_NOT_ACTIVE.selector);
        nft.mint{value: PRICE * mintQty}(alice, mintQty);
    }

    function test_mint_phaseNotActive_finished(uint256 _timeAfterSale) public {
        vm.assume(_timeAfterSale > 0);
        vm.assume(_timeAfterSale < P0_END);

        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_END + _timeAfterSale);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 4, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        uint256 mintQty = 4;

        vm.prank(alice);
        vm.expectRevert(ABErrors.PHASE_NOT_ACTIVE.selector);
        nft.mint{value: PRICE * mintQty}(alice, mintQty);
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

        vm.prank(alice);
        nft.mint{value: PRICE * mintQty}(alice, mintQty);

        vm.prank(bob);
        vm.expectRevert(ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: PRICE}(bob, 1);
    }

    function test_mint_maxMintPerAddress(uint256 _maxMint) public {
        vm.assume(_maxMint > 0);
        vm.assume(_maxMint < SUPPLY);

        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, _maxMint, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.mint{value: PRICE}(alice, 1);

        vm.expectRevert(ABErrors.MAX_MINT_PER_ADDRESS.selector);
        nft.mint{value: PRICE * _maxMint}(alice, _maxMint);

        vm.stopPrank();
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

        vm.prank(alice);
        nft.mint{value: PRICE * aliceMintQty}(alice, aliceMintQty);

        uint256 bobMintQty = 2;

        vm.prank(bob);
        vm.expectRevert(ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: PRICE * bobMintQty}(bob, bobMintQty);
    }

    function test_mint_noPhaseSet() public {
        vm.prank(publisher);
        nft.initDrop(SUPPLY, SHARE_PER_TOKEN, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        uint256 aliceMintQty = 3;

        vm.prank(alice);
        vm.expectRevert();
        nft.mint{value: PRICE * aliceMintQty}(alice, aliceMintQty);
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

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        uint256 tooHighPrice = PRICE * (mintQty + 1);
        uint256 tooLowPrice = PRICE * (mintQty - 1);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooHighPrice}(alice, mintQty);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooLowPrice}(alice, mintQty);

        vm.stopPrank();
    }

    function test_unmintedSupply(uint256 _qtyMint, uint256 _supply) external {
        vm.assume(_supply > 0);
        vm.assume(_qtyMint > 0);
        vm.assume(_supply > _qtyMint);
        vm.assume(_supply < 2000);

        vm.startPrank(publisher);
        nft.initDrop(_supply, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, _qtyMint, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        vm.prank(alice);
        nft.mint{value: PRICE * _qtyMint}(alice, _qtyMint);

        assertEq(nft.unmintedSupply(), _supply - _qtyMint);
    }

    function test_uniqueMinters() external {
        vm.startPrank(publisher);
        nft.initDrop(10, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        vm.prank(alice);
        nft.mint{value: PRICE}(alice, 1);

        assertEq(nft.uniqueMinters(), 1);

        vm.prank(alice);
        nft.mint{value: PRICE}(alice, 1);

        assertEq(nft.uniqueMinters(), 1);

        vm.prank(bob);
        nft.mint{value: PRICE}(bob, 1);

        assertEq(nft.uniqueMinters(), 2);
    }

    function test_canMint() external {
        vm.startPrank(publisher);
        nft.initDrop(10, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, 1, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        assertEq(nft.canMint(alice), true);

        vm.prank(alice);
        nft.mint{value: PRICE}(alice, 1);

        assertEq(nft.canMint(alice), false);
    }

    function test_numberMinted(uint256 _supply, uint256 _mintQty) external {
        vm.assume(_supply > _mintQty);
        vm.assume(_supply < 10_000);
        vm.assume(_supply > 0);
        vm.assume(_mintQty > 0);

        vm.startPrank(publisher);
        nft.initDrop(_supply, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, PRICE, _mintQty + 1, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(phases);
        vm.stopPrank();

        assertEq(nft.numberMinted(alice), 0);

        vm.prank(alice);
        nft.mint{value: PRICE * _mintQty}(alice, _mintQty);

        assertEq(nft.numberMinted(alice), _mintQty);

        nft.mint{value: PRICE}(alice, 1);

        assertEq(nft.numberMinted(alice), _mintQty + 1);
    }
}
