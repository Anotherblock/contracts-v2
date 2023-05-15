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
import {MockNFT1155} from "test/_mocks/MockNFT1155.sol";
import {ERC1155ABWrapperTestData} from "test/_testdata/ERC1155ABWrapper.td.sol";

contract ERC1155ABWrapperTest is Test, ERC1155ABWrapperTestData {
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

    MockNFT1155 public mockNFT;

    ERC1155ABWrapper public nft;

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

        mockNFT = new MockNFT1155(ORIGINAL_URI);
        vm.label(address(mockNFT), "mockNFT");

        /* Setup Access Control Roles */
        anotherCloneFactory.grantRole(AB_ADMIN_ROLE_HASH, address(this));

        /* Init contracts params */
        abDataRegistry.setAnotherCloneFactory(address(anotherCloneFactory));

        anotherCloneFactory.createPublisherProfile(publisher);

        vm.prank(publisher);
        anotherCloneFactory.createWrappedCollection1155(address(mockNFT), SALT);

        (address nftAddr,) = anotherCloneFactory.collections(0);

        nft = ERC1155ABWrapper(nftAddr);

        _mintMockTokens();
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        nft.initialize(msg.sender, address(mockNFT), address(abDataRegistry));
    }

    function test_initDrop_owner() public {
        vm.prank(publisher);

        nft.initDrop(TOKEN_ID_1, address(royaltyToken), URI);

        address originalCollection = nft.originalCollection();
        assertEq(originalCollection, address(mockNFT));

        (uint256 dropId,) = nft.tokensDetails(TOKEN_ID_1);

        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);
    }

    function test_initDrop_nonOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.initDrop(TOKEN_ID_1, address(royaltyToken), URI);
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

    //     vm.expectRevert();
    //     nft.setBaseURI(newURI);
    // }

    function test_wrap() public {
        vm.prank(publisher);
        nft.initDrop(TOKEN_ID_1, address(royaltyToken), URI);

        assertEq(mockNFT.balanceOf(alice, TOKEN_ID_1), 1);
        assertEq(nft.balanceOf(alice, TOKEN_ID_1), 0);

        // Impersonate `alice`
        vm.startPrank(alice);
        mockNFT.setApprovalForAll(address(nft), true);
        nft.wrap(TOKEN_ID_1, 1);

        assertEq(mockNFT.balanceOf(alice, TOKEN_ID_1), 0);
        assertEq(mockNFT.balanceOf(address(nft), TOKEN_ID_1), 1);
        assertEq(nft.balanceOf(alice, TOKEN_ID_1), 1);

        vm.stopPrank();
    }

    function _mintMockTokens() internal {
        uint256[] memory tokenIds = new uint256[](5);
        tokenIds[0] = TOKEN_ID_1;
        tokenIds[1] = TOKEN_ID_2;
        tokenIds[2] = TOKEN_ID_3;
        tokenIds[3] = TOKEN_ID_4;
        tokenIds[4] = TOKEN_ID_5;

        uint256[] memory aliceQty = new uint256[](5);
        aliceQty[0] = 1;
        aliceQty[1] = 1;
        aliceQty[2] = 1;
        aliceQty[3] = 1;
        aliceQty[4] = 1;

        uint256[] memory bobQty = new uint256[](5);
        bobQty[0] = 2;
        bobQty[1] = 2;
        bobQty[2] = 2;
        bobQty[3] = 2;
        bobQty[4] = 2;

        uint256[] memory karenQty = new uint256[](5);
        karenQty[0] = 3;
        karenQty[1] = 3;
        karenQty[2] = 3;
        karenQty[3] = 3;
        karenQty[4] = 3;

        mockNFT.mintBatch(alice, tokenIds, aliceQty);

        mockNFT.mintBatch(bob, tokenIds, bobQty);

        mockNFT.mintBatch(karen, tokenIds, karenQty);
    }
}
