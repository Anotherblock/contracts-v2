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
 * @title ERC721ABWrapper
 * @author Anotherblock Technical Team
 * @notice Anotherblock ERC721 contract standard used to wrap existing ERC721
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* ERC721 Contract */

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/* Anotherblock Interfaces */
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";
import {IABDataRegistry} from "./interfaces/IABDataRegistry.sol";

contract ERC721ABWrapper is ERC721Upgradeable, OwnableUpgradeable {
    /// @dev Error returned if the drop has already been initialized
    error DROP_ALREADY_INITIALIZED();

    /// @dev Error returned when the passed parameter is incorrect
    error INVALID_PARAMETER();

    /// @dev Event emitted upon wrapping of a token
    event Wrapped(uint256 tokenId, address user);

    /// @dev Event emitted upon unwrapping of a token
    event Unwrapped(uint256 tokenId, address user);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Anotherblock Drop Registry contract interface (see IABDataRegistry.sol)
    IABDataRegistry public abDataRegistry;

    /// @dev Anotherblock Royalty contract interface (see IABRoyalty.sol)
    IABRoyalty public abRoyalty;

    /// @dev Original NFT collection address
    address public originalCollection;

    /// @dev Drop Identifier
    uint256 public dropId;

    /// @dev Base Token URI
    string private baseTokenURI;

    mapping(uint256 tokenId => bool status) public minted;

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
     * @param _originalCollection address of the NFT collection to be wrapped
     * @param _abDataRegistry address of ABDropRegistry contract
     * @param _name NFT collection name
     * @param _symbol NFT collection symbol
     */
    function initialize(
        address _originalCollection,
        address _abDataRegistry,
        string memory _name,
        string memory _symbol
    ) external initializer {
        // Initialize ERC721
        __ERC721_init(_name, _symbol);

        // Initialize Ownable
        __Ownable_init();

        dropId = 0;

        // Assign the original collection address
        originalCollection = _originalCollection;

        // Assign ABDataRegistry address
        abDataRegistry = IABDataRegistry(_abDataRegistry);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Transfer `_tokenId` of the wrapped collection from the caller and mint the same `_tokenId` of this collection
     *
     * @param _tokenId token identifier to be wrapped
     */
    function wrap(uint256 _tokenId) external {
        // Transfer original NFT `_tokenId` from the caller to this contract
        IERC721(originalCollection).transferFrom(msg.sender, address(this), _tokenId);

        // Check if the requested `_tokenId` has already been wrapped and unwrapped
        if (_alreadyExists(_tokenId)) {
            // Transfer pre-minted token ID of this collection
            transferFrom(address(this), msg.sender, _tokenId);
        } else {
            minted[_tokenId] = true;

            // Mint `_tokenId` to `_to` address
            _mint(msg.sender, _tokenId);
        }
        emit Wrapped(_tokenId, msg.sender);
    }

    /**
     * @notice
     *  Transfer `_tokenId` of this collection from the caller to this contract and tranfer the same `_tokenId` of the wrapped collection to the caller
     *
     * @param _tokenId token identifier to be wrapped
     */
    function unwrap(uint256 _tokenId) external {
        transferFrom(msg.sender, address(this), _tokenId);
        IERC721(originalCollection).transferFrom(address(this), msg.sender, _tokenId);
        emit Unwrapped(_tokenId, msg.sender);
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
     * @param _royaltyCurrency royalty currency contract address
     * @param _baseUri base URI for this drop
     */
    function initDrop(address _royaltyCurrency, string calldata _baseUri) external onlyOwner {
        // Check that the drop hasn't been already initialized
        if (dropId != 0) revert DROP_ALREADY_INITIALIZED();

        // Register Drop within ABDropRegistry
        dropId = abDataRegistry.registerDrop(address(this), owner(), 0);

        abRoyalty = IABRoyalty(abDataRegistry.getRoyaltyContract(msg.sender));

        // Initialize royalty payout index
        abRoyalty.initPayoutIndex(_royaltyCurrency, dropId);

        // Set base URI
        baseTokenURI = _baseUri;
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

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the base URI
     *
     * @return _URI token URI state
     */
    function _baseURI() internal view virtual override returns (string memory _URI) {
        _URI = baseTokenURI;
    }

    function _alreadyExists(uint256 _tokenId) internal view returns (bool _exists) {
        _exists = minted[_tokenId];
    }

    function _beforeTokenTransfer(address _from, address _to, uint256, uint256) internal override(ERC721Upgradeable) {
        if (_to == address(this)) {
            // Redirect royalty to the publisher of this collection
            abRoyalty.updatePayout721(_from, owner(), dropId, 1);
        } else if (_from == address(this)) {
            // Redirect royalty from the publisher of this collection
            abRoyalty.updatePayout721(owner(), _to, dropId, 1);
        } else {
            abRoyalty.updatePayout721(_from, _to, dropId, 1);
        }
    }
}
