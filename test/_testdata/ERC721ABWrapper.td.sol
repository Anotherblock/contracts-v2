// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC721ABWrapperTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Roles Hash */
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASE = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant PUBLISHER_ROLE_HASH = keccak256("PUBLISHER_ROLE");
    bytes32 public constant AB_ADMIN_ROLE_HASH = keccak256("AB_ADMIN_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    /* Test Data */
    uint256 public constant PUBLISHER_FEE = 90;
    uint256 public constant UNITS_PRECISION = 1000;

    string public constant ORIGINAL_NAME = "original name";
    string public constant ORIGINAL_SYMBOL = "ORG_SYMBOL";

    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";
}
