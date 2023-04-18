// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "../src/ERC721AB.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
import {ABVerifier} from "../src/ABVerifier.sol";
import {ABRoyalty} from "../src/ABRoyalty.sol";
import {ABSuperToken} from "./mocks/ABSuperToken.sol";
import {ERC1155ABTestData} from "./testdata/ERC1155AB.td.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ERC1155ABTest is Test, ERC1155ABTestData, ERC1155Holder {
    address payable public alice;
    address payable public bob;
    address payable public karen;
    address payable public dave;

    address public abSigner;

    /* Contracts */
    ABVerifier public abVerifier;
    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;

    ERC1155AB public nft;

    function setUp() public {
        abSigner = vm.addr(69);

        /* Setup users */
        alice = payable(vm.addr(1));
        bob = payable(vm.addr(2));
        karen = payable(vm.addr(3));
        dave = payable(vm.addr(4));

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(karen, 100 ether);
        vm.deal(dave, 100 ether);

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(karen, "karen");
        vm.label(dave, "dave");

        /* Contracts Deployments */
        erc721Impl = new ERC721AB();
        erc1155Impl = new ERC1155AB();
        royaltyImpl = new ABRoyalty();
        royaltyToken = new ABSuperToken(SF_HOST);
        abVerifier = new ABVerifier(abSigner);

        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");

        anotherCloneFactory = new AnotherCloneFactory(
            address(abVerifier),
            address(erc721Impl),
            address(erc1155Impl),
            address(royaltyImpl)
        );

        anotherCloneFactory.createDrop1155(address(royaltyToken), SALT);

        (address nftContract,) = anotherCloneFactory.drops(0);

        nft = ERC1155AB(nftContract);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        nft.initialize(address(royaltyImpl));
    }

    function test_initDrop_owner() public {
        (uint256 mintedSupply, uint256 maxSupply, uint256 numOfPhase, string memory uri) = nft.tokensDetails(0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 tokenCount = nft.tokenCount();
        assertEq(tokenCount, 0);

        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);

        (mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(0);
        assertEq(mintedSupply, TOKEN_0_MINT_GENESIS);
        assertEq(maxSupply, TOKEN_0_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_0_URI)));

        tokenCount = nft.tokenCount();
        assertEq(tokenCount, 1);
    }

    function test_initDrop_owner_noMintGenesis() public {
        (uint256 mintedSupply, uint256 maxSupply, uint256 numOfPhase, string memory uri) = nft.tokensDetails(0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, 0);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked("")));

        uint256 tokenCount = nft.tokenCount();
        assertEq(tokenCount, 0);

        nft.initDrop(TOKEN_0_SUPPLY, 0, TOKEN_0_URI);

        (mintedSupply, maxSupply, numOfPhase, uri) = nft.tokensDetails(0);
        assertEq(mintedSupply, 0);
        assertEq(maxSupply, TOKEN_0_SUPPLY);
        assertEq(numOfPhase, 0);
        assertEq(keccak256(abi.encodePacked(uri)), keccak256(abi.encodePacked(TOKEN_0_URI)));

        tokenCount = nft.tokenCount();
        assertEq(tokenCount, 1);
    }

    function test_initDrop_owner_mintGenesisGTmaxSupply() public {
        vm.expectRevert(ERC1155AB.InvalidParameter.selector);
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_SUPPLY + 1, TOKEN_0_URI);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);
    }

    function test_setTokenURI_owner() public {
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);

        string memory currentURI = nft.uri(TOKEN_ID_0);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(TOKEN_0_URI)));

        string memory newURI = "http://new-uri.ipfs/";

        nft.setTokenURI(TOKEN_ID_0, newURI);
        currentURI = nft.uri(TOKEN_ID_0);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI)));
    }

    function test_setTokenURI_nonOwner() public {
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.setTokenURI(TOKEN_ID_0, newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);

        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0Price, p0MaxMint, p0MerkleRoot);
        ERC1155AB.Phase memory phase1 = ERC1155AB.Phase(p1Start, p1Price, p1MaxMint, p1MerkleRoot);
        ERC1155AB.Phase memory phase2 = ERC1155AB.Phase(p2Start, p2Price, p2MaxMint, p2MerkleRoot);

        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        nft.setDropPhases(TOKEN_ID_0, phases);

        ERC1155AB.Phase memory p0 = nft.getPhaseInfo(TOKEN_ID_0, 0);
        ERC1155AB.Phase memory p1 = nft.getPhaseInfo(TOKEN_ID_0, 1);
        ERC1155AB.Phase memory p2 = nft.getPhaseInfo(TOKEN_ID_0, 2);

        assertEq(p0.phaseStart, p0Start);
        assertEq(p0.price, p0Price);
        assertEq(p0.maxMint, p0MaxMint);
        assertEq(p0.merkle, p0MerkleRoot);

        assertEq(p1.phaseStart, p1Start);
        assertEq(p1.price, p1Price);
        assertEq(p1.maxMint, p1MaxMint);
        assertEq(p1.merkle, p1MerkleRoot);

        assertEq(p2.phaseStart, p2Start);
        assertEq(p2.price, p2Price);
        assertEq(p2.maxMint, p2MaxMint);
        assertEq(p2.merkle, p2MerkleRoot);
    }

    function test_setDropPhases_owner_onePhase() public {
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0Price, p0MaxMint, p0MerkleRoot);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;

        nft.setDropPhases(TOKEN_ID_0, phases);

        ERC1155AB.Phase memory p0 = nft.getPhaseInfo(TOKEN_ID_0, 0);

        assertEq(p0.phaseStart, p0Start);
        assertEq(p0.price, p0Price);
        assertEq(p0.maxMint, p0MaxMint);
        assertEq(p0.merkle, p0MerkleRoot);
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0Price, p0MaxMint, p0MerkleRoot);
        ERC1155AB.Phase memory phase1 = ERC1155AB.Phase(p1Start, p1Price, p1MaxMint, p1MerkleRoot);

        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.expectRevert(ERC1155AB.InvalidParameter.selector);
        nft.setDropPhases(TOKEN_ID_0, phases);
    }

    function test_setDropPhases_nonOwner() public {
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0Price, p0MaxMint, p0MerkleRoot);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;

        vm.prank(karen);

        vm.expectRevert("Ownable: caller is not the owner");
        nft.setDropPhases(TOKEN_ID_0, phases);
    }

    function test_mint() public {
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0Price, p0MaxMint, p0MerkleRoot);
        ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
        phases[0] = phase0;
        nft.setDropPhases(TOKEN_ID_0, phases);

        // Impersonate `alice`
        vm.prank(alice);

        // Create merkle proof for `alice`
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = aliceP0Proof;

        uint256 qty = 1;

        nft.mint{value: p0Price * qty}(alice, TOKEN_ID_0, PHASE_ID_0, qty, proof);

        assertEq(nft.balanceOf(alice, TOKEN_ID_0), qty);
    }

    // function test_mint_DropSoldOut() public {
    //     // Set block.timestamp to be after the start of Phase 0
    //     vm.warp(p0Start + 1);

    //     // Set the phases
    //     ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, PRICE, 4, p0MerkleRoot);
    //     ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
    //     phases[0] = phase0;
    //     nft.setDropPhases(phases);

    //     uint256 mintQty = 4;

    //     // Create merkle proof for `alice`
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = aliceP0Proof;

    //     vm.prank(alice);
    //     nft.mint{value: PRICE * mintQty}(alice, mintQty, proof);

    //     proof[0] = bobP0Proof;

    //     vm.prank(bob);
    //     vm.expectRevert(ERC1155AB.DropSoldOut.selector);
    //     nft.mint{value: PRICE}(bob, 1, proof);
    // }

    // function test_mint_NotEnoughTokensAvailable() public {
    //     // Set block.timestamp to be after the start of Phase 0
    //     vm.warp(p0Start + 1);

    //     // Set the phases
    //     ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, PRICE, p0MaxMint, p0MerkleRoot);
    //     ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
    //     phases[0] = phase0;
    //     nft.setDropPhases(phases);

    //     uint256 aliceMintQty = 3;

    //     // Create merkle proof for `alice`
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = aliceP0Proof;

    //     vm.prank(alice);
    //     nft.mint{value: PRICE * aliceMintQty}(alice, aliceMintQty, proof);

    //     uint256 bobMintQty = 2;
    //     proof[0] = bobP0Proof;

    //     vm.prank(bob);
    //     vm.expectRevert(ERC1155AB.NotEnoughTokensAvailable.selector);
    //     nft.mint{value: PRICE * bobMintQty}(bob, bobMintQty, proof);
    // }

    // function test_mint_IncorrectETHSent() public {
    //     // Set block.timestamp to be after the start of Phase 0
    //     vm.warp(p0Start + 1);

    //     // Set the phases
    //     ERC1155AB.Phase memory phase0 = ERC1155AB.Phase(p0Start, p0End, PRICE, 10, p0MerkleRoot);
    //     ERC1155AB.Phase[] memory phases = new ERC1155AB.Phase[](1);
    //     phases[0] = phase0;
    //     nft.setDropPhases(phases);

    //     // Impersonate `alice`
    //     vm.prank(alice);

    //     // Create merkle proof for `alice`
    //     bytes32[] memory proof = new bytes32[](1);
    //     proof[0] = aliceP0Proof;

    //     uint256 mintQty = 4;

    //     uint256 tooHighPrice = PRICE * (mintQty + 1);
    //     uint256 tooLowPrice = PRICE * (mintQty - 1);

    //     vm.expectRevert(ERC1155AB.IncorrectETHSent.selector);
    //     nft.mint{value: tooHighPrice}(alice, mintQty, proof);

    //     vm.expectRevert(ERC1155AB.IncorrectETHSent.selector);
    //     nft.mint{value: tooLowPrice}(alice, mintQty, proof);
    // }
}
