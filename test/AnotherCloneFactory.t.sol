// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {AnotherCloneFactory} from "../src/AnotherCloneFactory.sol";
import {ABRoyalty} from "../src/ABRoyalty.sol";
import {ABVerifier} from "../src/ABVerifier.sol";
import {ERC1155AB} from "../src/ERC1155AB.sol";
import {ERC721AB} from "../src/ERC721AB.sol";
import {ABSuperToken} from "./mocks/ABSuperToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AnotherCloneFactoryTest is Test {
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;
    address public constant label1 = address(0x01);

    uint256 public constant OPTIMISM_GOERLI_CHAIN_ID = 420;
    uint256 public constant DROP_ID_OFFSET = 10_000;

    address public abSigner;

    ABVerifier public abVerifier;
    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImplementation;
    ERC1155AB public erc1155Implementation;
    ERC721AB public erc721Implementation;

    function setUp() public {
        abSigner = vm.addr(69);

        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");

        abVerifier = new ABVerifier(abSigner);
        erc1155Implementation = new ERC1155AB();
        erc721Implementation = new ERC721AB();
        royaltyImplementation = new ABRoyalty();

        anotherCloneFactory = new AnotherCloneFactory(
            OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET,
            address(abVerifier),
            address(erc721Implementation),
            address(erc1155Implementation),
            address(royaltyImplementation)
        );
    }

    function test_setApproval(address label) public {
        anotherCloneFactory.setApproval(label, true);
        assertTrue(anotherCloneFactory.approvedAccount(label));

        anotherCloneFactory.setApproval(label, false);
        assertFalse(anotherCloneFactory.approvedAccount(label));
    }

    function test_createDrop721_owner() public {
        bytes32 salt = "SALT";
        address predictedAddress = anotherCloneFactory.predictERC721Address(salt);
        anotherCloneFactory.createDrop721("test drop", "td", true, address(royaltyToken), salt);
        (uint256 dropId, address nft, address royalty) = anotherCloneFactory.drops(0);

        assertEq(predictedAddress, nft);
        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);
        assertEq(address(this), ERC721AB(nft).owner());
        assertEq(address(this), ABRoyalty(royalty).owner());
    }

    function test_createDrop721_nonApprovedLabel() public {
        vm.expectRevert(AnotherCloneFactory.FORBIDDEN.selector);
        vm.prank(label1);

        anotherCloneFactory.createDrop721("test drop", "td", true, address(royaltyToken), "ISRC");
    }

    function test_createDrop721_approvedLabel() public {
        anotherCloneFactory.setApproval(label1, true);

        vm.prank(label1);
        anotherCloneFactory.createDrop721("test drop", "td", true, address(royaltyToken), "ISRC");
    }

    function test_createDrop1155_owner() public {
        bytes32 salt = "SALT";
        address predictedAddress = anotherCloneFactory.predictERC1155Address(salt);
        anotherCloneFactory.createDrop1155(address(royaltyToken), salt);
        (uint256 dropId, address nft, address royalty) = anotherCloneFactory.drops(0);

        assertEq(predictedAddress, nft);
        assertEq(dropId, OPTIMISM_GOERLI_CHAIN_ID * DROP_ID_OFFSET + 1);
        assertEq(address(this), ERC1155AB(nft).owner());
        assertEq(address(this), ABRoyalty(royalty).owner());
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
