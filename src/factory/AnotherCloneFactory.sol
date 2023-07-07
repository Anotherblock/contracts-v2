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
 * @notice Contract responsible for deploying new Anotherblock collections
 *
 */

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/* Anotherblock Libraries */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

/* Anotherblock Contract */
import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";
import {ERC1155AB} from "src/token/ERC1155/ERC1155AB.sol";
import {ABRoyalty} from "src/royalty/ABRoyalty.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";

contract AnotherCloneFactory is AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Array of all Collection created by this factory
    ABDataTypes.Collection[] public collections;

    /// @dev ABDropRegistry contract interface
    IABDataRegistry public abDataRegistry;

    /// @dev ABVerifier contract address
    address public abVerifier;

    /// @dev Standard Anotherblock ERC721 contract implementation address
    address public erc721Impl;

    /// @dev Standard Anotherblock ERC1155 contract implementation address
    address public erc1155Impl;

    /// @dev Standard Anotherblock Royalty Payout (IDA) contract implementation address
    address public royaltyImpl;

    ///@dev Default creator fee recipient
    address public creatorFeeRecipient;

    /// @dev Publisher Role
    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

    /**
     * @notice
     *  Contract Initializer
     *
     * @param _abDataRegistry address of ABDropRegistry contract
     * @param _abVerifier address of ABVerifier contract
     * @param _erc721Impl address of ERC721AB implementation
     * @param _erc1155Impl address of ERC1155AB implementation
     * @param _royaltyImpl address of ABRoyalty implementation
     * @param _creatorFeeRecipient address of the creator fee recipient
     */
    function initialize(
        address _abDataRegistry,
        address _abVerifier,
        address _erc721Impl,
        address _erc1155Impl,
        address _royaltyImpl,
        address _creatorFeeRecipient
    ) external initializer {
        abDataRegistry = IABDataRegistry(_abDataRegistry);
        abVerifier = _abVerifier;
        erc721Impl = _erc721Impl;
        erc1155Impl = _erc1155Impl;
        royaltyImpl = _royaltyImpl;
        creatorFeeRecipient = _creatorFeeRecipient;

        // Initialize Access Control
        __AccessControl_init();
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
     * @param _salt bytes used for deterministic deployment
     */
    function createCollection721(string memory _name, bytes32 _salt) external onlyRole(PUBLISHER_ROLE) {
        // Create new NFT contract
        ERC721AB newCollection = ERC721AB(Clones.cloneDeterministic(erc721Impl, _salt));

        // Initialize NFT contract
        newCollection.initialize(creatorFeeRecipient, msg.sender, address(abDataRegistry), abVerifier, _name);

        // Setup collection
        _setupCollection(address(newCollection), msg.sender);
    }

    /**
     * @notice
     *  Create new ERC721 collection
     *  Only the caller with role `PUBLISHER_ROLE` can perform this operation
     *
     * @param _impl implementation contract address to be cloned
     * @param _name collection name
     * @param _salt bytes used for deterministic deployment
     */
    function createCollection721FromImplementation(
        address _impl,
        address _publisher,
        string memory _name,
        bytes32 _salt
    ) external onlyRole(AB_ADMIN_ROLE) {
        if (!abDataRegistry.isPublisher(_publisher)) revert ABErrors.ACCOUNT_NOT_PUBLISHER();

        // Create new NFT contract
        ERC721AB newCollection = ERC721AB(Clones.cloneDeterministic(_impl, _salt));

        // Initialize NFT contract
        newCollection.initialize(creatorFeeRecipient, _publisher, address(abDataRegistry), abVerifier, _name);

        // Setup collection
        _setupCollection(address(newCollection), _publisher);
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
        ERC1155AB newCollection = ERC1155AB(Clones.cloneDeterministic(erc1155Impl, _salt));

        // Initialize NFT contract
        newCollection.initialize(msg.sender, address(abDataRegistry), abVerifier);

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
     *  Create a publisher profile for `_account`
     *  Only the caller with role `AB_ADMIN_ROLE` can perform this operation
     *
     * @param _account address of the profile to be created
     * @param _abRoyalty pre-deployed royalty contract address associated to the publisher
     * @param _publisherFee mint proceeds percentage that goes to the publisher (expressed in basis points)
     */
    function createPublisherProfile(address _account, address _abRoyalty, uint256 _publisherFee)
        external
        onlyRole(AB_ADMIN_ROLE)
    {
        // Ensure publisher fee is between 0 and 10_000
        if (_publisherFee > 10_000) revert ABErrors.INVALID_PARAMETER();

        // Ensure account address is not the zero-address
        if (_account == address(0)) revert ABErrors.INVALID_PARAMETER();

        // Register new publisher within the publisher registry
        abDataRegistry.registerPublisher(_account, address(_abRoyalty), _publisherFee);

        // Grant publisher role to `_account`
        grantRole(PUBLISHER_ROLE, _account);
    }

    /**
     * @notice
     *  Create a publisher profile for `_account` and deploy its own Royalty contract
     *  Only the caller with role `AB_ADMIN_ROLE` can perform this operation
     *
     * @param _account address of the profile to be created
     * @param _publisherFee mint proceeds percentage that goes to the publisher (expressed in basis points)
     */
    function createPublisherProfile(address _account, uint256 _publisherFee) external onlyRole(AB_ADMIN_ROLE) {
        // Ensure publisher fee is between 0 and 10_000
        if (_publisherFee > 10_000) revert ABErrors.INVALID_PARAMETER();

        // Ensure account address is not the zero-address
        if (_account == address(0)) revert ABErrors.INVALID_PARAMETER();

        // Create new Royalty contract for the publisher
        ABRoyalty newRoyalty = ABRoyalty(Clones.clone(royaltyImpl));

        // Initialize Payout contract
        newRoyalty.initialize(_account, address(this), address(abDataRegistry));

        // Register new publisher within the publisher registry
        abDataRegistry.registerPublisher(_account, address(newRoyalty), _publisherFee);

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
    function setERC721Implementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc721Impl = _newImpl;
    }

    /**
     * @notice
     *  Set ERC1155AB implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC1155Implementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc1155Impl = _newImpl;
    }

    /**
     * @notice
     *  Set ABRoyalty implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setABRoyaltyImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyImpl = _newImpl;
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
        _predicted = Clones.predictDeterministicAddress(erc721Impl, _salt, address(this));
    }

    /**
     * @notice
     *  Predict the new ERC1155AB collection address
     *
     * @param _salt address of the new implementation contract
     *
     * @return _predicted predicted address for the given `_salt`
     */
    function predictERC1155Address(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(erc1155Impl, _salt, address(this));
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
        collections.push(ABDataTypes.Collection(_collection, _publisher));

        // Allow the new collection contract to register drop within ABDropRegistry contract
        abDataRegistry.grantCollectionRole(_collection);

        // emit Collection creation event
        emit ABEvents.CollectionCreated(_collection, _publisher);
    }
}
