// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "../src/ERC721AB.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
import {ABRoyalty} from "../src/ABRoyalty.sol";
import {ABSuperToken} from "./mocks/ABSuperToken.sol";
import {ERC721ABTestData} from "./testdata/ERC721AB.td.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC721ABTest is Test, ERC721ABTestData {
    address payable public alice;
    address payable public bob;
    address payable public karen;
    address payable public dave;

    /* Contracts */
    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;

    ERC721AB public nftWithRoyalty;
    ERC721AB public nftWithoutRoyalty;

    function setUp() public {
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

        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");

        anotherCloneFactory = new AnotherCloneFactory(address(erc721Impl), address(erc1155Impl), address(royaltyImpl));

        anotherCloneFactory.createDrop721(
            NAME, SYMBOL, URI, PRICE, SUPPLY, MINT_GENESIS, true, address(royaltyToken), SALT
        );

        (address nft,) = anotherCloneFactory.drops(0);

        nftWithRoyalty = ERC721AB(nft);

        anotherCloneFactory.createDrop721(
            NAME, SYMBOL, URI, PRICE, SUPPLY, MINT_GENESIS, false, address(royaltyToken), SALT_2
        );

        (nft,) = anotherCloneFactory.drops(1);

        nftWithoutRoyalty = ERC721AB(nft);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        nftWithRoyalty.initialize(address(royaltyImpl), msg.sender, NAME, SYMBOL, URI, PRICE, SUPPLY, MINT_GENESIS);
    }

    function test_setBaseURI_owner() public {
        string memory currentURI = nftWithRoyalty.tokenURI(0);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "0")));

        string memory newURI = "http://new-uri.ipfs/";

        nftWithRoyalty.setBaseURI(newURI);
        currentURI = nftWithRoyalty.tokenURI(0);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI, "0")));
    }

    function test_setBaseURI_nonOwner() public {
        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(address(1));

        vm.expectRevert("Ownable: caller is not the owner");
        nftWithRoyalty.setBaseURI(newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint, 0x0);
        ERC721AB.Phase memory phase1 = ERC721AB.Phase(p1Start, p1End, PRICE, p1MaxMint, 0x0);
        ERC721AB.Phase memory phase2 = ERC721AB.Phase(p2Start, p2End, PRICE, p2MaxMint, 0x0);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        nftWithRoyalty.setDropPhases(phases);

        (uint256 _p0Start, uint256 _p0End, uint256 _p0Price, uint256 _p0MaxMint, bytes32 _p0Merkle) =
            nftWithRoyalty.phases(0);

        (uint256 _p1Start, uint256 _p1End, uint256 _p1Price, uint256 _p1MaxMint, bytes32 _p1Merkle) =
            nftWithRoyalty.phases(1);

        (uint256 _p2Start, uint256 _p2End, uint256 _p2Price, uint256 _p2MaxMint, bytes32 _p2Merkle) =
            nftWithRoyalty.phases(2);

        assertEq(_p0Start, p0Start);
        assertEq(_p0End, p0End);
        assertEq(_p0Price, PRICE);
        assertEq(_p0MaxMint, p0MaxMint);
        assertEq(_p0Merkle, 0x0);

        assertEq(_p1Start, p1Start);
        assertEq(_p1End, p1End);
        assertEq(_p1Price, PRICE);
        assertEq(_p1MaxMint, p1MaxMint);
        assertEq(_p1Merkle, 0x0);

        assertEq(_p2Start, p2Start);
        assertEq(_p2End, p2End);
        assertEq(_p2Price, PRICE);
        assertEq(_p2MaxMint, p2MaxMint);
        assertEq(_p2Merkle, 0x0);
    }

    function test_setDropPhases_owner_onePhase() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint, 0x0);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        nftWithRoyalty.setDropPhases(phases);

        (uint256 _p0Start, uint256 _p0End, uint256 _p0Price, uint256 _p0MaxMint, bytes32 _p0Merkle) =
            nftWithRoyalty.phases(0);

        assertEq(_p0Start, p0Start);
        assertEq(_p0End, p0End);
        assertEq(_p0Price, PRICE);
        assertEq(_p0MaxMint, p0MaxMint);
        assertEq(_p0Merkle, 0x0);
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint, 0x0);
        ERC721AB.Phase memory phase1 = ERC721AB.Phase(p1Start, p1End, PRICE, p1MaxMint, 0x0);

        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.expectRevert(ERC721AB.InvalidParameter.selector);
        nftWithRoyalty.setDropPhases(phases);
    }

    function test_setDropPhases_incorrectPhaseStart() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0End, p0Start, PRICE, p0MaxMint, 0x0);

        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        vm.expectRevert(ERC721AB.InvalidParameter.selector);
        nftWithRoyalty.setDropPhases(phases);
    }

    function test_setDropPhases_nonOwner() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint, 0x0);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        vm.prank(address(1));

        vm.expectRevert("Ownable: caller is not the owner");
        nftWithRoyalty.setDropPhases(phases);
    }

    function test_mint() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint, p0MerkleRoot);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        // Impersonate `alice`
        vm.prank(alice);

        // Create merkle proof for `alice`
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = aliceP0Proof;

        nftWithRoyalty.mint{value: PRICE}(alice, 1, proof);

        assertEq(nftWithRoyalty.balanceOf(alice), 1);
    }

    function test_mint_DropSoldOut() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, 4, p0MerkleRoot);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        uint256 mintQty = 4;

        // Create merkle proof for `alice`
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = aliceP0Proof;

        vm.prank(alice);
        nftWithRoyalty.mint{value: PRICE * mintQty}(alice, mintQty, proof);

        proof[0] = bobP0Proof;

        vm.prank(bob);
        vm.expectRevert(ERC721AB.DropSoldOut.selector);
        nftWithRoyalty.mint{value: PRICE}(bob, 1, proof);
    }

    function test_mint_NotEnoughTokensAvailable() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint, p0MerkleRoot);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        uint256 aliceMintQty = 3;

        // Create merkle proof for `alice`
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = aliceP0Proof;

        vm.prank(alice);
        nftWithRoyalty.mint{value: PRICE * aliceMintQty}(alice, aliceMintQty, proof);

        uint256 bobMintQty = 2;
        proof[0] = bobP0Proof;

        vm.prank(bob);
        vm.expectRevert(ERC721AB.NotEnoughTokensAvailable.selector);
        nftWithRoyalty.mint{value: PRICE * bobMintQty}(bob, bobMintQty, proof);
    }

    function test_mint_IncorrectETHSent() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, 10, p0MerkleRoot);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        // Impersonate `alice`
        vm.prank(alice);

        // Create merkle proof for `alice`
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = aliceP0Proof;

        uint256 mintQty = 4;

        uint256 tooHighPrice = PRICE * (mintQty + 1);
        uint256 tooLowPrice = PRICE * (mintQty - 1);

        vm.expectRevert(ERC721AB.IncorrectETHSent.selector);
        nftWithRoyalty.mint{value: tooHighPrice}(alice, mintQty, proof);

        vm.expectRevert(ERC721AB.IncorrectETHSent.selector);
        nftWithRoyalty.mint{value: tooLowPrice}(alice, mintQty, proof);
    }
}
