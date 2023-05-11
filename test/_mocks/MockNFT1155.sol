// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockNFT1155 is ERC1155 {
    constructor(string memory _uri) ERC1155(_uri) {}

    function mint(address _user, uint256 _tokenId, uint256 _quantity) external {
        _mint(_user, _tokenId, _quantity, "");
    }

    function mintBatch(address _user, uint256[] memory _tokenIds, uint256[] memory _quantities) external {
        _mintBatch(_user, _tokenIds, _quantities, "");
    }
}
