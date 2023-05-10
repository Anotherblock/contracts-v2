// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC1155ABWrapperTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Test Data */
    uint256 public constant UNITS_PRECISION = 1000;

    string public constant ORIGINAL_URI = "http://original-uri.ipfs/";

    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";

    uint256 public constant TOKEN_ID_1 = 1;
    uint256 public constant TOKEN_ID_2 = 2;
    uint256 public constant TOKEN_ID_3 = 3;
    uint256 public constant TOKEN_ID_4 = 4;
    uint256 public constant TOKEN_ID_5 = 5;
}
