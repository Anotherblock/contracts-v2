// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ABHolderRegistryTestData {
    uint256 public constant DROP_ID_OFFSET = 10_000;

    /* Roles Hash */
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant PUBLISHER_ROLE_HASH = keccak256("PUBLISHER_ROLE");
    bytes32 public constant AB_ADMIN_ROLE_HASH = keccak256("AB_ADMIN_ROLE");
    bytes32 public constant COLLECTION_ROLE_HASH = keccak256("COLLECTION_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    /* Test Data */
    uint256 public constant PUBLISHER_FEE = 9_000;

    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant SUPPLY = 5;
    uint256 public constant MINT_GENESIS = 1;
    uint256 public constant UNITS_PRECISION = 1000;
    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";
}
