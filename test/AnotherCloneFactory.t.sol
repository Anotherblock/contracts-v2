// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "../src/AnotherCloneFactory.sol";
import "../src/ABRoyalty.sol";
import "../src/ERC1155AB.sol";
import "../src/ERC721AB.sol";
import "./mocks/ABSuperToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AnotherCloneFactoryTest is Test {
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImplementation;
    ERC1155AB public erc1155Implementation;
    ERC721AB public erc721Implementation;

    address public label1 = address(0x01);

    function setUp() public {
        royaltyToken = new ABSuperToken(SF_HOST);
        royaltyToken.initialize(IERC20(address(0)), 18, "fakeSuperToken", "FST");

        erc1155Implementation = new ERC1155AB();
        erc721Implementation = new ERC721AB();
        royaltyImplementation = new ABRoyalty();

        anotherCloneFactory =
        new AnotherCloneFactory(address(erc721Implementation), address(erc1155Implementation), address(royaltyImplementation));
    }

    function test_setApproval(address label) public {
        anotherCloneFactory.setApproval(label, true);

        assertTrue(anotherCloneFactory.approvedAccount(label));
    }

    function test_createDrop721_owner() public {
        anotherCloneFactory.createDrop721(
            "test drop", "td", "testURI", 1e17, 100, 1, true, address(royaltyToken), "ISRC"
        );
    }

    function testFail_createDrop721_nonApprovedLabel() public {
        vm.prank(label1);
        anotherCloneFactory.createDrop721(
            "test drop", "td", "testURI", 1e17, 100, 1, true, address(royaltyToken), "ISRC"
        );
    }

    function test_createDrop721_approvedLabel() public {
        anotherCloneFactory.setApproval(label1, true);

        vm.prank(label1);
        anotherCloneFactory.createDrop721(
            "test drop", "td", "testURI", 1e17, 100, 1, true, address(royaltyToken), "ISRC"
        );
    }

    // function test_createDrop721_label() public {}

    // function test_consoleLog() public {
    //     console.log("test :", 123);
    // }
}
