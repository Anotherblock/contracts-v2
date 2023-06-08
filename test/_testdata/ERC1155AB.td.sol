// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC1155ABTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    // /* Test Data */
    bytes32 public constant SALT = "SALT";
    uint256 public constant PUBLISHER_FEE = 9_000;

    /* Roles Hash */
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant PUBLISHER_ROLE_HASH = keccak256("PUBLISHER_ROLE");
    bytes32 public constant AB_ADMIN_ROLE_HASH = keccak256("AB_ADMIN_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    // Token ID 1
    uint256 public constant TOKEN_ID_1 = 1;
    uint256 public constant TOKEN_1_SUPPLY = 5;
    uint256 public constant TOKEN_1_MINT_GENESIS = 1;
    string public constant TOKEN_1_URI = "http://token1.uri.ipfs/";

    // Token ID 2
    uint256 public constant TOKEN_ID_2 = 2;
    uint256 public constant TOKEN_2_SUPPLY = 20;
    uint256 public constant TOKEN_2_MINT_GENESIS = 2;
    string public constant TOKEN_2_URI = "http://token2.uri.ipfs/";

    // Token ID 3
    uint256 public constant TOKEN_ID_3 = 3;
    uint256 public constant TOKEN_3_SUPPLY = 30;
    uint256 public constant TOKEN_3_MINT_GENESIS = 3;
    string public constant TOKEN_3_URI = "http://token3.uri.ipfs/";

    uint256 public constant PHASE_ID_0 = 0;
    uint256 public constant PHASE_ID_1 = 1;
    uint256 public constant PHASE_ID_2 = 2;

    uint256 public constant P0_PRICE = 0.1 ether;
    uint256 public constant P0_START = 1680000000;
    uint256 public constant P0_END = 1680000100;
    uint256 public constant P0_MAX_MINT = 3;

    uint256 public constant P1_PRICE = 0.125 ether;
    uint256 public constant P1_START = 1680100001;
    uint256 public constant P1_END = 1680100100;
    uint256 public constant P1_MAX_MINT = 3;

    uint256 public constant P2_PRICE = 0.15 ether;
    uint256 public constant P2_START = 1680200001;
    uint256 public constant P2_END = 1680200100;
    uint256 public constant P2_MAX_MINT = 3;
}
