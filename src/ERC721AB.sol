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
 * @title ERC721AB
 * @author Anotherblock Technical Team
 * @notice Anotherblock ERC721 contract standard
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* ERC721A Contract */
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* Anotherblock Interfaces */
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";
import {IABVerifier} from "./interfaces/IABVerifier.sol";

contract ERC721AB is ERC721AUpgradeable, OwnableUpgradeable {
    /**
     * @notice
     *  Phase Structure format
     *
     * @param phaseStart timestamp at which the phase starts
     * @param price price for one token during the phase
     * @param maxMint maximum number of token to be minted per user during the phase
     */
    struct Phase {
        uint256 phaseStart;
        uint256 price;
        uint256 maxMint;
    }

    /// @dev Error returned if the drop is sold out
    error DropSoldOut();

    /// @dev Error returned if supply is insufficient
    error NotEnoughTokensAvailable();

    /// @dev Error returned if user did not send the correct amount of ETH
    error IncorrectETHSent();

    /// @dev Error returned if the requested phase is not active
    error PhaseNotActive();

    /// @dev Error returned if user attempt to mint more than allowed
    error MaxMintPerAddress();

    /// @dev Error returned if user is not eligible to mint during the current phase
    error NotEligible();

    /// @dev Error returned when the passed parameter is incorrect
    error InvalidParameter();

    /// @dev Error returned if user attempt to mint while the phases are not set
    error PhasesNotSet();

    /// @dev Event emitted upon phase update
    event UpdatedPhase(uint256 numOfPhase);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Anotherblock Verifier contract interface (see IABVerifier.sol)
    IABVerifier public abVerifier;

    /// @dev Anotherblock Royalty contract interface (see IABRoyalty.sol)
    IABRoyalty public abRoyalty;

    /// @dev Supply cap for this collection
    uint256 public maxSupply;

    /// @dev Base Token URI
    string private baseTokenURI;

    ///@dev Dynamic array of phases
    Phase[] public phases;

    ///@dev Mapping storing the amount minted per wallet and per phase
    mapping(address user => mapping(uint256 phaseId => uint256 minted)) public mintedPerPhase;

    ///@dev ERC721AB implementation version
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

    /**
     * @notice
     *  Contract Initializer (Minimal Proxy Contract)
     *
     * @param _abRoyalty address of corresponding ABRoyalty contract
     * @param _abVerifier address of ABVerifier contract
     * @param _name NFT collection name
     * @param _symbol NFT collection symbol
     */
    function initialize(address _abRoyalty, address _abVerifier, string memory _name, string memory _symbol)
        external
        initializerERC721A
        initializer
    {
        // Initialize ERC721A
        __ERC721A_init(_name, _symbol);

        // Initialize Ownable
        __Ownable_init();

        if (_abRoyalty != address(0)) {
            // Assign ABRoyalty address
            abRoyalty = IABRoyalty(_abRoyalty);

            // Initialize payout index
            abRoyalty.initPayoutIndex(0);
        }

        // Assign ABVerifier address
        abVerifier = IABVerifier(_abVerifier);
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
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     */
    function mint(address _to, uint256 _phaseId, uint256 _quantity, bytes calldata _signature) external payable {
        // Check that the phases are defined
        if (phases.length == 0) revert PhasesNotSet();

        // Check that the requested minting phase has started
        if (!_isPhaseActive(_phaseId)) revert PhaseNotActive();

        // Get requested phase details
        Phase memory phase = phases[_phaseId];

        // Get the current minted supply
        uint256 currentSupply = _totalMinted();

        // Check that the drop is not sold out
        if (currentSupply == maxSupply) revert DropSoldOut();

        // Check that there are enough tokens available for sale
        if (currentSupply + _quantity > maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        // Check that the user is included in the allowlist
        if (!abVerifier.verifySignature721(_to, address(this), _phaseId, _signature)) {
            revert NotEligible();
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_phaseId] + _quantity > phase.maxMint) revert MaxMintPerAddress();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert IncorrectETHSent();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_phaseId] += _quantity;

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
     * @param _mintGenesis amount of genesis tokens to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _baseUri base URI for this drop
     */
    function initDrop(uint256 _maxSupply, uint256 _mintGenesis, address _genesisRecipient, string memory _baseUri)
        external
        onlyOwner
    {
        // Set supply cap
        maxSupply = _maxSupply;

        // Set base URI
        baseTokenURI = _baseUri;

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_mintGenesis > 0) {
            if (_mintGenesis > _maxSupply) revert InvalidParameter();
            _mint(_genesisRecipient, _mintGenesis);
        }
    }

    /**
     * @notice
     *  Update the Base URI
     *  Only the contract owner can perform this operation
     *
     * @param _newBaseURI new base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *  Only the contract owner can perform this operation
     *
     * @param _phases array of phases to be set (see Phase structure format)
     */
    function setDropPhases(Phase[] memory _phases) external onlyOwner {
        // Delete previously set phases (if any)
        if (phases.length > 0) {
            delete phases;
        }

        uint256 previousPhaseStart = 0;

        uint256 numOfPhase = _phases.length;

        for (uint256 i = 0; i < numOfPhase; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order)
            if (phase.phaseStart <= previousPhaseStart) {
                revert InvalidParameter();
            }
            phases.push(phase);
            previousPhaseStart = phase.phaseStart;
        }

        emit UpdatedPhase(numOfPhase);
    }

    /**
     * @notice
     *  Withdraw `_amount` to the `_rightholder` address
     *  Only the contract owner can perform this operation
     *
     * @param _rightholder recipient address
     * @param _amount amount to be transferred
     */
    function withdrawToRightholder(address _rightholder, uint256 _amount) external onlyOwner {
        if (_rightholder == address(0)) revert InvalidParameter();
        (bool success,) = _rightholder.call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns true if the passed phase ID is active
     *
     * @param _phaseId requested phase ID
     *
     * @return _isActive true if phase is active, false otherwise
     */
    function _isPhaseActive(uint256 _phaseId) internal view returns (bool _isActive) {
        // Check that the requested phase ID exists within the phases array
        if (_phaseId >= phases.length) revert InvalidParameter();

        // Check if the requested phase has started
        _isActive = phases[_phaseId].phaseStart <= block.timestamp;
    }

    /**
     * @notice
     *  Returns the base URI
     *
     * @return _URI token URI state
     */
    function _baseURI() internal view virtual override returns (string memory _URI) {
        _URI = baseTokenURI;
    }

    /**
     * @notice
     *  Returns true if this drop pays-out royalty, false otherwise
     *
     * @return _enabled true if this drop pays-out royalty, false otherwise
     */
    function _royaltyEnabled() internal view returns (bool _enabled) {
        _enabled = address(abRoyalty) != address(0);
    }

    function _beforeTokenTransfers(address _from, address _to, uint256, /* _startTokenId */ uint256 _quantity)
        internal
        override(ERC721AUpgradeable)
    {
        if (_royaltyEnabled()) abRoyalty.updatePayout721(_from, _to, _quantity);
    }
}
