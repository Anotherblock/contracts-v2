// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ERC721ABTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x4C073B3baB6d8826b8C5b229f3cfdC1eC6E47E74;

    /* Roles Hash */
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant PUBLISHER_ROLE_HASH = keccak256("PUBLISHER_ROLE");
    bytes32 public constant AB_ADMIN_ROLE_HASH = keccak256("AB_ADMIN_ROLE");
    bytes32 public constant FACTORY_ROLE_HASH = keccak256("FACTORY_ROLE");

    /* Test Data */
    string public constant MOCK_TOKEN_NAME = "Mock Token";
    string public constant MOCK_TOKEN_SYMBOL = "MOCK";
    uint256 public constant PUBLISHER_FEE = 9_000;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant SUPPLY = 5;
    uint256 public constant SHARE_PER_TOKEN = 90_000;
    uint256 public constant MINT_GENESIS = 1;
    uint256 public constant UNITS_PRECISION = 1_000;
    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";

    bool public constant PUBLIC_PHASE = true;
    bool public constant PRIVATE_PHASE = false;

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
