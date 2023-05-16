// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ABDataRegistryTestData {
    /* Roles Hash */
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant COLLECTION_ROLE_HASH = keccak256("COLLECTION_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    /* Test Data */

    uint256 public constant PHASE_0 = 0;
    uint256 public constant PHASE_1 = 1;
    uint256 public constant PHASE_2 = 2;

    uint256 public constant TOKEN_0 = 0;
    uint256 public constant TOKEN_1 = 1;
    uint256 public constant TOKEN_2 = 2;
}
