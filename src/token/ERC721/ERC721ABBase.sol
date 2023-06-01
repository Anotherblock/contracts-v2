// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";

contract ERC721ABBase is ERC721AB {
    uint256 private minterCount;

    uint256 private constant PHASE_ID = 0;

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function supplyLeft() external view returns (uint256) {
        return maxSupply - _totalMinted();
    }

    function uniqueMinters() external view returns (uint256) {
        return minterCount;
    }

    function numberMinted(address user) external view returns (uint256) {
        return _numberMinted(user);
    }

    function mint(address _to, uint256 _quantity) public payable {
        // Check that the requested minting phase has started
        if (!_isPhaseActive(PHASE_ID)) revert PHASE_NOT_ACTIVE();
        // Get requested phase details
        Phase memory phase = phases[PHASE_ID];
        // Check that there are enough tokens available for sale
        if (_totalMinted() + _quantity > maxSupply) {
            revert NOT_ENOUGH_TOKEN_AVAILABLE();
        }
        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert INCORRECT_ETH_SENT();

        if (_numberMinted(_to) == 0) {
            ++minterCount;
        }
        // Mint `_quantity` amount to `_to` address
        _mint(_to, _quantity);
    }
}
