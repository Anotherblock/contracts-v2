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
import {ERC721ABTestData} from "test/_testdata/ERC721AB.td.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC721ABWrapper public erc721WrapperImpl;
    ERC1155AB public erc1155Impl;
    ERC1155ABWrapper public erc1155WrapperImpl;

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

        abDataRegistry = new ABDataRegistry(DROP_ID_OFFSET, treasury);
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

        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        uint256 maxSupply = nft.maxSupply();
        assertEq(maxSupply, SUPPLY);

        uint256 dropId = nft.dropId();
        assertEq(dropId, DROP_ID_OFFSET + 1);

        assertEq(nft.balanceOf(genesisRecipient), MINT_GENESIS);

        string memory currentURI = nft.tokenURI(1);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "1")));
    }

    function test_initDrop_noGenesisMint() public {
        vm.prank(publisher);
        nft.initDrop(SUPPLY, 0, genesisRecipient, address(royaltyToken), URI);

        uint256 maxSupply = nft.maxSupply();

        assertEq(maxSupply, SUPPLY);
        assertEq(nft.balanceOf(genesisRecipient), 0);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);
    }

    function test_initDrop_supplyToGenesisRatio() public {
        vm.expectRevert(ERC721AB.INVALID_PARAMETER.selector);
        vm.prank(publisher);

        nft.initDrop(SUPPLY, SUPPLY + 1, genesisRecipient, address(royaltyToken), URI);
    }

    function test_setBaseURI_owner() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

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
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(alice);

        vm.expectRevert();
        nft.setBaseURI(newURI);
    }

    function test_setDropPhases_owner_multiplePhases() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC721AB.Phase memory phase1 = ERC721AB.Phase(p1Start, p1End, p1Price, p1MaxMint);
        ERC721AB.Phase memory phase2 = ERC721AB.Phase(p2Start, p2End, p2Price, p2MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](3);
        phases[0] = phase0;
        phases[1] = phase1;
        phases[2] = phase2;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _p0Start, uint256 _p0End, uint256 _p0Price, uint256 _p0MaxMint) = nft.phases(0);
        (uint256 _p1Start, uint256 _p1End, uint256 _p1Price, uint256 _p1MaxMint) = nft.phases(1);
        (uint256 _p2Start, uint256 _p2End, uint256 _p2Price, uint256 _p2MaxMint) = nft.phases(2);

        assertEq(_p0Start, p0Start);
        assertEq(_p0End, p0End);
        assertEq(_p0Price, p0Price);
        assertEq(_p0MaxMint, p0MaxMint);

        assertEq(_p1Start, p1Start);
        assertEq(_p1End, p1End);
        assertEq(_p1Price, p1Price);
        assertEq(_p1MaxMint, p1MaxMint);

        assertEq(_p2Start, p2Start);
        assertEq(_p2End, p2End);
        assertEq(_p2Price, p2Price);
        assertEq(_p2MaxMint, p2MaxMint);
    }

    function test_setDropPhases_owner_onePhase() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        vm.prank(publisher);
        nft.setDropPhases(phases);

        (uint256 _p0Start, uint256 _p0End, uint256 _p0Price, uint256 _p0MaxMint) = nft.phases(0);

        assertEq(_p0Start, p0Start);
        assertEq(_p0End, p0End);
        assertEq(_p0Price, p0Price);
        assertEq(_p0MaxMint, p0MaxMint);
    }

    function test_setDropPhases_incorrectPhaseOrder() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC721AB.Phase memory phase1 = ERC721AB.Phase(p1Start, p1End, p1Price, p1MaxMint);

        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](2);
        phases[0] = phase1;
        phases[1] = phase0;

        vm.prank(publisher);
        vm.expectRevert(ERC721AB.INVALID_PARAMETER.selector);
        nft.setDropPhases(phases);
    }

    function test_setDropPhases_nonOwner() public {
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, p0Price, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
        phases[0] = phase0;

        vm.prank(bob);

        vm.expectRevert();
        nft.setDropPhases(phases);
    }

    function test_mint() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
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
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, 4);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
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
        vm.expectRevert(ERC721AB.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: PRICE}(bob, PHASE_ID_0, 1, signature);
    }

    function test_mint_notEnoughTokenAvailable() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, p0MaxMint);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
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
        vm.expectRevert(ERC721AB.NOT_ENOUGH_TOKEN_AVAILABLE.selector);
        nft.mint{value: PRICE * bobMintQty}(bob, PHASE_ID_0, bobMintQty, signature);
    }

    function test_mint_noPhaseSet() public {
        vm.prank(publisher);
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        uint256 aliceMintQty = 3;

        // Create signature for `alice` dropId 0 and phaseId 0
        bytes memory signature = _generateBackendSignature(alice, address(nft), PHASE_ID_0);

        vm.prank(alice);
        vm.expectRevert();
        nft.mint{value: PRICE * aliceMintQty}(alice, PHASE_ID_0, aliceMintQty, signature);
    }

    function test_mint_incorrectETHSent() public {
        vm.startPrank(publisher);
        nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

        // Set block.timestamp to be after the start of Phase 0
        vm.warp(p0Start + 1);

        // Set the phases
        ERC721AB.Phase memory phase0 = ERC721AB.Phase(p0Start, p0End, PRICE, 10);
        ERC721AB.Phase[] memory phases = new ERC721AB.Phase[](1);
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

        vm.expectRevert(ERC721AB.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooHighPrice}(alice, PHASE_ID_0, mintQty, signature);

        vm.expectRevert(ERC721AB.INCORRECT_ETH_SENT.selector);
        nft.mint{value: tooLowPrice}(alice, PHASE_ID_0, mintQty, signature);

        vm.stopPrank();
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
}
