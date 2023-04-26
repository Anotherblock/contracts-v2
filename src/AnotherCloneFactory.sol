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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/* Anotherblock Contract */
import {ERC721AB} from "./ERC721AB.sol";
import {ERC1155AB} from "./ERC1155AB.sol";
import {ABRoyalty} from "./ABRoyalty.sol";
import {IABDropRegistry} from "./interfaces/IABDropRegistry.sol";
import {IABPublisherRegistry} from "./interfaces/IABPublisherRegistry.sol";

contract AnotherCloneFactory is Ownable {
    /// @dev Error returned when caller is not authorized to perform operation
    error FORBIDDEN();

    /// @dev Error returned when attempting to create a publisher profile with an account already publisher
    error ACCOUNT_ALREADY_PUBLISHER();

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

    /// @dev Approval status for a given account
    mapping(address account => bool isApproved) public approvedPublisher;

    /// @dev ABDropRegistry contract interface
    IABDropRegistry public abDropRegistry;

    /// @dev ABPublisherRegistry contract interface
    IABPublisherRegistry public abPublisherRegistry;

    /// @dev ABVerifier contract address
    address public abVerifier;

    /// @dev Standard Anotherblock ERC721 contract implementation address
    address public erc721Impl;

    /// @dev Standard Anotherblock ERC1155 contract implementation address
    address public erc1155Impl;

    /// @dev Standard Anotherblock Royalty Payout (IDA) contract implementation address
    address public royaltyImpl;

    /**
     * @notice
     *  Contract Constructor
     *
     * @param _abDropRegistry address of ABDropRegistry contract
     * @param _abVerifier address of ABVerifier contract
     * @param _erc721Impl address of ERC721AB implementation
     * @param _erc1155Impl address of ERC1155AB implementation
     * @param _royaltyImpl address of ABRoyalty implementation
     */
    constructor(
        address _abPublisherRegistry,
        address _abDropRegistry,
        address _abVerifier,
        address _erc721Impl,
        address _erc1155Impl,
        address _royaltyImpl
    ) {
        abPublisherRegistry = IABPublisherRegistry(_abPublisherRegistry);
        abDropRegistry = IABDropRegistry(_abDropRegistry);
        abVerifier = _abVerifier;
        erc721Impl = _erc721Impl;
        erc1155Impl = _erc1155Impl;
        royaltyImpl = _royaltyImpl;
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
     *
     * @param _name collection name
     * @param _symbol collection symbol
     * @param _salt bytes used for deterministic deployment
     */
    function createCollection721(string memory _name, string memory _symbol, bytes32 _salt) external onlyPublisher {
        // Create new NFT contract
        ERC721AB newCollection = ERC721AB(Clones.cloneDeterministic(erc721Impl, _salt));

        // Get the royalty contract address belonging to the publisher
        address abRoyalty = abPublisherRegistry.getRoyaltyContract(msg.sender);

        // Initialize NFT contract
        newCollection.initialize(address(abPublisherRegistry), address(abDropRegistry), abVerifier, _name, _symbol);

        // Log drop details in Collections array
        collections.push(Collection(address(newCollection), msg.sender));

        // Grant approval to the new collection to communicate with the publisher's royalty contract
        ABRoyalty(abRoyalty).approveNFT(address(newCollection));

        // Allow the new collection contract to register new drops within ABDropRegistry contract
        abDropRegistry.allowNFT(address(newCollection));

        // Transfer NFT contract ownership
        newCollection.transferOwnership(msg.sender);

        // emit Collection creation event
        emit CollectionCreated(address(newCollection), msg.sender);
    }

    // /**
    //  * @notice
    //  *  Create new ERC1155 collection
    //  *
    //  * @param _royaltyCurrency address of the token used to pay royalty
    //  * @param _salt bytes used for deterministic deployment
    //  */
    // function createCollection1155(address _royaltyCurrency, bytes32 _salt) external onlyPublisher {
    //     // Create new ABRoyalty contract
    //     ABRoyalty newRoyalty = ABRoyalty(Clones.clone(royaltyImpl));

    //     // Create new NFT contract
    //     ERC1155AB newCollection = ERC1155AB(Clones.cloneDeterministic(erc1155Impl, _salt));

    //     // Initialize ABRoyalty contract
    //     newRoyalty.initialize(address(this), _royaltyCurrency, address(newCollection));

    //     // Initialize NFT contract
    //     newCollection.initialize(address(abDropRegistry), address(newRoyalty), abVerifier);

    //     // Transfer Ownership of NFT contract and Payout contract to the caller
    //     newRoyalty.transferOwnership(msg.sender);
    //     newCollection.transferOwnership(msg.sender);

    //     // Allow the new collection contract to register drop within ABDropRegistry contract
    //     abDropRegistry.allowNFT(address(newCollection));

    //     emit CollectionCreated(address(newCollection), address(newRoyalty), msg.sender);

    //     // Store the new Collection contracts addresses
    //     collections.push(Collection(address(newCollection), address(newRoyalty)));
    // }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Revoke the rights from `_account` to publish collections
     *  Only the contract owner can perform this operation
     *
     * @param _account address of the account to be revoked
     */
    function revokePublisherAccess(address _account) external onlyOwner {
        approvedPublisher[_account] = false;
    }

    function createPublisherProfile(address _account) external onlyOwner {
        if (IABPublisherRegistry(abPublisherRegistry).isPublisher(_account)) revert ACCOUNT_ALREADY_PUBLISHER();

        // Create new Royalty contract for the publisher
        ABRoyalty newRoyalty = ABRoyalty(Clones.clone(royaltyImpl));

        // Initialize Payout contract
        newRoyalty.initialize(address(this));

        // Register new publisher within the publisher registry
        IABPublisherRegistry(abPublisherRegistry).registerPublisher(_account, address(newRoyalty));
        approvedPublisher[_account] = true;

        // Transfer Payout contract ownership
        newRoyalty.transferOwnership(msg.sender);
    }

    /**
     * @notice
     *  Set ERC721AB implementation address
     *  Only the contract owner can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC721Implementation(address _newImpl) external onlyOwner {
        erc721Impl = _newImpl;
    }

    /**
     * @notice
     *  Set ERC1155AB implementation address
     *  Only the contract owner can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setERC1155Implementation(address _newImpl) external onlyOwner {
        erc1155Impl = _newImpl;
    }

    /**
     * @notice
     *  Set ABRoyalty implementation address
     *  Only the contract owner can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     */
    function setABRoyaltyImplementation(address _newImpl) external onlyOwner {
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

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  _____
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/

    /**
     * @notice
     *  Ensure that the call is coming from an approved publisher
     */
    modifier onlyPublisher() {
        if (msg.sender != owner() && !approvedPublisher[msg.sender]) {
            revert FORBIDDEN();
        }
        _;
    }
}
