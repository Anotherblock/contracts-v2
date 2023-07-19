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
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* Anotherblock Libraries */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

/* Anotherblock Interfaces */
import {IABRoyalty} from "src/royalty/IABRoyalty.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";

contract ABDataRegistry is IABDataRegistry, AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Collection identifier offset
    uint256 private DROP_ID_OFFSET;

    /// @dev Mapping storing ABRoyalty contract address for a given publisher account
    mapping(address publisher => address abRoyalty) public publishers;

    /// @dev Mapping storing Publisher Fee for a given publisher account
    mapping(address publisher => uint256 fee) public publisherFees;

    /// @dev Array of all Drops (see Drop structure format)
    ABDataTypes.Drop[] public drops;

    /// @dev Anotherblock treasury address
    address public abTreasury;

    /// @dev Collection Role
    bytes32 public constant COLLECTION_ROLE = keccak256("COLLECTION_ROLE");

    /// @dev Factory Role
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

    /**
     * @notice
     *  Contract Initializer
     */
    function initialize(uint256 _offset, address _abTreasury) external initializer {
        // Initialize Access Control
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        DROP_ID_OFFSET = _offset;
        abTreasury = _abTreasury;

        emit ABEvents.DataRegistryInitialized(_abTreasury, _offset);
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
     * @param _royaltyCurrency royalty currency contract address
     * @param _tokenId token identifier (0 if ERC-721)
     *
     * @return _dropId identifier of the new drop
     */
    function registerDrop(address _publisher, address _royaltyCurrency, uint256 _tokenId)
        external
        onlyRole(COLLECTION_ROLE)
        returns (uint256 _dropId)
    {
        // Get the next drop identifier available
        _dropId = _getNextDropId();

        // Store the new drop details in the drops array
        drops.push(ABDataTypes.Drop(_dropId, _tokenId, _publisher, msg.sender));

        // Emit the DropRegistered event
        emit ABEvents.DropRegistered(_dropId, _tokenId, msg.sender, _publisher);

        if (_royaltyCurrency != address(0)) {
            // Initialize royalty payout index
            IABRoyalty(publishers[_publisher]).initPayoutIndex(msg.sender, _royaltyCurrency, _dropId);
        }
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
    function registerPublisher(address _publisher, address _abRoyalty, uint256 _publisherFee)
        external
        onlyRole(FACTORY_ROLE)
    {
        if (publishers[_publisher] != address(0)) revert ABErrors.ACCOUNT_ALREADY_PUBLISHER();

        // Store the new publisher ABRoyalty contract address
        publishers[_publisher] = _abRoyalty;

        // Store the publisher fees
        publisherFees[_publisher] = _publisherFee;

        // Emit the PublisherRegistered event
        emit ABEvents.PublisherRegistered(_publisher, _abRoyalty);
    }

    /**
     * @notice
     *  Update the subscription units on ERC721 token transfer
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _publisher publisher address
     * @param _from previous holder address
     * @param _to new holder address
     * @param _dropId drop identifier
     * @param _quantity quantity of tokens transferred
     */
    function on721TokenTransfer(address _publisher, address _from, address _to, uint256 _dropId, uint256 _quantity)
        external
        onlyRole(COLLECTION_ROLE)
    {
        IABRoyalty abRoyalty = IABRoyalty(publishers[_publisher]);
        abRoyalty.updatePayout721(_from, _to, _dropId, _quantity);
    }

    /**
     * @notice
     *  Distribute the royalty for the given Drop ID on behalf of the publisher
     *  Only contract owner can perform this operation
     *
     * @param _publisher publisher address corresponding to the drop id to be paid-out
     * @param _dropId drop identifier
     * @param _amount amount to be paid-out
     */
    function distributeOnBehalf(address _publisher, uint256 _dropId, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IABRoyalty abRoyalty = IABRoyalty(publishers[_publisher]);
        if (address(abRoyalty) == address(0)) revert ABErrors.INVALID_PARAMETER();
        abRoyalty.distributeOnBehalf(_dropId, _amount);
    }

    /**
     * @notice
     *  Update the subscription units on ERC721 token transfer
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _publisher publisher address
     * @param _from previous holder address
     * @param _to new holder address
     * @param _dropIds array of drop identifier
     * @param _quantities array of quantities
     */

    function on1155TokenTransfer(
        address _publisher,
        address _from,
        address _to,
        uint256[] memory _dropIds,
        uint256[] memory _quantities
    ) external onlyRole(COLLECTION_ROLE) {
        IABRoyalty abRoyalty = IABRoyalty(publishers[_publisher]);
        abRoyalty.updatePayout1155(_from, _to, _dropIds, _quantities);
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

    /**
     * @notice
     *  Set the treasury account address
     *  Only contract owner can perform this operation
     *
     * @param _abTreasury the treasury account address to be set
     */
    function setTreasury(address _abTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        abTreasury = _abTreasury;
    }

    /**
     * @notice
     *  Update a publisher fee
     *  Only contract owner can perform this operation
     *
     * @param _publisher publisher account to be updated
     * @param _fee new fees to be set
     */
    function setPublisherFee(address _publisher, uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publisherFees[_publisher] = _fee;
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

    /**
     * @notice
     *  Return the fee percentage associated to the given `_publisher`
     *
     * @param _publisher publisher to be queried
     *
     * @return _fee the fees associated to the given `_publisher`
     */
    function getPublisherFee(address _publisher) external view returns (uint256 _fee) {
        _fee = publisherFees[_publisher];
    }

    /**
     * @notice
     *  Return the details required to withdraw the mint proceeds
     *
     * @param _publisher publisher to be queried
     *
     * @return _treasury the treasury account address
     * @return _fee the fees associated to the given `_publisher`
     */
    function getPayoutDetails(address _publisher) external view returns (address _treasury, uint256 _fee) {
        _treasury = abTreasury;
        _fee = publisherFees[_publisher];
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
