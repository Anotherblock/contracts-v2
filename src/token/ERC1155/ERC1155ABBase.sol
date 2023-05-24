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
 * @title ERC1155ABBase
 * @author Anotherblock Technical Team
 * @notice Anotherblock ERC1155 contract standard
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* Anotherblock Interfaces */
import {IABRoyalty} from "src/royalty/IABRoyalty.sol";
import {IABVerifier} from "src/utils/IABVerifier.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";
import {IABHolderRegistry} from "src/utils/IABHolderRegistry.sol";

contract ERC1155ABBase is ERC1155Upgradeable, AccessControlUpgradeable {
    /**
     * @notice
     *  TokenDetails Structure format
     *
     * @param dropId drop identifier
     * @param mintedSupply amount of tokens minted
     * @param maxSupply maximum supply
     * @param numOfPhase number of phases
     * @param phases mint phases (see phase structure format)
     * @param uri token URI
     */
    struct TokenDetails {
        uint256 dropId;
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
     * @param phaseEnd timestamp at which the phase ends
     * @param price price for one token during the phase
     * @param maxMint maximum number of token to be minted per user during the phase
     */
    struct Phase {
        uint256 phaseStart;
        uint256 phaseEnd;
        uint256 price;
        uint256 maxMint;
    }

    struct MintParams {
        uint256 tokenId;
        uint256 phaseId;
        uint256 quantity;
        bytes signature;
    }

    /// @dev Error returned if supply is insufficient
    error NOT_ENOUGH_TOKEN_AVAILABLE();

    /// @dev Error returned if user did not send the correct amount of ETH
    error INCORRECT_ETH_SENT();

    /// @dev Error returned if the requested phase is not active
    error PHASE_NOT_ACTIVE();

    /// @dev Error returned if user attempt to mint more than allowed
    error MAX_MINT_PER_ADDRESS();

    /// @dev Error returned if user is not eligible to mint during the current phase
    error NOT_ELIGIBLE();

    /// @dev Error returned when the passed parameter is incorrect
    error INVALID_PARAMETER();

    /// @dev Error returned if user attempt to mint while the phases are not set
    error PHASES_NOT_SET();

    /// @dev Error returned when the withdraw transfer fails
    error TRANSFER_FAILED();

    /// @dev Event emitted upon drop initialization
    event DropInitialized(uint256 dropId, uint256 tokenId);

    /// @dev Event emitted upon phase update
    event UpdatedPhase(uint256 numOfPhase);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Anotherblock Drop Registry contract interface (see IABDataRegistry.sol)
    IABDataRegistry public abDataRegistry;

    /// @dev Anotherblock Holder Registry contract interface (see IABHolderRegistry.sol)
    IABHolderRegistry public abHolderRegistry;

    /// @dev Anotherblock Verifier contract interface (see IABVerifier.sol)
    IABVerifier public abVerifier;

    /// @dev Anotherblock Royalty contract interface (see IABRoyalty.sol)
    IABRoyalty public abRoyalty;

    /// @dev Publisher address
    address public publisher;

    /// @dev Next Token ID available in this collection
    uint256 public nextTokenId;

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
     * @param _publisher publisher address
     * @param _abDataRegistry address of ABDropRegistry contract
     * @param _abHolderRegistry address of ABHolderRegistry contract
     * @param _abVerifier address of ABVerifier contract
     */
    function initialize(address _publisher, address _abDataRegistry, address _abHolderRegistry, address _abVerifier)
        external
        initializer
    {
        // Initialize ERC1155
        __ERC1155_init("");

        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _publisher);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize `nextTokenId`
        nextTokenId = 1;

        // Assign ABDataRegistry address
        abDataRegistry = IABDataRegistry(_abDataRegistry);

        // Assign ABHolderRegistry address
        abHolderRegistry = IABHolderRegistry(_abHolderRegistry);

        // Assign ABVerifier address
        abVerifier = IABVerifier(_abVerifier);

        // Assign the publisher address
        publisher = _publisher;
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
     * @param _mintParams mint parameters (see MintParams structure)
     */
    function mint(address _to, MintParams calldata _mintParams) external payable {
        // Get the Token Details for the requested tokenID
        TokenDetails storage tokenDetails = tokensDetails[_mintParams.tokenId];

        // Check that the phases are defined
        if (tokenDetails.numOfPhase == 0) revert PHASES_NOT_SET();

        // Check that the requested minting phase has started
        if (!_isPhaseActive(_mintParams.tokenId, _mintParams.phaseId)) revert PHASE_NOT_ACTIVE();

        // Get the requested phase details
        Phase memory phase = tokenDetails.phases[_mintParams.phaseId];

        // Check that there are enough tokens available for sale
        if (tokenDetails.mintedSupply + _mintParams.quantity > tokenDetails.maxSupply) {
            revert NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check that the user is included in the allowlist
        if (
            !abVerifier.verifySignature1155(
                _to, address(this), _mintParams.tokenId, _mintParams.phaseId, _mintParams.signature
            )
        ) {
            revert NOT_ELIGIBLE();
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_mintParams.tokenId][_mintParams.phaseId] + _mintParams.quantity > phase.maxMint) {
            revert MAX_MINT_PER_ADDRESS();
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _mintParams.quantity) {
            revert INCORRECT_ETH_SENT();
        }

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_mintParams.tokenId][_mintParams.phaseId] += _mintParams.quantity;

        // Update the minted supply for this token
        tokenDetails.mintedSupply += _mintParams.quantity;

        // Mint `_quantity` amount of `_tokenId` to `_to` address
        _mint(_to, _mintParams.tokenId, _mintParams.quantity, "");
    }

    /**
     * @notice
     *  Mint tokens in batch to `_to` address
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _mintParams mint parameters array (see MintParams structure)
     */
    function mintBatch(address _to, MintParams[] calldata _mintParams) external payable {
        uint256 length = _mintParams.length;

        uint256[] memory tokenIds = new uint256[](length);
        uint256[] memory quantities = new uint256[](length);

        uint256 totalCost = 0;

        TokenDetails storage tokenDetails;

        for (uint256 i = 0; i < length; ++i) {
            // Get the Token Details for the requested tokenID
            tokenDetails = tokensDetails[_mintParams[i].tokenId];

            // Check that the phases are defined
            if (tokenDetails.numOfPhase == 0) revert PHASES_NOT_SET();

            // Check that the requested minting phase has started
            if (!_isPhaseActive(_mintParams[i].tokenId, _mintParams[i].phaseId)) revert PHASE_NOT_ACTIVE();

            // Get the requested phase details
            Phase memory phase = tokenDetails.phases[_mintParams[i].phaseId];

            // Check that there are enough tokens available for sale
            if (tokenDetails.mintedSupply + _mintParams[i].quantity > tokenDetails.maxSupply) {
                revert NOT_ENOUGH_TOKEN_AVAILABLE();
            }

            // Check that the user is included in the allowlist
            if (
                !abVerifier.verifySignature1155(
                    _to, address(this), _mintParams[i].tokenId, _mintParams[i].phaseId, _mintParams[i].signature
                )
            ) {
                revert NOT_ELIGIBLE();
            }

            // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
            if (
                mintedPerPhase[_to][_mintParams[i].tokenId][_mintParams[i].phaseId] + _mintParams[i].quantity
                    > phase.maxMint
            ) {
                revert MAX_MINT_PER_ADDRESS();
            }

            // Set quantity minted for `_to` during the current phase
            mintedPerPhase[_to][_mintParams[i].tokenId][_mintParams[i].phaseId] += _mintParams[i].quantity;

            // Update the minted supply for this token
            tokenDetails.mintedSupply += _mintParams[i].quantity;

            // Increment total cost
            totalCost += phase.price * _mintParams[i].quantity;

            // Populate arrays used to mint ERC1155 in batch
            tokenIds[i] = _mintParams[i].tokenId;
            quantities[i] = _mintParams[i].quantity;
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != totalCost) {
            revert INCORRECT_ETH_SENT();
        }
        _mintBatch(_to, tokenIds, quantities, "");
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Initialize the drop parameters
     *  Only the contract owner can perform this operation
     *
     * @param _maxSupply supply cap for this drop
     * @param _mintGenesis amount of genesis tokens to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _uri token URI for this drop
     */
    function initDrop(uint256 _maxSupply, uint256 _mintGenesis, address _genesisRecipient, string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _initDrop(_maxSupply, _mintGenesis, _genesisRecipient, _uri);
    }

    /**
     * @notice
     *  Initialize multiple drops parameters
     *  Only the contract owner can perform this operation
     *
     * @param _maxSupply array of supply cap for this drop
     * @param _mintGenesis array of amount of genesis tokens to be minted
     * @param _genesisRecipient array of recipient address of genesis tokens
     * @param _uri array of token URI for this drop
     */
    function initDrop(
        uint256[] calldata _maxSupply,
        uint256[] calldata _mintGenesis,
        address[] calldata _genesisRecipient,
        string[] calldata _uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = _maxSupply.length;

        if (length != _mintGenesis.length || length != _genesisRecipient.length || length != _uri.length) {
            revert INVALID_PARAMETER();
        }

        for (uint256 i = 0; i < length; ++i) {
            _initDrop(_maxSupply[i], _mintGenesis[i], _genesisRecipient[i], _uri[i]);
        }
    }

    /**
     * @notice
     *  Initialize the royalty contract integration
     *  Only the contract owner can perform this operation
     *
     * @param _publisher publisher address
     * @param _royaltyCurrency royalty currency contract address
     * @param _tokenId token identifier to initialize royalty for
     */
    function initRoyalty(address _publisher, address _royaltyCurrency, uint256 _tokenId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        abRoyalty = IABRoyalty(abDataRegistry.getRoyaltyContract(_publisher));

        uint256 dropId = tokensDetails[_tokenId].dropId;

        // Initialize royalty payout index
        abRoyalty.initPayoutIndex(_royaltyCurrency, dropId);
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId : token ID for which the phases are set
     * @param _phases : array of phases to be set
     */
    function setDropPhases(uint256 _tokenId, Phase[] memory _phases) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Get the requested token details
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        uint256 previousPhaseStart = 0;

        uint256 length = _phases.length;
        for (uint256 i = 0; i < length; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order consistence)
            if (phase.phaseStart < previousPhaseStart || phase.phaseStart > phase.phaseEnd) {
                revert INVALID_PARAMETER();
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
    function withdrawToRightholder(address _rightholder, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_rightholder == address(0)) revert INVALID_PARAMETER();
        (bool success,) = _rightholder.call{value: _amount}("");
        if (!success) revert TRANSFER_FAILED();
    }

    /**
     * @notice
     *  Update the token URI
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId token ID to be updated
     * @param _uri new token URI to be set
     */
    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Initialize the Drop parameters
     *
     * @param _maxSupply supply cap for this drop
     * @param _mintGenesis amount of genesis tokens to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _uri token URI for this drop
     */
    function _initDrop(uint256 _maxSupply, uint256 _mintGenesis, address _genesisRecipient, string memory _uri)
        internal
    {
        TokenDetails storage newTokenDetails = tokensDetails[nextTokenId];

        // Register the drop and get an unique drop identifier
        uint256 dropId = abDataRegistry.registerDrop(publisher, nextTokenId);

        // Set the drop identifier
        newTokenDetails.dropId = dropId;

        // Set supply cap
        newTokenDetails.maxSupply = _maxSupply;

        // Set Token URI
        newTokenDetails.uri = _uri;

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_mintGenesis > 0) {
            // Check that the requested amount of genesis token does not exceed the supply cap
            if (_mintGenesis > _maxSupply) revert INVALID_PARAMETER();

            // Increment the amount of token minted
            newTokenDetails.mintedSupply += _mintGenesis;

            // Mint the genesis token(s) to the genesis recipient
            _mint(_genesisRecipient, nextTokenId, _mintGenesis, "");
        }

        // Emit DropInitialized event
        emit DropInitialized(dropId, nextTokenId);

        // Increment nextTokenId
        nextTokenId++;
    }

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
        Phase memory phase = tokensDetails[_tokenId].phases[_phaseId];

        // Check that the requested phase ID exists
        if (phase.phaseStart == 0) revert INVALID_PARAMETER();

        // Check if the requested phase has started
        _isActive = phase.phaseStart <= block.timestamp && phase.phaseEnd > block.timestamp;
    }

    function _beforeTokenTransfer(
        address, /* _operator */
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) internal override(ERC1155Upgradeable) {
        uint256 length = _tokenIds.length;

        uint256[] memory dropIds = new uint256[](_tokenIds.length);

        // Convert each token ID into its associated drop ID
        for (uint256 i = 0; i < length; ++i) {
            dropIds[i] = tokensDetails[_tokenIds[i]].dropId;
        }

        if (address(abRoyalty) == address(0)) {
            abHolderRegistry.registerHolderChange1155(_from, _to, dropIds, _amounts);
        } else {
            abRoyalty.updatePayout1155(_from, _to, dropIds, _amounts);
        }
    }
}