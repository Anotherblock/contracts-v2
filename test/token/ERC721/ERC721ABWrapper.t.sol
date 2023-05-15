// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {ERC721ABWrapper} from "src/token/ERC721/ERC721ABWrapper.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ERC1155ABWrapper} from "src/token/ERC1155/ERC1155ABWrapper.sol";
import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {AnotherCloneFactory} from "src/factory/AnotherCloneFactory.sol";
import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";

import {ABSuperToken} from "test/_mocks/ABSuperToken.sol";
import {MockNFT} from "test/_mocks/MockNFT.sol";
import {ERC721ABWrapperTestData} from "test/_testdata/ERC721ABWrapper.td.sol";

contract ERC721ABWrapperTest is Test, ERC721ABWrapperTestData {
    using ECDSA for bytes32;

    /* Admin */
    uint256 public abSignerPkey = 69;
    address public abSigner;

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

    MockNFT public mockNFT;

    ERC721ABWrapper public nft;

    uint256 public constant OPTIMISM_GOERLI_CHAIN_ID = 420;
    uint256 public constant DROP_ID_OFFSET = 10_000;

    function setUp() public {
        /* Setup admins */
        abSigner = vm.addr(abSignerPkey);

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

        mockNFT = new MockNFT(ORIGINAL_NAME, ORIGINAL_SYMBOL);
        vm.label(address(mockNFT), "mockNFT");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.setAnotherCloneFactory(address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher);

        vm.prank(publisher);
        anotherCloneFactory.createWrappedCollection721(address(mockNFT), NAME, SYMBOL, SALT);

        (address nftAddr,) = anotherCloneFactory.collections(0);

        nft = ERC721ABWrapper(nftAddr);

        // Mint Token ID 0 to Token ID 4 to alice
        mockNFT.mint(alice, 5);

        // Mint Token ID 5 to Token ID 9 to bob
        mockNFT.mint(bob, 5);

        // Mint Token ID 10 to Token ID 14 to karen
        mockNFT.mint(karen, 5);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        nft.initialize(msg.sender, address(mockNFT), address(abDataRegistry), NAME, SYMBOL);
    }

    function test_initDrop_owner() public {
        vm.prank(publisher);

        nft.initDrop(address(royaltyToken), URI);

        address originalCollection = nft.originalCollection();
        assertEq(originalCollection, address(mockNFT));

        uint256 dropId = nft.dropId();
        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(address(royaltyToken), URI);
    }

    // function test_setBaseURI_owner() public {
    //     vm.startPrank(publisher);
    //     nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

    //     string memory currentURI = nft.tokenURI(0);
    //     assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "0")));

    //     string memory newURI = "http://new-uri.ipfs/";

    //     nft.setBaseURI(newURI);
    //     currentURI = nft.tokenURI(0);
    //     assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI, "0")));

    //     vm.stopPrank();
    // }

    // function test_setBaseURI_nonOwner() public {
    //     vm.prank(publisher);
    //     nft.initDrop(SUPPLY, MINT_GENESIS, genesisRecipient, address(royaltyToken), URI);

    //     string memory newURI = "http://new-uri.ipfs/";

    //     vm.prank(alice);

    //     vm.expectRevert("Ownable: caller is not the owner");
    //     nft.setBaseURI(newURI);
    // }

    function test_wrap() public {
        vm.prank(publisher);
        nft.initDrop(address(royaltyToken), URI);

        uint256 tokenId = 0;

        assertEq(mockNFT.balanceOf(alice), 5);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(mockNFT.ownerOf(tokenId), alice);

        // Impersonate `alice`
        vm.startPrank(alice);
        mockNFT.approve(address(nft), tokenId);
        nft.wrap(tokenId);

        assertEq(mockNFT.balanceOf(alice), 4);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(mockNFT.ownerOf(tokenId), address(nft));
        assertEq(nft.ownerOf(tokenId), alice);

        vm.stopPrank();
    }
}
