// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
import {ABDataRegistry} from "../src/ABDataRegistry.sol";
import {ABRoyalty} from "../src/ABRoyalty.sol";
import {ABVerifier} from "../src/ABVerifier.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {ERC721AB} from "../src/ERC721AB.sol";
import {ERC721ABWrapper} from "../src/ERC721ABWrapper.sol";
import {ABSuperToken} from "./mocks/ABSuperToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AnotherCloneFactoryTestData} from "./testdata/AnotherCloneFactory.td.sol";

contract AnotherCloneFactoryTest is Test, AnotherCloneFactoryTestData {
    /* Admin */
    address public abSigner;

    /* Users */
    address payable public alice;
    address payable public bob;

    /* Contracts */
    ABVerifier public abVerifier;
    ABSuperToken public royaltyToken;
    ABDataRegistry public abDataRegistry;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImplementation;
    ERC1155AB public erc1155Implementation;
    ERC721AB public erc721Implementation;
    ERC721ABWrapper public erc721WrapperImplementation;

    uint256 public constant OPTIMISM_GOERLI_CHAIN_ID = 420;
    uint256 public constant DROP_ID_OFFSET = 10_000;

    function setUp() public {
        /* Setup admins */
        abSigner = vm.addr(69);

        /* Setup users */
        alice = payable(vm.addr(1));
        bob = payable(vm.addr(2));

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);

        vm.label(alice, "alice");
        vm.label(bob, "bob");

        /* Contracts Deployments & Initialization */
        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");

        abVerifier = new ABVerifier(abSigner);
        erc1155Implementation = new ERC1155AB();
        erc721Implementation = new ERC721AB();
        erc721WrapperImplementation = new ERC721ABWrapper();
        royaltyImplementation = new ABRoyalty();
        abDataRegistry = new ABDataRegistry(OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET);

        anotherCloneFactory = new AnotherCloneFactory(
            address(abDataRegistry),
            address(abVerifier),
            address(erc721Implementation),
            address(erc721WrapperImplementation),
            address(erc1155Implementation),
            address(royaltyImplementation)
        );

        abDataRegistry.setAnotherCloneFactory(address(anotherCloneFactory));
    }

    function test_createPublisher_owner() public {
        assertEq(anotherCloneFactory.approvedPublisher(alice), false);

        anotherCloneFactory.createPublisherProfile(alice);

        assertEq(anotherCloneFactory.approvedPublisher(alice), true);
    }

    function test_createPublisher_nonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        anotherCloneFactory.createPublisherProfile(alice);
    }

    function test_createCollection721_approvedPublisher() public {
        anotherCloneFactory.createPublisherProfile(bob);

        vm.startPrank(bob);

        address predictedAddress = anotherCloneFactory.predictERC721Address(SALT);
        anotherCloneFactory.createCollection721(NAME, SYMBOL, SALT);
        (address nft, address publisher) = anotherCloneFactory.collections(0);

        assertEq(predictedAddress, nft);
        assertEq(ERC721AB(nft).owner(), bob);
        assertEq(publisher, bob);

        vm.stopPrank();
    }

    function test_createCollection721_nonApprovedPublisher() public {
        vm.expectRevert(AnotherCloneFactory.FORBIDDEN.selector);
        vm.prank(alice);

        anotherCloneFactory.createCollection721(NAME, SYMBOL, SALT);
    }

    function test_createCollection1155_approvedPublisher() public {
        anotherCloneFactory.createPublisherProfile(bob);

        vm.startPrank(bob);

        address predictedAddress = anotherCloneFactory.predictERC1155Address(SALT);
        anotherCloneFactory.createCollection1155(SALT);
        (address nft, address publisher) = anotherCloneFactory.collections(0);

        assertEq(predictedAddress, nft);
        assertEq(ERC1155AB(nft).owner(), bob);
        assertEq(publisher, bob);

        vm.stopPrank();
    }

    function test_setERC721Implementation_owner() public {
        ERC721AB newErc721Implementation = new ERC721AB();

        assertEq(anotherCloneFactory.erc721Impl(), address(erc721Implementation));

        anotherCloneFactory.setERC721Implementation(address(newErc721Implementation));

        assertEq(anotherCloneFactory.erc721Impl(), address(newErc721Implementation));
    }

    function test_setERC721Implementation_nonOwner() public {
        ERC721AB newErc721Implementation = new ERC721AB();

        vm.prank(address(0x02));

        vm.expectRevert("Ownable: caller is not the owner");
        anotherCloneFactory.setERC721Implementation(address(newErc721Implementation));
    }

    function test_setERC1155Implementation_owner() public {
        ERC1155AB newErc1155Implementation = new ERC1155AB();

        assertEq(anotherCloneFactory.erc1155Impl(), address(erc1155Implementation));

        anotherCloneFactory.setERC1155Implementation(address(newErc1155Implementation));

        assertEq(anotherCloneFactory.erc1155Impl(), address(newErc1155Implementation));
    }

    function test_setERC1155Implementation_nonOwner() public {
        ERC1155AB newErc1155Implementation = new ERC1155AB();

        vm.prank(address(0x02));

        vm.expectRevert("Ownable: caller is not the owner");
        anotherCloneFactory.setERC1155Implementation(address(newErc1155Implementation));
    }

    function test_setABRoyaltyImplementation_owner() public {
        ABRoyalty newRoyaltyImplementation = new ABRoyalty();

        assertEq(anotherCloneFactory.royaltyImpl(), address(royaltyImplementation));

        anotherCloneFactory.setABRoyaltyImplementation(address(newRoyaltyImplementation));

        assertEq(anotherCloneFactory.royaltyImpl(), address(newRoyaltyImplementation));
    }

    function test_setABRoyaltyImplementation_nonOwner() public {
        ABRoyalty newRoyaltyImplementation = new ABRoyalty();

        vm.prank(address(0x02));

        vm.expectRevert("Ownable: caller is not the owner");
        anotherCloneFactory.setABRoyaltyImplementation(address(newRoyaltyImplementation));
    }
}
