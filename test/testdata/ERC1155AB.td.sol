// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC1155ABTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;
    // uint256 public constant UNITS_PRECISION = 1000;

    // /* Test Data */
    uint256 public constant TOKEN_0_ID = 0;
    uint256 public constant TOKEN_0_PRICE = 0.1 ether;
    uint256 public constant TOKEN_0_SUPPLY = 5;
    uint256 public constant TOKEN_0_MINT_GENESIS = 1;
    string public constant TOKEN_0_URI = "http://token0.uri.ipfs/";

    bytes32 public constant SALT = "SALT";
}
