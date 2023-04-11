// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "../src/ERC721AB.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
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

    /* Contracts */
    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;

    ERC1155AB public nft;

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

        string memory currentURI = nft.uri(TOKEN_0_ID);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(TOKEN_0_URI)));

        string memory newURI = "http://new-uri.ipfs/";

        nft.setTokenURI(TOKEN_0_ID, newURI);
        currentURI = nft.uri(TOKEN_0_ID);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI)));
    }

    function test_setTokenURI_nonOwner() public {
        nft.initDrop(TOKEN_0_SUPPLY, TOKEN_0_MINT_GENESIS, TOKEN_0_URI);

        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(bob);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.setTokenURI(TOKEN_0_ID, newURI);
    }
}
