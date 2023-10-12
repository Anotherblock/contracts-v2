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
 * @title ERC721ABDS
 * @author anotherblock Technical Team
 * @notice anotherblock ERC721 contract used for dynamic share NFTs
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* anotherblock Contract */
import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";

/* anotherblock Libraries */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

contract ERC721ABDS is ERC721AB {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev maximum amount of share units for this collection
    uint256 public maxUnits;

    /// @dev amount of units sold for this collection
    uint256 public soldUnits;

    /// @dev units associated to a given token
    mapping(uint256 tokenId => uint256 units) public tokenUnits;

    /// @dev Implementation Type
    bytes32 public constant IMPLEMENTATION_TYPE = keccak256("DYNAMIC_SHARE");

    /// @dev ERC721AB implementation version
    uint8 public constant IMPLEMENTATION_VERSION = 1;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Mint `_quantity` tokens to `_to` address based on the current `_phaseId` if `_signature` is valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _phaseId current minting phase (must be started)
     * @param _units amount of units requested
     * @param _signature signature to verify allowlist status
     */
    function mint(address _to, uint256 _phaseId, uint256 _units, bytes calldata _signature) external payable {
        // Check that the requested minting phase has started
        if (!_isPhaseActive(_phaseId)) revert ABErrors.PHASE_NOT_ACTIVE();

        // Get requested phase details
        ABDataTypes.Phase memory phase = phases[_phaseId];

        // Check that there are enough tokens available for sale
        if (soldUnits + _units > maxUnits) {
            revert ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check if the current phase is private
        if (!phase.isPublic) {
            // Check that the user is included in the allowlist
            if (!abVerifier.verifySignature721(_to, address(this), _phaseId, _signature)) {
                revert ABErrors.NOT_ELIGIBLE();
            }
        }

        // Check that user did not mint / is not asking to mint more units than the max mint per address for the current phase
        if (mintedPerPhase[_to][_phaseId] + _units > phase.maxMint) revert ABErrors.MAX_MINT_PER_ADDRESS();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _units) revert ABErrors.INCORRECT_ETH_SENT();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_phaseId] += _units;

        // Set the token units for the token to be minted
        tokenUnits[_nextTokenId()] = _units;

        // Mint `_quantity` amount to `_to` address
        _mint(_to, 1);
    }

    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //               /____/

    /**
     * @notice
     *  Initialize the Drop parameters
     *  Only the contract owner can perform this operation
     *
     * @param _maxUnits maximum amount of units to be set
     * @param _sharePerToken percentage ownership of the full master right for one token (to be divided by 1e6)
     * @param _mintGenesisUnits amount of units associated to the genesis token to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _royaltyCurrency royalty currency contract address
     * @param _baseUri base URI for this drop
     */
    function initDrop(
        uint256 _maxUnits,
        uint256 _sharePerToken,
        uint256 _mintGenesisUnits,
        address _genesisRecipient,
        address _royaltyCurrency,
        string calldata _baseUri
    ) external onlyOwner {
        if (_mintGenesisUnits > _maxUnits) revert ABErrors.INVALID_PARAMETER();

        // Set the maximum amount of units
        maxUnits = _maxUnits;

        if (_mintGenesisUnits > 0) {
            // Set the token units for the token to be minted
            tokenUnits[_nextTokenId()] = _mintGenesisUnits;

            // Increment the amount of units sold
            soldUnits += _mintGenesisUnits;

            // Initialize the drop
            _initDrop(_sharePerToken, 1, _genesisRecipient, _royaltyCurrency, _baseUri);
        } else {
            // Initialize the drop
            _initDrop(_sharePerToken, 0, _genesisRecipient, _royaltyCurrency, _baseUri);
        }
    }

    /**
     * @notice
     *  Set the maximum amount of units
     *  Only the contract owner can perform this operation
     *
     * @param _maxUnits new maximum amount of units to be set
     */
    function setMaxUnits(uint256 _maxUnits) external onlyOwner {
        if (_maxUnits < soldUnits) revert ABErrors.INVALID_PARAMETER();
        maxUnits = _maxUnits;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _beforeTokenTransfers(address _from, address _to, uint256 _tokenId, uint256 _quantity)
        internal
        virtual
        override(ERC721AB)
    {
        abDataRegistry.on721TokenTransfer(publisher, _from, _to, dropId, _quantity * tokenUnits[_tokenId]);
    }
}
