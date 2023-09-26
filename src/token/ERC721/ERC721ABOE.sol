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
 * @title ERC721ABOE
 * @author anotherblock Technical Team
 * @notice anotherblock ERC721 Open Edition contract standard
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* ERC721A Contract */
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/* anotherblock Libraries */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

/* anotherblock Interfaces */
import {IABVerifier} from "src/utils/IABVerifier.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";

contract ERC721ABOE is ERC721AUpgradeable, OwnableUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev anotherblock Drop Registry contract interface (see IABDataRegistry.sol)
    IABDataRegistry public abDataRegistry;

    /// @dev anotherblock Verifier contract interface (see IABVerifier.sol)
    IABVerifier public abVerifier;

    /// @dev Publisher address
    address public publisher;

    /// @dev Drop Identifier
    uint256 public dropId;

    /// @dev Percentage ownership of the full master right for one token (to be divided by 1e6)
    uint256 public sharePerToken;

    /// @dev Base Token URI
    string internal baseTokenURI;

    /// @dev Dynamic array of phases
    ABDataTypes.Phase[] public phases;

    /// @dev Mapping storing the amount minted per wallet and per phase
    mapping(address user => mapping(uint256 phaseId => uint256 minted)) public mintedPerPhase;

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

    /**
     * @notice
     *  Contract Initializer (Minimal Proxy Contract)
     *
     * @param _publisher publisher address of this collection
     * @param _abDataRegistry ABDropRegistry contract address
     * @param _abVerifier ABVerifier contract address
     * @param _name NFT collection name
     */
    function initialize(address _publisher, address _abDataRegistry, address _abVerifier, string memory _name)
        external
        initializerERC721A
        initializer
    {
        // Initialize ERC721A
        __ERC721A_init(_name, "");

        // Initialize Ownable
        __Ownable_init();
        _transferOwnership(_publisher);

        dropId = 0;

        // Assign ABDataRegistry address
        abDataRegistry = IABDataRegistry(_abDataRegistry);

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
     *  Mint `_quantity` tokens to `_to` address based on the current `_phaseId` if `_signature` is valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _phaseId current minting phase (must be started)
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     */
    function mint(address _to, uint256 _phaseId, uint256 _quantity, bytes calldata _signature) external payable {
        // Check that the requested minting phase has started
        if (!_isPhaseActive(_phaseId)) revert ABErrors.PHASE_NOT_ACTIVE();

        // Get requested phase details
        ABDataTypes.Phase memory phase = phases[_phaseId];

        // Check if the current phase is private
        if (!phase.isPublic) {
            // Check that the user is included in the allowlist
            if (!abVerifier.verifySignature721(_to, address(this), _phaseId, _signature)) {
                revert ABErrors.NOT_ELIGIBLE();
            }
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_phaseId] + _quantity > phase.maxMint) revert ABErrors.MAX_MINT_PER_ADDRESS();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert ABErrors.INCORRECT_ETH_SENT();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_phaseId] += _quantity;

        // Mint `_quantity` amount to `_to` address
        _mint(_to, _quantity);
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
     * @param _sharePerToken percentage ownership of the full master right for one token (to be divided by 1e6)
     * @param _mintGenesis amount of genesis tokens to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _royaltyCurrency royalty currency contract address
     * @param _baseUri base URI for this drop
     */
    function initDrop(
        uint256,
        uint256 _sharePerToken,
        uint256 _mintGenesis,
        address _genesisRecipient,
        address _royaltyCurrency,
        string calldata _baseUri
    ) external virtual onlyOwner {
        // Check that the drop hasn't been already initialized
        if (dropId != 0) revert ABErrors.DROP_ALREADY_INITIALIZED();

        // Check that share per token & royalty currency are consistent
        if (
            (_sharePerToken == 0 && _royaltyCurrency != address(0))
                || (_royaltyCurrency == address(0) && _sharePerToken != 0)
        ) revert ABErrors.INVALID_PARAMETER();

        // Register Drop within ABDropRegistry
        dropId = abDataRegistry.registerDrop(publisher, _royaltyCurrency, 0);

        // Set the royalty share
        sharePerToken = _sharePerToken;

        // Set base URI
        baseTokenURI = _baseUri;

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_mintGenesis > 0) {
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
     *  Update the share per token percentage
     *  Only the contract owner can perform this operation
     *
     * @param _newSharePerToken new share per token value
     */
    function setSharePerToken(uint256 _newSharePerToken) external onlyOwner {
        sharePerToken = _newSharePerToken;
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *  Only the contract owner can perform this operation
     *
     * @param _phases array of phases to be set (see Phase structure format)
     */

    function setDropPhases(ABDataTypes.Phase[] calldata _phases) external onlyOwner {
        // Delete previously set phases (if any)
        if (phases.length > 0) {
            delete phases;
        }

        uint256 previousPhaseStart = 0;

        uint256 numOfPhase = _phases.length;

        for (uint256 i = 0; i < numOfPhase; ++i) {
            ABDataTypes.Phase memory phase = _phases[i];

            // Check parameter correctness (phase order)
            if (phase.phaseStart < previousPhaseStart || phase.phaseStart > phase.phaseEnd) {
                revert ABErrors.INVALID_PARAMETER();
            }

            phases.push(phase);
            previousPhaseStart = phase.phaseStart;
        }

        emit ABEvents.UpdatedPhase(numOfPhase);
    }

    /**
     * @notice
     *  Withdraw the mint proceeds
     *  Only the contract owner can perform this operation
     *
     */
    function withdrawToRightholder() external onlyOwner {
        (address abTreasury, uint256 fee) = abDataRegistry.getPayoutDetails(publisher);

        if (abTreasury == address(0)) revert ABErrors.INVALID_PARAMETER();

        uint256 balance = address(this).balance;
        uint256 amountToRH = balance * fee / 10_000;
        uint256 amountToTreasury = balance - amountToRH;

        if (amountToTreasury > 0) {
            (bool success,) = abTreasury.call{value: amountToTreasury}("");
            if (!success) revert ABErrors.TRANSFER_FAILED();
        }

        if (amountToRH > 0) {
            (bool success,) = publisher.call{value: amountToRH}("");
            if (!success) revert ABErrors.TRANSFER_FAILED();
        }
    }

    /**
     * @notice
     *  Withdraw ERC20 tokens from this contract to the caller
     *  Only the contract owner can perform this operation
     *
     * @param _token token contract address to be withdrawn
     * @param _amount amount to be withdrawn
     */
    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        // Transfer amount of underlying token to the caller
        IERC20(_token).transfer(msg.sender, _amount);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice
     *  Returns the NFT symbol
     *
     * @return _symbol NFT symbol
     */
    function symbol() public view virtual override returns (string memory _symbol) {
        if (dropId != 0) {
            _symbol = string.concat("AB", Strings.toString(dropId));
        }
    }

    /**
     * @notice
     *  Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param _tokenId token identifier to be queried
     *
     * @return _tokenURI the token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory _tokenURI) {
        if (!_exists(_tokenId)) revert ABErrors.INVALID_PARAMETER();

        string memory baseURI = _baseURI();

        if (bytes(baseURI).length == 0) {
            _tokenURI = "";
        } else {
            bytes memory lastByte = new bytes(1);

            lastByte[0] = bytes(baseURI)[bytes(baseURI).length - 1];
            string memory lastChar = string(lastByte);

            if (keccak256(abi.encodePacked(lastChar)) == keccak256(abi.encodePacked("/"))) {
                _tokenURI = string(abi.encodePacked(baseURI, _toString(_tokenId)));
            } else {
                _tokenURI = baseURI;
            }
        }
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
        if (_phaseId >= phases.length) revert ABErrors.INVALID_PARAMETER();
        ABDataTypes.Phase memory phase = phases[_phaseId];
        // Check if the requested phase has started
        _isActive = phase.phaseStart <= block.timestamp && phase.phaseEnd > block.timestamp;
    }

    /**
     * @notice
     *  Returns the base URI
     *
     * @return _uri token URI state
     */
    function _baseURI() internal view virtual override returns (string memory _uri) {
        _uri = baseTokenURI;
    }

    /**
     * @notice
     *  Returns the starting token ID
     *
     * @return _firstTokenId start token index
     */
    function _startTokenId() internal view virtual override returns (uint256 _firstTokenId) {
        _firstTokenId = 1;
    }

    function _beforeTokenTransfers(address _from, address _to, uint256, /* _startTokenId */ uint256 _quantity)
        internal
        override(ERC721AUpgradeable)
    {
        if (sharePerToken > 0) {
            abDataRegistry.on721TokenTransfer(publisher, _from, _to, dropId, _quantity);
        }
    }
}
