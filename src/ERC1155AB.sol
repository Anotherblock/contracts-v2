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
 * @title ERC1155AB
 * @author Anotherblock Technical Team
 * @notice Anotherblock ERC1155 contract standard
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* Anotherblock Interfaces */
import {IABVerifier} from "./interfaces/IABVerifier.sol";
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";

contract ERC1155AB is ERC1155Upgradeable, OwnableUpgradeable {
    /**
     * @notice
     *  TokenDetails Structure format
     *
     * @param mintedSupply amount of tokens minted
     * @param maxSupply maximum supply
     * @param numOfPhase number of phases
     * @param phases mint phases (see phase structure format)
     * @param uri token URI
     */
    struct TokenDetails {
        uint256 mintedSupply;
        uint256 maxSupply;
        uint256 numOfPhase;
        mapping(uint256 phaseId => Phase phase) phases;
        string uri;
    }

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

    /// @dev Number of Token ID available in this collection
    uint256 public tokenCount;

    /// @dev Mapping storing the Token Details for a given Token ID
    mapping(uint256 tokenId => TokenDetails tokenDetails) public tokensDetails;

    ///@dev Mapping storing the amount of token(s) minted per wallet and per phase
    mapping(address user => mapping(uint256 tokenId => mapping(uint256 phaseId => uint256 minted))) public
        mintedPerPhase;

    ///@dev ERC1155AB implementation version
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
     */
    function initialize(address _abRoyalty, address _abVerifier) external initializer {
        // Initialize ERC1155
        __ERC1155_init("");

        // Initialize Ownable
        __Ownable_init();

        // Initialize `tokenCount`
        tokenCount = 0;

        // Assign ABVerifier address
        abVerifier = IABVerifier(_abVerifier);

        // Assign ABRoyalty address
        abRoyalty = IABRoyalty(_abRoyalty);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Mint `_quantity` tokens of `_tokenId` to `_to` address based on the current `_phaseId` if `_signature` is valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _tokenId requested token identifier
     * @param _phaseId current minting phase (must be started)
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     */
    function mint(address _to, uint256 _tokenId, uint256 _phaseId, uint256 _quantity, bytes calldata _signature)
        external
        payable
    {
        // Check that the requested tokenID exists within the collection
        if (_tokenId >= tokenCount) revert InvalidParameter();

        // Get the Token Details for the requested tokenID
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        // Check that the phases are defined
        if (tokenDetails.numOfPhase == 0) revert PhasesNotSet();

        // Check that the requested minting phase has started
        if (!_isPhaseActive(_tokenId, _phaseId)) revert PhaseNotActive();

        // Get the requested phase details
        Phase memory phase = tokenDetails.phases[_phaseId];

        // Check that the drop is not sold-out
        if (tokenDetails.mintedSupply == tokenDetails.maxSupply) {
            revert DropSoldOut();
        }

        // Check that there are enough tokens available for sale
        if (tokenDetails.mintedSupply + _quantity > tokenDetails.maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        // Check that the user is included in the allowlist
        if (!abVerifier.verifySignature1155(_to, address(this), _tokenId, _phaseId, _signature)) {
            revert NotEligible();
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_tokenId][_phaseId] + _quantity > phase.maxMint) revert MaxMintPerAddress();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) {
            revert IncorrectETHSent();
        }

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_tokenId][_phaseId] += _quantity;

        // Update the minted supply for this token
        tokenDetails.mintedSupply += _quantity;

        // Mint `_quantity` amount of `_tokenId` to `_to` address
        _mint(_to, _tokenId, _quantity, "");
    }

    // function mintBatch(address _to, uint256[] memory _tokenIds, uint256[] memory _quantities) external payable {
    //     _mintBatch(_to, _tokenIds, _quantities, "");
    // }

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
     * @param _uri token URI for this drop
     */
    function initDrop(uint256 _maxSupply, uint256 _mintGenesis, address _genesisRecipient, string memory _uri)
        external
        onlyOwner
    {
        TokenDetails storage newTokenDetails = tokensDetails[tokenCount];

        // Set supply cap
        newTokenDetails.maxSupply = _maxSupply;

        // Set Token URI
        newTokenDetails.uri = _uri;

        // Check if the collection pays-out royalty
        if (_royaltyEnabled()) {
            // Initialize payout index
            abRoyalty.initPayoutIndex(uint32(tokenCount));
        }

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_mintGenesis > 0) {
            if (_mintGenesis > _maxSupply) revert InvalidParameter();
            tokensDetails[tokenCount].mintedSupply += _mintGenesis;
            _mint(_genesisRecipient, tokenCount, _mintGenesis, "");
        }

        // Increment tokenDetails count
        tokenCount++;
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId : token ID for which the phases are set
     * @param _phases : array of phases to be set
     */
    function setDropPhases(uint256 _tokenId, Phase[] memory _phases) external onlyOwner {
        // Get the requested token details
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        uint256 previousPhaseStart = 0;

        uint256 length = _phases.length;
        for (uint256 i = 0; i < length; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order consistence)
            if (phase.phaseStart <= previousPhaseStart) {
                revert InvalidParameter();
            }

            // Set the phase
            tokenDetails.phases[i] = phase;
            previousPhaseStart = phase.phaseStart;
        }

        // Set the number of phase
        tokenDetails.numOfPhase = _phases.length;

        emit UpdatedPhase(length);
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

    /**
     * @notice
     *  Update the token URI
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId token ID to be updated
     * @param _uri new token URI to be set
     */
    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
        tokensDetails[_tokenId].uri = _uri;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the token URI
     *
     * @param _tokenId requested token ID
     *
     * @return _tokenURI token URI
     */
    function uri(uint256 _tokenId) public view override returns (string memory _tokenURI) {
        _tokenURI = tokensDetails[_tokenId].uri;
    }

    /**
     * @notice
     *  Returns `_phaseId` phase details for `_tokenId`
     *
     * @param _tokenId requested token ID
     * @param _phaseId requested phase ID
     *
     * @return _phase phase details
     */
    function getPhaseInfo(uint256 _tokenId, uint256 _phaseId) public view returns (Phase memory _phase) {
        _phase = tokensDetails[_tokenId].phases[_phaseId];
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
     * @param _tokenId requested token ID
     * @param _phaseId requested phase ID
     *
     * @return _isActive true if phase is active, false otherwise
     */
    function _isPhaseActive(uint256 _tokenId, uint256 _phaseId) internal view returns (bool _isActive) {
        uint256 _phaseStart = tokensDetails[_tokenId].phases[_phaseId].phaseStart;

        // Check that the requested phase ID exists
        if (_phaseStart == 0) revert InvalidParameter();

        // Check if the requested phase has started
        _isActive = _phaseStart <= block.timestamp;
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

    function _beforeTokenTransfer(
        address, /* _operator */
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) internal override(ERC1155Upgradeable) {
        if (_royaltyEnabled()) {
            abRoyalty.updatePayout1155(_from, _to, _tokenIds, _amounts);
        }
    }
}
