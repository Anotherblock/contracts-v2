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
 * @title ERC1155ABWrapperBase
 * @author Anotherblock Technical Team
 * @notice Anotherblock ERC1155 contract standard used to wrap existing ERC1155
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/* Anotherblock Interfaces */
import {IABRoyalty} from "src/royalty/IABRoyalty.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";
import {IABHolderRegistry} from "src/utils/IABHolderRegistry.sol";

contract ERC1155ABWrapperBase is ERC1155Upgradeable, AccessControlUpgradeable {
    /**
     * @notice
     *  TokenDetails Structure format
     *
     * @param dropId drop identifier
     * @param uri token URI
     */
    struct TokenDetails {
        uint256 dropId;
        string uri;
    }

    /// @dev Error returned when the passed parameter is incorrect
    error INVALID_PARAMETER();

    /// @dev Event emitted upon drop initialization
    event DropInitialized(uint256 dropId, uint256 tokenId);

    /// @dev Event emitted upon wrapping of a token
    event Wrapped(uint256 tokenId, uint256 quantity, address user);

    /// @dev Event emitted upon unwrapping of a token
    event Unwrapped(uint256 tokenId, uint256 quantity, address user);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Anotherblock Drop Registry contract interface (see IABDataRegistry.sol)
    IABDataRegistry public abDataRegistry;

    /// @dev Anotherblock Holder Registry contract interface (see IABHolderRegistry.sol)
    IABHolderRegistry public abHolderRegistry;

    /// @dev Anotherblock Royalty contract interface (see IABRoyalty.sol)
    IABRoyalty public abRoyalty;

    /// @dev Publisher address
    address public publisher;

    /// @dev Original NFT collection address
    address public originalCollection;

    /// @dev Mapping storing the Token Details for a given Token ID
    mapping(uint256 tokenId => TokenDetails tokenDetails) public tokensDetails;

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
     * @param _originalCollection address of the NFT collection to be wrapped
     * @param _abDataRegistry address of ABDropRegistry contract
     * @param _abHolderRegistry address of ABHolderRegistry contract
     */
    function initialize(
        address _publisher,
        address _originalCollection,
        address _abDataRegistry,
        address _abHolderRegistry
    ) external initializer {
        // Initialize ERC1155
        __ERC1155_init("");

        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _publisher);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Assign the original collection address
        originalCollection = _originalCollection;

        // Assign ABDataRegistry address
        abDataRegistry = IABDataRegistry(_abDataRegistry);

        // Assign ABHolderRegistry address
        abHolderRegistry = IABHolderRegistry(_abHolderRegistry);

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
     *  Transfer `_quantity` of `_tokenId` of the wrapped collection from the caller and mint the same `_tokenId` of this collection
     *
     * @param _tokenId token identifier to be wrapped
     * @param _quantity quantity of token to be wrapped
     */
    function wrap(uint256 _tokenId, uint256 _quantity) external {
        // Transfer original NFT `_tokenId` from the caller to this contract
        IERC1155(originalCollection).safeTransferFrom(msg.sender, address(this), _tokenId, _quantity, "");

        // Check if the requested `_tokenId` has already been wrapped and unwrapped
        if (balanceOf(address(this), _tokenId) >= _quantity) {
            // Transfer pre-minted token ID of this collection
            safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, "");
        } else {
            // Mint `_quantity` of `_tokenId` to the caller address
            _mint(msg.sender, _tokenId, _quantity, "");
        }
        emit Wrapped(_tokenId, _quantity, msg.sender);
    }

    /**
     * @notice
     *  Transfer `_quantity` of `_tokenId` of this collection from the caller to this contract and tranfer the same `_tokenId` of the wrapped collection to the caller
     *
     * @param _tokenId token identifier to be unwrapped
     * @param _quantity quantity of token to be unwrapped
     */
    function unwrap(uint256 _tokenId, uint256 _quantity) external {
        safeTransferFrom(msg.sender, address(this), _tokenId, _quantity, "");
        IERC1155(originalCollection).safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, "");
        emit Unwrapped(_tokenId, _quantity, msg.sender);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        virtual
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
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
     * @param _tokenId token identifier
     * @param _uri token URI for this drop
     */
    function initDrop(uint256 _tokenId, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _initDrop(_tokenId, _uri);
    }

    /**
     * @notice
     *  Initialize multiple drops parameters
     *  Only the contract owner can perform this operation
     *
     * @param _tokenIds token identifiers
     * @param _uri token URI for this drop
     */
    function initDrop(uint256[] calldata _tokenIds, string[] calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = _tokenIds.length;

        if (length != _uri.length) {
            revert INVALID_PARAMETER();
        }

        for (uint256 i = 0; i < length; ++i) {
            _initDrop(_tokenIds[i], _uri[i]);
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
     * @param _tokenId token identifier
     * @param _uri token URI for this drop
     */
    function _initDrop(uint256 _tokenId, string memory _uri) internal {
        TokenDetails storage newTokenDetails = tokensDetails[_tokenId];

        // Register the drop and get an unique drop identifier
        uint256 dropId = abDataRegistry.registerDrop(publisher, _tokenId);

        // Set the drop identifier
        newTokenDetails.dropId = dropId;

        // Set Token URI
        newTokenDetails.uri = _uri;

        // Emit DropInitialized event
        emit DropInitialized(dropId, _tokenId);
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
            if (_to == address(this)) {
                // Redirect royalty to the publisher of this collection
                abHolderRegistry.registerHolderChange1155(_from, publisher, dropIds, _amounts);
            } else if (_from == address(this)) {
                // Redirect royalty from the publisher of this collection
                abHolderRegistry.registerHolderChange1155(publisher, _to, dropIds, _amounts);
            } else {
                abHolderRegistry.registerHolderChange1155(_from, _to, dropIds, _amounts);
            }
        } else {
            if (_to == address(this)) {
                // Redirect royalty to the publisher of this collection
                abRoyalty.updatePayout1155(_from, publisher, dropIds, _amounts);
            } else if (_from == address(this)) {
                // Redirect royalty from the publisher of this collection
                abRoyalty.updatePayout1155(publisher, _to, dropIds, _amounts);
            } else {
                abRoyalty.updatePayout1155(_from, _to, dropIds, _amounts);
            }
        }
    }
}