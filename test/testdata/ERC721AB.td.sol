// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC721ABTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Test Data */
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant SUPPLY = 5;
    uint256 public constant MINT_GENESIS = 1;
    uint256 public constant UNITS_PRECISION = 1000;
    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";

    uint256 public constant PHASE_ID_0 = 0;
    uint256 public constant PHASE_ID_1 = 1;
    uint256 public constant PHASE_ID_2 = 2;

    uint256 public constant p0Price = 0.1 ether;
    uint256 public constant p0Start = 1680000000;
    uint256 public constant p0End = 1680000100;
    uint256 public constant p0MaxMint = 3;

    uint256 public constant p1Price = 0.125 ether;
    uint256 public constant p1Start = 1680100001;
    uint256 public constant p1End = 1680100100;
    uint256 public constant p1MaxMint = 3;

    uint256 public constant p2Price = 0.15 ether;
    uint256 public constant p2Start = 1680200001;
    uint256 public constant p2End = 1680200100;
    uint256 public constant p2MaxMint = 3;
}
