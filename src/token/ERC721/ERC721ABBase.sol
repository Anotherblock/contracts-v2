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
import {IABRoyalty} from "src/royalty/IABRoyalty.sol";

/* Anotherblock Library */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";

contract ERC721ABBase is ERC721AB {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Counts the number of unique minters
    uint256 private minterCount;

    /// @dev Phase identifier
    uint256 private constant PHASE_ID = 0;

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

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
        ABDataTypes.Phase memory phase = phases[PHASE_ID];

        // Check that there are enough tokens available for sale
        if (_totalMinted() + _quantity > maxSupply) {
            revert NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert INCORRECT_ETH_SENT();

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][PHASE_ID] + _quantity > phase.maxMint) revert MAX_MINT_PER_ADDRESS();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][PHASE_ID] += _quantity;

        // Increment the total number of unique minter if `_to` did not mint before
        if (_numberMinted(_to) == 0) {
            ++minterCount;
        }

        // Mint `_quantity` amount to `_to` address
        _mint(_to, _quantity);
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Initialize the Drop parameters
     *  Only the contract owner can perform this operation
     *
     * @param _maxSupply supply cap for this drop
     * @param _sharePerToken percentage ownership of the full master right for one token (to be divided by 1e6)
     * @param _mintGenesis amount of genesis tokens to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _royaltyCurrency royalty currency contract address
     * @param _baseUri base URI for this drop
     */
    function initDrop(
        uint256 _maxSupply,
        uint256 _sharePerToken,
        uint256 _mintGenesis,
        address _genesisRecipient,
        address _royaltyCurrency,
        string calldata _baseUri
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check that the drop hasn't been already initialized
        if (dropId != 0) revert DROP_ALREADY_INITIALIZED();

        // Register Drop within ABDropRegistry
        dropId = abDataRegistry.registerDrop(publisher, 0);

        abRoyalty = IABRoyalty(abDataRegistry.getRoyaltyContract(publisher));

        // Initialize royalty payout index
        abRoyalty.initPayoutIndex(_royaltyCurrency, dropId);

        // Set supply cap
        maxSupply = _maxSupply;

        // Set the royalty share
        sharePerToken = _sharePerToken;

        // Set base URI
        baseTokenURI = _baseUri;

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_mintGenesis > 0) {
            if (_mintGenesis > _maxSupply) revert INVALID_PARAMETER();
            _mint(_genesisRecipient, _mintGenesis);
            ++minterCount;
        }
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the total amount of tokens available for mint
     *
     * @return _unmintedSupply total amount of tokens available for mint
     */
    function unmintedSupply() external view returns (uint256 _unmintedSupply) {
        _unmintedSupply = maxSupply - _totalMinted();
    }

    /**
     * @notice
     *  Returns the total number of unique minter
     *
     * @return _uniqueMinters total number of unique minter
     */
    function uniqueMinters() external view returns (uint256 _uniqueMinters) {
        _uniqueMinters = minterCount;
    }

    /**
     * @notice
     *  Returns true if `_user` can mint, false otherwise
     *
     * @param _user user address to be queried
     *
     * @return _canMint true if `_user` can mint, false otherwise
     */
    function canMint(address _user) external view returns (bool _canMint) {
        // Get the phase details
        ABDataTypes.Phase memory phase = phases[PHASE_ID];

        _canMint = _numberMinted(_user) < phase.maxMint;
    }

    /**
     * @notice
     *  Returns the total number of tokens minted by the given `_user`
     *
     * @param _user user address to be queried
     *
     * @return _userMinted total number of tokens minted by the given `_user`
     */
    function numberMinted(address _user) external view returns (uint256 _userMinted) {
        _userMinted = _numberMinted(_user);
    }
}
