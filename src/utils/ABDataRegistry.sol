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
 * @title ABDataRegistry
 * @author Anotherblock Technical Team
 * @notice Anotherblock Data Registry contract responsible for housekeeping drops & publishers details
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ABDataRegistry is AccessControl {
    /**
     * @notice
     *  Drop Structure format
     *
     * @param dropId drop identifier
     * @param tokenId token identifier (0 if ERC-721)
     * @param publisher address of the drop publisher
     * @param nft NFT contract address
     */
    struct Drop {
        uint256 dropId;
        uint256 tokenId;
        address publisher;
        address nft;
    }

    /// @dev Error returned when caller is not authorized to perform operation
    error FORBIDDEN();

    /// @dev Event emitted when a new drop is registered
    event DropRegistered(uint256 dropId, uint256 tokenId, address nft, address publisher);

    /// @dev Event emitted when a new publisher is registered
    event PublisherRegistered(address account, address abRoyalty);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Collection identifier offset
    uint256 private immutable DROP_ID_OFFSET;

    /// @dev Mapping storing the allowed status of a given NFT contract
    mapping(address nft => bool isAllowed) private allowedNFT;

    /// @dev Mapping storing ABRoyalty contract address for a given publisher account
    mapping(address publisher => address abRoyalty) public publishers;

    /// @dev Array of all Drops (see Drop structure format)
    Drop[] public drops;

    /// @dev Collection Role
    bytes32 public constant COLLECTION_ROLE = keccak256("COLLECTION_ROLE");

    /// @dev Factory Role
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    constructor(uint256 _offset) {
        // Grant `DEFAULT_ADMIN_ROLE` to the sender
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        DROP_ID_OFFSET = _offset;
    }

    //     ____        __         ___                                         __
    //    / __ \____  / /_  __   /   |  ____  ____  _________ _   _____  ____/ /
    //   / / / / __ \/ / / / /  / /| | / __ \/ __ \/ ___/ __ \ | / / _ \/ __  /
    //  / /_/ / / / / / /_/ /  / ___ |/ /_/ / /_/ / /  / /_/ / |/ /  __/ /_/ /
    //  \____/_/ /_/_/\__, /  /_/  |_/ .___/ .___/_/   \____/|___/\___/\__,_/
    //               /____/         /_/   /_/

    /**
     * @notice
     *  Register a new drop
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _publisher address of the drop publisher
     * @param _tokenId token identifier (0 if ERC-721)
     *
     * @return _dropId identifier of the new drop
     */
    function registerDrop(address _publisher, uint256 _tokenId)
        external
        onlyRole(COLLECTION_ROLE)
        returns (uint256 _dropId)
    {
        // Get the next drop identifier available
        _dropId = _getNextDropId();

        // Store the new drop details in the drops array
        drops.push(Drop(_dropId, _tokenId, _publisher, msg.sender));

        // Emit the DropRegistered event
        emit DropRegistered(_dropId, _tokenId, msg.sender, _publisher);
    }

    /**
     * @notice
     *  Register a new publisher
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _publisher address of the publisher
     * @param _abRoyalty address of ABRoyalty contract associated to this publisher
     *
     */
    function registerPublisher(address _publisher, address _abRoyalty) external onlyRole(FACTORY_ROLE) {
        // Store the new publisher ABRoyalty contract address
        publishers[_publisher] = _abRoyalty;

        // Emit the PublisherRegistered event
        emit PublisherRegistered(_publisher, _abRoyalty);
    }

    /**
     * @notice
     *  Set allowed status to true for the given `_collection` contract address
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _collection nft contract address to be granted with the collection role
     */

    function grantCollectionRole(address _collection) external onlyRole(FACTORY_ROLE) {
        // Grant `COLLECTION_ROLE` to the given `_collection`
        _grantRole(COLLECTION_ROLE, _collection);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Return true if `_account` is a publisher, false otherwise
     *
     * @param _account address to be queried
     *
     * @return _isPublisher true if `_account` is a publisher, false otherwise
     */
    function isPublisher(address _account) external view returns (bool _isPublisher) {
        _isPublisher = publishers[_account] != address(0);
    }

    /**
     * @notice
     *  Return the royalty contract address associated to the given `_publisher`
     *
     * @param _publisher publisher to be queried
     *
     * @return _royalty the royalty contract address associated to the given `_publisher`
     */
    function getRoyaltyContract(address _publisher) external view returns (address _royalty) {
        _royalty = publishers[_publisher];
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Calculate and return the next drop ID available
     *
     * @return _nextDropId next drop ID available
     */
    function _getNextDropId() internal view returns (uint256 _nextDropId) {
        _nextDropId = DROP_ID_OFFSET + drops.length + 1;
    }
}
