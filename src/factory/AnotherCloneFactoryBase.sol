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
 * @title AnotherCloneFactory
 * @author Anotherblock Technical Team
 * @notice Contract responsible for deploying new Anotherblock collections for Base
 *
 */

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/* Anotherblock Contract */
import {ERC721ABBase} from "src/token/ERC721/ERC721ABBase.sol";
import {ERC721ABWrapperBase} from "src/token/ERC721/ERC721ABWrapperBase.sol";
import {ERC1155ABBase} from "src/token/ERC1155/ERC1155ABBase.sol";
import {ERC1155ABWrapperBase} from "src/token/ERC1155/ERC1155ABWrapperBase.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";
import {IABHolderRegistry} from "src/utils/IABHolderRegistry.sol";

contract AnotherCloneFactoryBase is AccessControl {
    /// @dev Error returned when the passed parameters are invalid
    error INVALID_PARAMETER();

    /// @dev Error returned when caller is not authorized to perform operation
    error FORBIDDEN();

    /// @dev Event emitted when a new collection is created
    event CollectionCreated(address nft, address publisher);

    /**
     * @notice
     *  Collection Structure format
     *
     * @param nft nft contract address
     * @param publisher publisher address
     */
    struct Collection {
        address nft;
        address publisher;
    }

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Array of all Collection created by this factory
    Collection[] public collections;

    /// @dev ABDropRegistry contract interface
    IABDataRegistry public abDataRegistry;

    /// @dev Anotherblock Holder Registry contract interface (see IABHolderRegistry.sol)
    IABHolderRegistry public abHolderRegistry;

    /// @dev ABVerifier contract address
    address public abVerifier;

    /// @dev Standard Anotherblock ERC721 contract implementation address
    address public erc721BaseImpl;

    /// @dev Standard Anotherblock ERC721 Wrapper contract implementation address
    address public erc721WrapperBaseImpl;

    /// @dev Standard Anotherblock ERC1155 contract implementation address
    address public erc1155BaseImpl;

    /// @dev Standard Anotherblock ERC1155 Wrapper contract implementation address
    address public erc1155WrapperBaseImpl;

    /// @dev Publisher Role
    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /**
     * @notice
     *  Contract Constructor
     *
     * @param _abDataRegistry address of ABDropRegistry contract
     * @param _abHolderRegistry address of ABHolderRegistry contract
     * @param _abVerifier address of ABVerifier contract
     * @param _erc721BaseImpl address of ERC721AB implementation
     * @param _erc721WrapperBaseImpl address of ERC721ABWrapperBase implementation
     * @param _erc1155BaseImpl address of ERC1155ABBase implementation
     * @param _erc1155WrapperBaseImpl address of ERC1155ABWrapperBase implementation
     */
    constructor(
        address _abDataRegistry,
        address _abHolderRegistry,
        address _abVerifier,
        address _erc721BaseImpl,
        address _erc721WrapperBaseImpl,
        address _erc1155BaseImpl,
        address _erc1155WrapperBaseImpl
    ) {
        abDataRegistry = IABDataRegistry(_abDataRegistry);
        abHolderRegistry = IABHolderRegistry(_abHolderRegistry);
        abVerifier = _abVerifier;
        erc721BaseImpl = _erc721BaseImpl;
        erc721WrapperBaseImpl = _erc721WrapperBaseImpl;
        erc1155BaseImpl = _erc1155BaseImpl;
        erc1155WrapperBaseImpl = _erc1155WrapperBaseImpl;

        // Access control initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //     ____        __         ___                                         __
    //    / __ \____  / /_  __   /   |  ____  ____  _________ _   _____  ____/ /
    //   / / / / __ \/ / / / /  / /| | / __ \/ __ \/ ___/ __ \ | / / _ \/ __  /
    //  / /_/ / / / / / /_/ /  / ___ |/ /_/ / /_/ / /  / /_/ / |/ /  __/ /_/ /
    //  \____/_/ /_/_/\__, /  /_/  |_/ .___/ .___/_/   \____/|___/\___/\__,_/
    //               /____/         /_/   /_/

    /**
     * @notice
     *  Create new ERC721 collection
     *  Only the caller with role `PUBLISHER_ROLE` can perform this operation
     *
     * @param _name collection name
     * @param _symbol collection symbol
     * @param _salt bytes used for deterministic deployment
     */
    function createCollection721(string memory _name, string memory _symbol, bytes32 _salt)
        external
        onlyRole(PUBLISHER_ROLE)
    {
        // Create new NFT contract
        ERC721ABBase newCollection = ERC721ABBase(Clones.cloneDeterministic(erc721BaseImpl, _salt));

        // Initialize NFT contract
        newCollection.initialize(
            msg.sender, address(abDataRegistry), address(abHolderRegistry), abVerifier, _name, _symbol
        );

        // Setup collection
        _setupCollection(address(newCollection), msg.sender);
    }

    /**
     * @notice
     *  Create new ERC721 Wrapper collection
     *  Only the caller with role `PUBLISHER_ROLE` can perform this operation
     *
     * @param _originalCollection original collection contract address
     * @param _name collection name
     * @param _symbol collection symbol
     * @param _salt bytes used for deterministic deployment
     */
    function createWrappedCollection721(
        address _originalCollection,
        string memory _name,
        string memory _symbol,
        bytes32 _salt
    ) external onlyRole(PUBLISHER_ROLE) {
        // Create new NFT contract
        ERC721ABWrapperBase newCollection = ERC721ABWrapperBase(Clones.cloneDeterministic(erc721WrapperBaseImpl, _salt));

        // Initialize NFT contract
        newCollection.initialize(
            msg.sender, _originalCollection, address(abDataRegistry), address(abHolderRegistry), _name, _symbol
        );

        // Setup collection
        _setupCollection(address(newCollection), msg.sender);
    }

    /**
     * @notice
     *  Create new ERC1155 collection
     *  Only the caller with role `PUBLISHER_ROLE` can perform this operation
     *
     * @param _salt bytes used for deterministic deployment
     */
    function createCollection1155(bytes32 _salt) external onlyRole(PUBLISHER_ROLE) {
        // Create new NFT contract
        ERC1155ABBase newCollection = ERC1155ABBase(Clones.cloneDeterministic(erc1155BaseImpl, _salt));

        // Initialize NFT contract
        newCollection.initialize(msg.sender, address(abDataRegistry), address(abHolderRegistry), abVerifier);

        // Setup collection
        _setupCollection(address(newCollection), msg.sender);
    }

    /**
     * @notice
     *  Create new ERC1155 collection
     *  Only the caller with role `PUBLISHER_ROLE` can perform this operation
     *
     * @param _originalCollection original collection contract address
     * @param _salt bytes used for deterministic deployment
     */
    function createWrappedCollection1155(address _originalCollection, bytes32 _salt)
        external
        onlyRole(PUBLISHER_ROLE)
    {
        // Create new NFT contract
        ERC1155ABWrapperBase newCollection =
            ERC1155ABWrapperBase(Clones.cloneDeterministic(erc1155WrapperBaseImpl, _salt));

        // Initialize NFT contract
        newCollection.initialize(msg.sender, _originalCollection, address(abDataRegistry), address(abHolderRegistry));

        // Setup collection
        _setupCollection(address(newCollection), msg.sender);
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Create a publisher profile for `_account` and deploy its own Royalty contract
     *  Only the caller with role `AB_ADMIN_ROLE` can perform this operation
     *
     * @param _account address of the profile to be created
     */
    function createPublisherProfile(address _account) external onlyRole(AB_ADMIN_ROLE) {
        // Ensure account address is not the zero-address
        if (_account == address(0)) revert INVALID_PARAMETER();

        // Register new publisher within the publisher registry
        IABDataRegistry(abDataRegistry).registerPublisher(_account, address(0));

        // Grant publisher role to `_account`
        grantRole(PUBLISHER_ROLE, _account);
    }

    /**
     * @notice
     *  Revoke the rights from `_account` to publish collections
     *  Only the caller with role `AB_ADMIN_ROLE` can perform this operation
     *
     * @param _account address of the account to be revoked
     */
    function revokePublisherAccess(address _account) external onlyRole(AB_ADMIN_ROLE) {
        // Revoke publisher role from `_account`
        revokeRole(PUBLISHER_ROLE, _account);
    }

    /**
     * @notice
     *  Set ERC721AB implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC721BaseImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc721BaseImpl = _newImpl;
    }

    /**
     * @notice
     *  Set ERC721ABWrapperBase implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC721WrapperBaseImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc721WrapperBaseImpl = _newImpl;
    }

    /**
     * @notice
     *  Set ERC1155ABBase implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC1155BaseImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc1155BaseImpl = _newImpl;
    }

    /**
     * @notice
     *  Set ERC1155ABWrapperBase implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC1155WrapperBaseImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc1155WrapperBaseImpl = _newImpl;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Predict the new ERC721AB collection address
     *
     * @param _salt address of the new implementation contract
     *
     * @return _predicted predicted address for the given `_salt`
     */
    function predictERC721Address(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(erc721BaseImpl, _salt, address(this));
    }

    /**
     * @notice
     *  Predict the new ERC721ABWrapperBase collection address
     *
     * @param _salt address of the new implementation contract
     *
     * @return _predicted predicted address for the given `_salt`
     */
    function predictWrappedERC721Address(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(erc721WrapperBaseImpl, _salt, address(this));
    }

    /**
     * @notice
     *  Predict the new ERC1155ABBase collection address
     *
     * @param _salt address of the new implementation contract
     *
     * @return _predicted predicted address for the given `_salt`
     */
    function predictERC1155Address(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(erc1155BaseImpl, _salt, address(this));
    }

    /**
     * @notice
     *  Predict the new ERC1155ABWrapperBase collection address
     *
     * @param _salt address of the new implementation contract
     *
     * @return _predicted predicted address for the given `_salt`
     */
    function predictWrappedERC1155Address(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(erc1155WrapperBaseImpl, _salt, address(this));
    }

    /**
     * @notice
     *  Returns true if `_account` has `PUBLISHER_ROLE`, false otherwise
     *
     * @param _account address to be queried
     *
     * @return _hasRole true if `_account` has `PUBLISHER_ROLE`, false otherwise
     */
    function hasPublisherRole(address _account) external view returns (bool _hasRole) {
        _hasRole = hasRole(PUBLISHER_ROLE, _account);
    }
    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _setupCollection(address _collection, address _publisher) internal {
        // Log collection info
        collections.push(Collection(_collection, _publisher));

        // Allow the new collection contract to register drop within ABDataRegistry contract
        abDataRegistry.grantCollectionRole(_collection);

        // Allow the new collection contract to update ABHolderRegistry contract
        abHolderRegistry.grantCollectionRole(_collection);

        // emit Collection creation event
        emit CollectionCreated(_collection, _publisher);
    }
}
