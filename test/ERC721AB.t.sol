// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {ERC721AB} from "../src/ERC721AB.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
import {ABRoyalty} from "../src/ABRoyalty.sol";
import {ABSuperToken} from "./mocks/ABSuperToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC721ABTest is Test {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Test Data */
    address public constant label1 = address(0x01);
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant SUPPLY = 5;
    uint256 public constant MINT_GENESIS = 1;
    uint256 public constant UNITS_PRECISION = 1000;
    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";

    /* Contracts */
    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImpl;
    ERC721AB public erc721Impl;
    ERC1155AB public erc1155Impl;

    ERC721AB public nftUnderTest;

    function setUp() public {
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

        nftUnderTest = ERC721AB(nft);
    }

    function test_initialize_alreadyInitialized() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        nftUnderTest.initialize(address(royaltyImpl), msg.sender, NAME, SYMBOL, URI, PRICE, SUPPLY, MINT_GENESIS);
    }

    function test_setBaseURI_owner() public {
        string memory currentURI = nftUnderTest.tokenURI(0);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(URI, "0")));

        string memory newURI = "http://new-uri.ipfs/";

        nftUnderTest.setBaseURI(newURI);
        currentURI = nftUnderTest.tokenURI(0);
        assertEq(keccak256(abi.encodePacked(currentURI)), keccak256(abi.encodePacked(newURI, "0")));
    }

    function test_setBaseURI_nonOwner() public {
        string memory newURI = "http://new-uri.ipfs/";

        vm.prank(address(0x02));

        vm.expectRevert("Ownable: caller is not the owner");
        nftUnderTest.setBaseURI(newURI);
    }

    function test_mint() public {
        // get random address
        address user = vm.addr(1);

        // funds `user` with 1 ether
        vm.deal(user, 1 ether);

        vm.prank(user);
        nftUnderTest.mint{value: PRICE}(user, 1);

        assertEq(nftUnderTest.balanceOf(user), 1);
    }

    function test_mint_DropSoldOut() public {
        uint256 mintQty = 4;

        // get random address
        address user = vm.addr(1);

        // funds `user` with 1 ether
        vm.deal(user, 1 ether);

        vm.prank(user);
        nftUnderTest.mint{value: PRICE * mintQty}(user, mintQty);

        vm.expectRevert(ERC721AB.DropSoldOut.selector);
        nftUnderTest.mint{value: PRICE}(user, 1);
    }
}
