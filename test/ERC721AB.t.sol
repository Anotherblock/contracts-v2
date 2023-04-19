// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "../src/ERC721AB.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
import {ABVerifier} from "../src/ABVerifier.sol";
import {ABRoyalty} from "../src/ABRoyalty.sol";
import {ABSuperToken} from "./mocks/ABSuperToken.sol";
import {ERC721ABTestData} from "./testdata/ERC721AB.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC721ABTest is Test, ERC721ABTestData {
    using ECDSA for bytes32;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;

    /* Users */
    address payable public alice;
    address payable public bob;
    address payable public karen;
    address payable public dave;

    /* Contracts */
    ABVerifier public abVerifier;
    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;

    ERC721AB public nftWithRoyalty;
    ERC721AB public nftWithoutRoyalty;

    function setUp() public {
        /* Setup admins */
        abSigner = vm.addr(abSignerPkey);

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
        nftWithRoyalty.initialize(
            address(royaltyImpl), msg.sender, address(abVerifier), NAME, SYMBOL, URI, PRICE, SUPPLY, MINT_GENESIS
        );
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
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0Price, p0MaxMint);
        ERC721AB.Phase memory phase1 = ERC721AB.Phase(p1Start, p1Price, p1MaxMint);
        ERC721AB.Phase memory phase2 = ERC721AB.Phase(p2Start, p2Price, p2MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        nftWithRoyalty.setDropPhases(phases);

        (uint256 _p0Start, uint256 _p0Price, uint256 _p0MaxMint) = nftWithRoyalty.phases(0);

        (uint256 _p1Start, uint256 _p1Price, uint256 _p1MaxMint) = nftWithRoyalty.phases(1);

        (uint256 _p2Start, uint256 _p2Price, uint256 _p2MaxMint) = nftWithRoyalty.phases(2);

        assertEq(_p0Start, p0Start);
        assertEq(_p0Price, p0Price);
        assertEq(_p0MaxMint, p0MaxMint);

        assertEq(_p1Start, p1Start);
        assertEq(_p1Price, p1Price);
        assertEq(_p1MaxMint, p1MaxMint);

        assertEq(_p2Start, p2Start);
        assertEq(_p2Price, p2Price);
        assertEq(_p2MaxMint, p2MaxMint);
    }

    function test_setDropPhases_owner_onePhase() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0Price, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        nftWithRoyalty.setDropPhases(phases);

        (uint256 _p0Start, uint256 _p0Price, uint256 _p0MaxMint) = nftWithRoyalty.phases(0);

        assertEq(_p0Start, p0Start);
        assertEq(_p0Price, p0Price);
        assertEq(_p0MaxMint, p0MaxMint);
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0Price, p0MaxMint);
        ERC721AB.Phase memory phase1 = ERC721AB.Phase(p1Start, p1Price, p1MaxMint);

        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.expectRevert(ERC721AB.InvalidParameter.selector);
        nftWithRoyalty.setDropPhases(phases);
    }

    function test_setDropPhases_nonOwner() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0Price, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        vm.prank(bob);

        vm.expectRevert("Ownable: caller is not the owner");
        nftWithRoyalty.setDropPhases(phases);
    }

    function test_mint() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, PRICE, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        uint256 dropId = 0;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, dropId, PHASE_ID_0);

        // Impersonate `alice`
        vm.prank(alice);
        nftWithRoyalty.mint{value: PRICE}(alice, PHASE_ID_0, 1, signature);
        assertEq(nftWithRoyalty.balanceOf(alice), 1);
    }

    function test_mint_DropSoldOut() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, PRICE, 4);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        uint256 dropId = 0;
        uint256 mintQty = 4;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, dropId, PHASE_ID_0);

        vm.prank(alice);
        nftWithRoyalty.mint{value: PRICE * mintQty}(alice, PHASE_ID_0, mintQty, signature);

        signature = _generateBackendSignature(bob, dropId, PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ERC721AB.DropSoldOut.selector);
        nftWithRoyalty.mint{value: PRICE}(bob, PHASE_ID_0, 1, signature);
    }

    function test_mint_NotEnoughTokensAvailable() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, PRICE, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        uint256 dropId = 0;
        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, dropId, PHASE_ID_0);

        vm.prank(alice);
        nftWithRoyalty.mint{value: PRICE * aliceMintQty}(alice, PHASE_ID_0, aliceMintQty, signature);

        uint256 bobMintQty = 2;
        signature = _generateBackendSignature(alice, dropId, PHASE_ID_0);

        vm.prank(bob);
        vm.expectRevert(ERC721AB.NotEnoughTokensAvailable.selector);
        nftWithRoyalty.mint{value: PRICE * bobMintQty}(bob, PHASE_ID_0, bobMintQty, signature);
    }

    function test_mint_IncorrectETHSent() public {
        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, PRICE, 10);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;
        nftWithRoyalty.setDropPhases(phases);

        uint256 dropId = 0;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, dropId, PHASE_ID_0);

        // Impersonate `alice`
        vm.startPrank(alice);

        uint256 mintQty = 4;

        uint256 tooHighPrice = PRICE * (mintQty + 1);
        uint256 tooLowPrice = PRICE * (mintQty - 1);

        vm.expectRevert(ERC721AB.IncorrectETHSent.selector);
        nftWithRoyalty.mint{value: tooHighPrice}(alice, PHASE_ID_0, mintQty, signature);

        vm.expectRevert(ERC721AB.IncorrectETHSent.selector);
        nftWithRoyalty.mint{value: tooLowPrice}(alice, PHASE_ID_0, mintQty, signature);

        vm.stopPrank();
    }

    /* ******************************************************************************************/
    /*                                    UTILITY FUNCTIONS                                     */
    /* ******************************************************************************************/

    function _generateBackendSignature(address _signFor, uint256 _dropId, uint256 _phaseId)
        internal
        view
        returns (bytes memory signature)
    {
        // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
        bytes32 msgHash = keccak256(abi.encodePacked(_signFor, _dropId, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(abSignerPkey, msgHash);
        signature = abi.encodePacked(r, s, v);
    }
}
