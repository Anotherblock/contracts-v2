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
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {ERC1155ABTestData} from "test/_testdata/ERC1155AB.td.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC1155ABTest is Test, ERC1155ABTestData, ERC1155Holder {
    using ECDSA for bytes32;

    /* Admin Profiles */
    uint256 public abSignerPkey = 69;
    address public abSigner;
    address public genesisRecipient;

    /* User Profiles */
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
    ERC721AB public erc721Impl;
    ERC721ABWrapper public erc721WrapperImpl;
    ERC1155AB public erc1155Impl;
    ERC1155ABWrapper public erc1155WrapperImpl;

    ERC1155AB public nft;

    uint256 public constant OPTIMISM_GOERLI_CHAIN_ID = 420;
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

        /* Contracts Deployments & Initialization */
        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");
        vm.label(address(royaltyToken), "royaltyToken");

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

        royaltyImpl = new ABRoyalty();
        vm.label(address(royaltyImpl), "royaltyImpl");

        abDataRegistry = new ABDataRegistry(OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET);
        vm.label(address(abDataRegistry), "abDataRegistry");

        anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry),
            address(abVerifier),
            address(erc721Impl),
            address(erc721WrapperImpl),
            address(erc1155Impl),
            address(erc1155WrapperImpl),
            address(royaltyImpl)
        );
        vm.label(address(anotherCloneFactory), "anotherCloneFactory");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.grantRole(keccak256("FACTORY_ROLE"), address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher);

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
        (uint256 dropId, uint256 mintedSupply, uint256 maxSupply, uint256 numOfPhase, string memory uri) =
            nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 1);

        vm.prank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);
        assertEq(mintedSupply, TOKEN_1_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_1_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 2);
    }

    function test_initDrop_owner_noMintGenesis() public {
        (uint256 dropId, uint256 mintedSupply, uint256 maxSupply, uint256 numOfPhase, string memory uri) =
            nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 1);

        vm.prank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, 0, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_1);
        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);

        assertEq(mintedSupply, 0);
        assertEq(maxSupply, TOKEN_1_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 2);
    }

    function test_initDrop_owner_mintGenesisGTmaxSupply() public {
        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);

        vm.prank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_SUPPLY + 1, genesisRecipient, address(royaltyToken), TOKEN_1_URI);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);
    }

    function test_initDrop_multipleDrops_owner() public {
        (uint256 dropId, uint256 mintedSupply, uint256 maxSupply, uint256 numOfPhase, string memory uri) =
            nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_2);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_3);

        assertEq(dropId, 0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 1);

        vm.prank(publisher);

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);
        assertEq(mintedSupply, TOKEN_1_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_1_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_1_URI)));

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_2);

        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 2);
        assertEq(mintedSupply, TOKEN_2_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_2_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_2_URI)));

        (dropId, mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(TOKEN_ID_3);

        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 3);
        assertEq(mintedSupply, TOKEN_3_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_3_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_3_URI)));

        nextTokenId = nft.nextTokenId();
        assertEq(nextTokenId, 4);
    }

    function test_initDrop_multipleDrops_invalidParameter_supplyLength() public {
        vm.prank(publisher);

        uint256[] memory supplies = new uint256[](2);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }

    function test_initDrop_multipleDrops_invalidParameter_mintGenesisLength() public {
        vm.prank(publisher);

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](2);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }

    function test_initDrop_multipleDrops_invalidParameter_genesisRecipientLength() public {
        vm.prank(publisher);

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](2);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }

    function test_initDrop_multipleDrops_invalidParameter_royaltyTokenLength() public {
        vm.prank(publisher);

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](2);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }

    function test_initDrop_multipleDrops_invalidParameter_uriLength() public {
        vm.prank(publisher);

        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](2);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;

        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }

    function test_initDrop_multipleDrops_nonOwner() public {
        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }

    function test_setTokenURI_owner() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

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
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(bob);
        vm.expectRevert();
        nft.setTokenURI(TOKEN_ID_1, newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase memory phase1 = ERC1155AB.Phase(p1Start, p1End, p1Price, p1MaxMint);
        ERC1155AB.Phase memory phase2 = ERC1155AB.Phase(p2Start, p2End, p2Price, p2MaxMint);

        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        nft.setDropPhases(TOKEN_ID_1, phases);

        ERC1155AB.Phase memory p0 = nft.getPhaseInfo(TOKEN_ID_1, 0);
        ERC1155AB.Phase memory p1 = nft.getPhaseInfo(TOKEN_ID_1, 1);
        ERC1155AB.Phase memory p2 = nft.getPhaseInfo(TOKEN_ID_1, 2);

        assertEq(p0.phaseStart, p0Start);
        assertEq(p0.phaseEnd, p0End);
        assertEq(p0.price, p0Price);
        assertEq(p0.maxMint, p0MaxMint);

        assertEq(p1.phaseStart, p1Start);
        assertEq(p1.phaseEnd, p1End);
        assertEq(p1.price, p1Price);
        assertEq(p1.maxMint, p1MaxMint);

        assertEq(p2.phaseStart, p2Start);
        assertEq(p2.phaseEnd, p2End);
        assertEq(p2.price, p2Price);
        assertEq(p2.maxMint, p2MaxMint);

        vm.stopPrank();
    }

    function test_setDropPhases_owner_onePhase() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;

        nft.setDropPhases(TOKEN_ID_1, phases);

        ERC1155AB.Phase memory p0 = nft.getPhaseInfo(TOKEN_ID_1, 0);

        assertEq(p0.phaseStart, p0Start);
        assertEq(p0.phaseEnd, p0End);
        assertEq(p0.price, p0Price);
        assertEq(p0.maxMint, p0MaxMint);

        vm.stopPrank();
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase memory phase1 = ERC1155AB.Phase(p1Start, p1End, p1Price, p1MaxMint);

        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.expectRevert(ERC1155AB.INVALID_PARAMETER.selector);
        nft.setDropPhases(TOKEN_ID_1, phases);

        vm.stopPrank();
    }

    function test_setDropPhases_nonOwner() public {
        vm.prank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;

        vm.prank(karen);

        vm.expectRevert();
        nft.setDropPhases(TOKEN_ID_1, phases);
    }

    function test_mint() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        uint256 qty = 1;

        // Impersonate `alice`
        vm.prank(alice);

        nft.mint{value: p0Price * qty}(alice, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, qty, signature));

        assertEq(nft.balanceOf(alice, TOKEN_ID_1), qty);
    }

    function test_mint_dropSoldOut() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, 4);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        uint256 mintQty = 4;

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(alice);
        nft.mint{value: p0Price * mintQty}(alice, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, signature));

        signature = _generateBackendSignature(bob, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ERC1155AB.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: p0Price}(bob, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, 1, signature));
    }

    function test_mint_notEnoughTokenAvailable() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(alice);
        nft.mint{value: p0Price * aliceMintQty}(
            alice, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, aliceMintQty, signature)
        );

        uint256 bobMintQty = 2;
        signature = _generateBackendSignature(bob, address(nft), TOKEN_ID_1, PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ERC1155AB.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: p0Price * bobMintQty}(bob, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, bobMintQty, signature));
    }

    function test_mint_incorrectETHSent() public {
        vm.startPrank(publisher);
        nft.initDrop(TOKEN_1_SUPPLY, TOKEN_1_MINT_GENESIS, genesisRecipient, address(royaltyToken), TOKEN_1_URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, 10);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_1, phases);
        vm.stopPrank();

        // Impersonate `alice`
        vm.startPrank(alice);

        // Create signature for `alice` dropId 0, tokenId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0);

        uint256 mintQty = 4;

        uint256 tooHighPrice = p0Price * (mintQty + 1);
        uint256 tooLowPrice = p0Price * (mintQty - 1);

        vm.expectRevert(ERC1155AB.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooHighPrice}(alice, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, signature));

        vm.expectRevert(ERC1155AB.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooLowPrice}(alice, ERC1155AB.MintParams(TOKEN_ID_1, PHASE_ID_0, mintQty, signature));

        vm.stopPrank();
    }

    function test_mintBatch() public {
        _initThreeDrops();

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the same phase for Token ID 1, Token ID 2, Token ID 3
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;

        vm.startPrank(publisher);
        nft.setDropPhases(TOKEN_ID_1, phases);
        nft.setDropPhases(TOKEN_ID_2, phases);
        nft.setDropPhases(TOKEN_ID_3, phases);
        vm.stopPrank();

        uint256 qty = 1;

        ERC1155AB.MintParams[] memory mintParams = new ERC1155AB.MintParams[](3);

        mintParams[0] = ERC1155AB.MintParams(
            TOKEN_ID_1, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0)
        );
        mintParams[1] = ERC1155AB.MintParams(
            TOKEN_ID_2, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_2, PHASE_ID_0)
        );
        mintParams[2] = ERC1155AB.MintParams(
            TOKEN_ID_3, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_3, PHASE_ID_0)
        );

        vm.prank(alice);

        nft.mintBatch{value: p0Price * 3}(alice, mintParams);

        assertEq(nft.balanceOf(alice, TOKEN_ID_1), qty);
        assertEq(nft.balanceOf(alice, TOKEN_ID_2), qty);
        assertEq(nft.balanceOf(alice, TOKEN_ID_3), qty);
    }

    function test_mintBatch_incorrectETHSent() public {
        _initThreeDrops();

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the same phase for Token ID 1, Token ID 2, Token ID 3
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;

        vm.startPrank(publisher);
        nft.setDropPhases(TOKEN_ID_1, phases);
        nft.setDropPhases(TOKEN_ID_2, phases);
        nft.setDropPhases(TOKEN_ID_3, phases);
        vm.stopPrank();

        uint256 qty = 1;

        ERC1155AB.MintParams[] memory mintParams = new ERC1155AB.MintParams[](3);

        mintParams[0] = ERC1155AB.MintParams(
            TOKEN_ID_1, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_1, PHASE_ID_0)
        );
        mintParams[1] = ERC1155AB.MintParams(
            TOKEN_ID_2, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_2, PHASE_ID_0)
        );
        mintParams[2] = ERC1155AB.MintParams(
            TOKEN_ID_3, PHASE_ID_0, qty, _generateBackendSignature(alice, address(nft), TOKEN_ID_3, PHASE_ID_0)
        );

        vm.prank(alice);
        vm.expectRevert(ERC1155AB.INCORRECT_ETH_SENT.selector);
        nft.mintBatch{value: p0Price * 2}(alice, mintParams);
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

    function _initThreeDrops() internal {
        uint256[] memory supplies = new uint256[](3);
        supplies[0] = TOKEN_1_SUPPLY;
        supplies[1] = TOKEN_2_SUPPLY;
        supplies[2] = TOKEN_3_SUPPLY;

        uint256[] memory genesises = new uint256[](3);
        genesises[0] = TOKEN_1_MINT_GENESIS;
        genesises[1] = TOKEN_2_MINT_GENESIS;
        genesises[2] = TOKEN_3_MINT_GENESIS;

        address[] memory genesisRecipients = new address[](3);
        genesisRecipients[0] = genesisRecipient;
        genesisRecipients[1] = genesisRecipient;
        genesisRecipients[2] = genesisRecipient;

        address[] memory royaltyTokens = new address[](3);
        royaltyTokens[0] = address(royaltyToken);
        royaltyTokens[1] = address(royaltyToken);
        royaltyTokens[2] = address(royaltyToken);

        string[] memory uris = new string[](3);
        uris[0] = TOKEN_1_URI;
        uris[1] = TOKEN_2_URI;
        uris[2] = TOKEN_3_URI;

        vm.prank(publisher);
        nft.initDrop(supplies, genesises, genesisRecipients, royaltyTokens, uris);
    }
}
