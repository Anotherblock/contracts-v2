// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/AnotherCloneFactory.sol";
import "../src/ABRoyalty.sol";
import "../src/ERC1155AB.sol";
import "../src/ERC721AB.sol";
import "./mocks/ABSuperToken.sol";

contract AnotherCloneFactoryTest is Test {
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    ABSuperToken public royaltyToken;
    AnotherCloneFactory public anotherCloneFactory;
    ABRoyalty public royaltyImplementation;
    ERC1155AB public erc1155Implementation;
    ERC721AB public erc721Implementation;

    function setUp() public {
        royaltyToken = new ABSuperToken(SF_HOST);

        erc1155Implementation = new ERC1155AB();
        erc721Implementation = new ERC721AB();
        royaltyImplementation = new ABRoyalty();

        anotherCloneFactory =
        new AnotherCloneFactory(address(erc721Implementation), address(erc1155Implementation), address(royaltyImplementation));
    }

    // function testStake(uint8 amount) public {
    //   mockERC20.approve(address(staking), amount);
    //   bool result = staking.stake(address(mockERC20), amount);
    //   assertTrue(result);
    // }
}
