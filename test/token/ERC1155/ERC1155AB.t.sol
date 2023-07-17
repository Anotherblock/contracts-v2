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
import {ERC1155ABTestData} from "test/_testdata/ERC1155AB.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ERC1155ABTest is Test, ERC1155ABTestData, ERC1155Holder {
    using ECDSA for bytes32;

    /* Admin Profiles */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    address public genesisRecipient;
    address payable public treasury;

    /* User Profiles */
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

    ERC1155AB public nft;

    uint256 public constant DROP_ID_OFFSET = 10_000;

    /* Environment Variables */
    string BASE_GOERLI_RPC_URL = vm.envString("BASE_GOERLI_RPC");

    function setUp() public {
        vm.selectFork(vm.createFork(BASE_GOERLI_RPC_URL));

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

        /* Contracts Deployments & Initialization */
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
        anotherCloneFactory.createCollection1155(SALT);

        (address nftContract,) = anotherCloneFactory.collections(0);

        nft = ERC1155AB(nftContract);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        nft.initialize(msg.sender, address(abDataRegistry), address(abVerifier));
    }

    function test_initDrop_owner() public {
        (
            uint256 dropId,
            uint256 mintedSupply,
            uint256 maxSupply,
            uint256 numOfPhase,
            uint256 sharePerToken,
            string memory uri
        ) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 1);

        vm.prank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, DROP_ID_OFFSET + 1);
        assertEq(mintedSupply, TOKEN_1_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_1_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, SHARE_PER_TOKEN);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 2);
    }

    function test_initDrop_owner_noMintGenesis() public {
        (
            uint256 dropId,
            uint256 mintedSupply,
            uint256 maxSupply,
            uint256 numOfPhase,
            uint256 sharePerToken,
            string memory uri
        ) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 1);

        vm.prank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY, SHARE_PER_TOKEN, 0, genesisRecipient, address(royaltyToken), TOKEN_1_URI
            )
        );

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_1);
        assertEq(dropId, DROP_ID_OFFSET + 1);

        assertEq(mintedSupply, 0);
        assertEq(maxSupply, TOKEN_1_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, SHARE_PER_TOKEN);

        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 2);
    }

    function test_initDrop_owner_mintGenesisGTmaxSupply() public {
        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);

        vm.prank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_SUPPLY + 1,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );
    }

    function test_initDrop_multipleDrops_owner() public {
        (
            uint256 dropId,
            uint256 mintedSupply,
            uint256 maxSupply,
            uint256 numOfPhase,
            uint256 sharePerToken,
            string memory uri
        ) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_2);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_3);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 1);

        _initThreeDrops();

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, DROP_ID_OFFSET + 1);
        assertEq(mintedSupply, TOKEN_1_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_1_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, SHARE_PER_TOKEN);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_2);

        assertEq(dropId, DROP_ID_OFFSET + 2);
        assertEq(mintedSupply, TOKEN_2_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_2_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, SHARE_PER_TOKEN);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_2_URI)));

        (dropId, mintedSupply, maxSupply, numOfPhase, sharePerToken, uri) = nft.tokensDetails(TOKEN_ID_3);

        assertEq(dropId, DROP_ID_OFFSET + 3);
        assertEq(mintedSupply, TOKEN_3_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_3_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(sharePerToken, SHARE_PER_TOKEN);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_3_URI)));

        nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 4);
    }

    function test_initDrop_multipleDrops_nonOwner() public {
        ABDataTypes.InitDropParams[] memory initDropParams = new ABDataTypes.InitDropParams[](3);

        initDropParams[0] = ABDataTypes.InitDropParams(
            TOKEN_1_SUPPLY, SHARE_PER_TOKEN, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI
        );

        initDropParams[1] = ABDataTypes.InitDropParams(
            TOKEN_2_SUPPLY, SHARE_PER_TOKEN, TOKEN_2_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_2_URI
        );

        initDropParams[2] = ABDataTypes.InitDropParams(
            TOKEN_3_SUPPLY, SHARE_PER_TOKEN, TOKEN_3_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_3_URI
        );

        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(initDropParams);
    }

    function test_setTokenURI_owner() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        string memory currentURI = nft.uri(TOKEN_ID_1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        string memory newURI = "http://new-uri.ipfs/";

        nft.setTokenURI(TOKEN_ID_1, newURI);
        currentURI = nft.uri(TOKEN_ID_1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI)));

        vm.stopPrank();
    }

    function test_setTokenURI_nonOwner() public {
        vm.prank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(bob);
        vm.expectRevert();
        nft.setTokenURI(TOKEN_ID_1, newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 = ABDataTypes.Phase(P1_START, P1_END, P1_PRICE, P1_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase2 = ABDataTypes.Phase(P2_START, P2_END, P2_PRICE, P2_MAX_MINT, PRIVATE_PHASE);

        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        nft.setDropPhases(TOKEN_ID_1, phases);

        ABDataTypes.Phase memory p0 = nft.getPhaseInfo(TOKEN_ID_1, 0);
        ABDataTypes.Phase memory p1 = nft.getPhaseInfo(TOKEN_ID_1, 1);
        ABDataTypes.Phase memory p2 = nft.getPhaseInfo(TOKEN_ID_1, 2);

        assertEq(p0.phaseStart, P0_START);
        assertEq(p0.phaseEnd, P0_END);
        assertEq(p0.price, P0_PRICE);
        assertEq(p0.maxMint, P0_MAX_MINT);
        assertEq(p0.isPublic, PRIVATE_PHASE);

        assertEq(p1.phaseStart, P1_START);
        assertEq(p1.phaseEnd, P1_END);
        assertEq(p1.price, P1_PRICE);
        assertEq(p1.maxMint, P1_MAX_MINT);
        assertEq(p1.isPublic, PRIVATE_PHASE);

        assertEq(p2.phaseStart, P2_START);
        assertEq(p2.phaseEnd, P2_END);
        assertEq(p2.price, P2_PRICE);
        assertEq(p2.maxMint, P2_MAX_MINT);
        assertEq(p2.isPublic, PRIVATE_PHASE);

        vm.stopPrank();
    }

    function test_setDropPhases_owner_onePhase() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        nft.setDropPhases(TOKEN_ID_1, phases);

        ABDataTypes.Phase memory p0 = nft.getPhaseInfo(TOKEN_ID_1, 0);

        assertEq(p0.phaseStart, P0_START);
        assertEq(p0.phaseEnd, P0_END);
        assertEq(p0.price, P0_PRICE);
        assertEq(p0.maxMint, P0_MAX_MINT);
        assertEq(p0.isPublic, PRIVATE_PHASE);

        vm.stopPrank();
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase memory phase1 = ABDataTypes.Phase(P1_START, P1_END, P1_PRICE, P1_MAX_MINT, PRIVATE_PHASE);

        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.expectRevert(ABErrors.INVALID_PARAMETER.selector);
        nft.setDropPhases(TOKEN_ID_1, phases);

        vm.stopPrank();
    }

    function test_setDropPhases_nonOwner() public {
        vm.prank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.prank(karen);

        vm.expectRevert();
        nft.setDropPhases(TOKEN_ID_1, phases);
    }

    function test_mint() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        uint256 qty = 1;

        // Impersonate `alice`
        vm.prank(alice);

        nft.mint{value: P0_PRICE * qty}(alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, qty, signature));

        assertEq(nft.balanceOf(alice, TOKEN_ID_1), qty);
    }

    function test_mint_dropSoldOut() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, 4, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        uint256 mintQty = 4;

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(alice);
        nft.mint{value: P0_PRICE * mintQty}(alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, signature));

        signature = _generateBackendSignature(bob, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: P0_PRICE}(bob, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, 1, signature));
    }

    function test_mint_notEnoughTokenAvailable() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(alice);
        nft.mint{value: P0_PRICE * aliceMintQty}(
            alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, aliceMintQty, signature)
        );

        uint256 bobMintQty = 2;
        signature = _generateBackendSignature(bob, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: P0_PRICE * bobMintQty}(
            bob, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, bobMintQty, signature)
        );
    }

    function test_mint_incorrectETHSent() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        uint256 mintQty = 4;

        uint256 tooHighPrice = P0_PRICE * (mintQty + 1);
        uint256 tooLowPrice = P0_PRICE * (mintQty - 1);

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooHighPrice}(alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, signature));

        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooLowPrice}(alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, signature));

        vm.stopPrank();
    }

    function test_mint_notEligible() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, 10, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory invalidSignature = _generateInvalidSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        uint256 mintQty = 4;

        vm.expectRevert(ABErrors.NOT_ELIGIBLE.selector);
        nft.mint{value: P0_PRICE * mintQty}(
            alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, invalidSignature)
        );

        vm.stopPrank();
    }

    function test_mint_publicPhase() public {
        vm.startPrank(publisher);
        nft.initDrop(
            ABDataTypes.InitDropParams(
                TOKEN_1_SUPPLY,
                SHARE_PER_TOKEN,
                TOKEN_1_MINT_GENESIS,
                genesisRecipient,
                address(royaltyToken),
                TOKEN_1_URI
            )
        );

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the phases
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, 10, PUBLIC_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        nft.mint{value: P0_PRICE * mintQty}(alice, ABDataTypes.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, ""));
        assertEq(nft.balanceOf(alice, TOKEN_ID_1), mintQty);

        vm.stopPrank();
    }

    function test_mintBatch() public {
        _initThreeDrops();

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the same phase for Token ID 1, Token ID 2, Token ID 3
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.startPrank(publisher);
        nft.setDropPhases(TOKEN_ID_1, phases);
        nft.setDropPhases(TOKEN_ID_2, phases);
        nft.setDropPhases(TOKEN_ID_3, phases);
        vm.stopPrank();

        uint256 qty = 1;

        ABDataTypes.MintParams[] memory mintParams = new ABDataTypes.MintParams[](3);

        mintParams[0] = ABDataTypes.MintParams(
            TOKEN_ID_1, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0)
        );
        mintParams[1] = ABDataTypes.MintParams(
            TOKEN_ID_2, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_2, PHASE_ID_0)
        );
        mintParams[2] = ABDataTypes.MintParams(
            TOKEN_ID_3, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_3, PHASE_ID_0)
        );

        vm.prank(alice);

        nft.mintBatch{value: P0_PRICE * 3}(alice, mintParams);

        assertEq(nft.balanceOf(alice, TOKEN_ID_1), qty);
        assertEq(nft.balanceOf(alice, TOKEN_ID_2), qty);
        assertEq(nft.balanceOf(alice, TOKEN_ID_3), qty);
    }

    function test_mintBatch_incorrectETHSent() public {
        _initThreeDrops();

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(P0_START + 1);

        // Set the same phase for Token ID 1, Token ID 2, Token ID 3
        ABDataTypes.Phase memory phase0 = ABDataTypes.Phase(P0_START, P0_END, P0_PRICE, P0_MAX_MINT, PRIVATE_PHASE);
        ABDataTypes.Phase[] memory phases = new ABDataTypes.Phase[](1);
        phases[0] = phase0;

        vm.startPrank(publisher);
        nft.setDropPhases(TOKEN_ID_1, phases);
        nft.setDropPhases(TOKEN_ID_2, phases);
        nft.setDropPhases(TOKEN_ID_3, phases);
        vm.stopPrank();

        uint256 qty = 1;

        ABDataTypes.MintParams[] memory mintParams = new ABDataTypes.MintParams[](3);

        mintParams[0] = ABDataTypes.MintParams(
            TOKEN_ID_1, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0)
        );
        mintParams[1] = ABDataTypes.MintParams(
            TOKEN_ID_2, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_2, PHASE_ID_0)
        );
        mintParams[2] = ABDataTypes.MintParams(
            TOKEN_ID_3, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_3, PHASE_ID_0)
        );

        vm.prank(alice);
        vm.expectRevert(ABErrors.INCORRECT_ETH_SENT.selector);
        nft.mintBatch{value: P0_PRICE * 2}(alice, mintParams);
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

    /* ******************************************************************************************/
    /*                                    UTILITY FUNCTIONS                                     */
    /* ******************************************************************************************/

    function _generateBackendSignature(address _signFor, address _collection, uint256 _tokenId, uint256 _phaseId)
        internal
        view
        returns (bytes memory signature)
    {
        // Create signature for user `signFor` for drop ID `_dropId`, token ID `_tokenId` and phase ID `_phaseId`
        bytes32 msgHash =
            keccak256(abi.encodePacked(_signFor, _collection, _tokenId, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(abSignerPkey, msgHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _generateInvalidSignature(address _signFor, address _collection, uint256 _tokenId, uint256 _phaseId)
        internal
        pure
        returns (bytes memory signature)
    {
        // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
        bytes32 msgHash =
            keccak256(abi.encodePacked(_signFor, _collection, _tokenId, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1000, msgHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _initThreeDrops() internal {
        ABDataTypes.InitDropParams[] memory initDropParams = new ABDataTypes.InitDropParams[](3);

        initDropParams[0] = ABDataTypes.InitDropParams(
            TOKEN_1_SUPPLY, SHARE_PER_TOKEN, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI
        );

        initDropParams[1] = ABDataTypes.InitDropParams(
            TOKEN_2_SUPPLY, SHARE_PER_TOKEN, TOKEN_2_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_2_URI
        );

        initDropParams[2] = ABDataTypes.InitDropParams(
            TOKEN_3_SUPPLY, SHARE_PER_TOKEN, TOKEN_3_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_3_URI
        );

        vm.prank(publisher);
        nft.initDrop(initDropParams);
    }
}
