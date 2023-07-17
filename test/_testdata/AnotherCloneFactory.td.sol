// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AnotherCloneFactoryTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x9D469e8515F0cD12E30699B18059Ac8ca3324110;

    /* Roles Hash */
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant PUBLISHER_ROLE_HASH = keccak256("PUBLISHER_ROLE");
    bytes32 public constant AB_ADMIN_ROLE_HASH = keccak256("AB_ADMIN_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    /* Test Data */
    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    bytes32 public constant SALT = "SALT";
    uint256 public constant PUBLISHER_FEE = 9_000;
}
