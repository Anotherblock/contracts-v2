// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 private tokenCount;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _user, uint256 _quantity) external {
        for (uint256 i = 0; i < _quantity; ++i) {
            _mint(_user, tokenCount);
            ++tokenCount;
        }
    }
}
