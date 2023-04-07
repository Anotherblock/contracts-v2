contract ERC721ABTestData {
    /* Superfluid Host */
    address public constant SF_HOST = 0x567c4B141ED61923967cA25Ef4906C8781069a10;

    /* Test Data */
    address public constant label1 = address(0x01);
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant SUPPLY = 5;
    uint256 public constant MINT_GENESIS = 1;
    uint256 public constant UNITS_PRECISION = 1000;
    string public constant NAME = "name";
    string public constant SYMBOL = "SYMBOL";
    string public constant URI = "http://uri.ipfs/";
    bytes32 public constant SALT = "SALT";
    bytes32 public constant SALT_2 = "SALT_2";



    // Contains USER_1 & USER_2
    bytes32 public constant p0MerkleRoot = 0x3dd73fb4bffdc562cf570f864739747e2ab5d46ab397c4466da14e0e06b57d56;
    uint256 public constant p0Start = 1680000000;
    uint256 public constant p0End = 1680100000;
    uint256 public constant p0MaxMint = 3;

    // Contains USER_1, USER_2 & USER_3
    bytes32 public constant p1MerkleRoot = 0xf427e2516c2b28668cec27b1c40c626fe3e391f5c632d8da25d5cd391d19fae1;
    uint256 public constant p1Start = 1680100001;
    uint256 public constant p1End = 1680200000;
    uint256 public constant p1MaxMint = 3;

    // Contains USER_1, USER_2, USER_3 & USER_4
    bytes32 public constant p2MerkleRoot = 0xe47075d54b1d9bb2eca1aaf74c2a73615b83ee5e7b02a4323bb50db8c32cea00;
    uint256 public constant p2Start = 1680200001;
    uint256 public constant p2End = 1680300000;
    uint256 public constant p2MaxMint = 3;

 
}
