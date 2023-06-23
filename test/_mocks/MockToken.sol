// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    uint256 public tokenCount;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _user, uint256 _quantity) external {
        _mint(_user, _quantity);
    }
}
