// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC721ABWrapperTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Test Data */
    uint256 public constant UNITS_PRECISION = 1000;

    string public constant ORIGINAL_NAME = "original name";
    string public constant ORIGINAL_SYMBOL = "ORG_SYMBOL";

    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";
}
