//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//

/**
 * @title ERC721ABBase
 * @author Anotherblock Technical Team
 * @notice Anotherblock ERC721 contract standard for onchain summer
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";

contract ERC721ABBase is ERC721AB {
    uint256 private minterCount;

    uint256 private constant PHASE_ID = 0;

    /**
     * @notice
     *  Returns the total amount of tokens minted
     *
     * @return : total amount of tokens minted
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @notice
     *  Returns the total amount of tokens available for mint
     *
     * @return : total amount of tokens available for mint
     */
    function unmintedSupply() external view returns (uint256) {
        return maxSupply - _totalMinted();
    }

    /**
     * @notice
     *  Returns the total number of unique minter
     *
     * @return : total number of unique minter
     */
    function uniqueMinters() external view returns (uint256) {
        return minterCount;
    }

    /**
     * @notice
     *  Returns the total number of tokens minted by the given `_user`
     *
     * @param _user user address to be queried
     *
     * @return : total number of tokens minted by the given `_user`
     */
    function numberMinted(address _user) external view returns (uint256) {
        return _numberMinted(_user);
    }

    /**
     * @notice
     *  Mint `_quantity` tokens to `_to` address
     *
     * @param _to token recipient address
     * @param _quantity quantity of tokens requested
     */
    function mint(address _to, uint256 _quantity) external payable {
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

        // Increment the total number of minter if `_to` did not mint before
        if (_numberMinted(_to) == 0) {
            ++minterCount;
        }

        // Mint `_quantity` amount to `_to` address
        _mint(_to, _quantity);
    }
}
