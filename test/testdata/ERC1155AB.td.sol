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
    // bytes32 public constant SALT_2 = "SALT_2";

    // Pre-calculated Merkle Root - includes USER_1 & USER_2
    bytes32 public constant p0MerkleRoot = 0x3dd73fb4bffdc562cf570f864739747e2ab5d46ab397c4466da14e0e06b57d56;
    uint256 public constant p0Price = 0.1 ether;
    uint256 public constant p0Start = 1680000000;
    uint256 public constant p0End = 1680100000;
    uint256 public constant p0MaxMint = 3;

    // Pre-calculated Merkle Root - includes USER_1, USER_2 & USER_3
    bytes32 public constant p1MerkleRoot = 0xf427e2516c2b28668cec27b1c40c626fe3e391f5c632d8da25d5cd391d19fae1;
    uint256 public constant p1Price = 0.125 ether;
    uint256 public constant p1Start = 1680100001;
    uint256 public constant p1End = 1680200000;
    uint256 public constant p1MaxMint = 3;

    // Pre-calculated Merkle Root - includes USER_1, USER_2, USER_3 & USER_4
    bytes32 public constant p2MerkleRoot = 0xe47075d54b1d9bb2eca1aaf74c2a73615b83ee5e7b02a4323bb50db8c32cea00;
    uint256 public constant p2Price = 0.15 ether;
    uint256 public constant p2Start = 1680200001;
    uint256 public constant p2End = 1680300000;
    uint256 public constant p2MaxMint = 3;

    // // Pre-calculated Merkle Proofs

    // // USER_1
    // // Phase 0 :
    // bytes32 public aliceP0Proof = 0x94a6fc29a44456b36232638a7042431c9c91b910df1c52187179085fac1560e9;
    // // Phase 1 :
    // bytes32 public aliceP1Proof = 0x1bec7c333d3d0c3eef8c6199a402856509c3f869d25408cc1cc2208d0371db0e;
    // // Phase 2 :
    // bytes32 public aliceP2Proof = 0x7ffe805cbf69104033955da6db7de982b4b029fc5459b3133ba12ed30a67ad85;

    // // USER_2 :
    // // Phase 0 :
    // bytes32 public bobP0Proof = 0x3322f33946a3c503c916c8fc29768a547f01fa665e1eb22f9f66cf7e5a262012;
    // // Phase 1 :
    // bytes32 public bobP1Proof = 0x1bec7c333d3d0c3eef8c6199a402856509c3f869d25408cc1cc2208d0371db0e;
    // // Phase 2 :
    // bytes32 public bobP2Proof = 0x7ffe805cbf69104033955da6db7de982b4b029fc5459b3133ba12ed30a67ad85;

    // // USER_3 :
    // // Phase 1
    // bytes32 public karenP1Proof = 0x3dd73fb4bffdc562cf570f864739747e2ab5d46ab397c4466da14e0e06b57d56;
    // // Phase 2 :
    // bytes32 public karenP2Proof = 0x1143df8268b94bd6292fdd7c9b8af39a79f764cfc03ae006844446bc91203927;

    // // USER_4 :
    // // Phase 2 :
    // bytes32 public daveP2Proof = 0x1bec7c333d3d0c3eef8c6199a402856509c3f869d25408cc1cc2208d0371db0e;
}
