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
 * @title ABVerifier
 * @author Anotherblock Technical Team
 * @notice Anotherblock contract responsible for verifying signature validity
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/* Anotherblock Library */
import {ABErrors} from "src/libraries/ABErrors.sol";

contract ABVerifier is AccessControlUpgradeable {
    using ECDSA for bytes32;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Default signer address
    address public defaultSigner;

    /// @dev Mapping storing the signer address for a given collection
    mapping(address collection => address signer) private signerPerCollection;

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

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
     *  Contract Initializer
     *
     * @param _defaultSigner allowlist generator signer
     *
     */
    function initialize(address _defaultSigner) external initializer {
        if (_defaultSigner == address(0)) revert ABErrors.INVALID_PARAMETER();
        defaultSigner = _defaultSigner;

        // Initialize Access Control
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Return true if the user is allowlisted, false otherwise
     *
     * @param _user user address
     * @param _collection NFT contract address which user is attempting to mint
     * @param _phaseId phase at which user is attempting to mint
     * @param _signature signature generated by AB Backend and signed by AB Allowlist Signer
     *
     * @return _isValid boolean corresponding to the user's allowlist inclusion
     */
    function verifySignature721(address _user, address _collection, uint256 _phaseId, bytes calldata _signature)
        external
        view
        returns (bool _isValid)
    {
        address signer = _getSigner(_collection);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_user, _collection, _phaseId))
            )
        );
        _isValid = signer == digest.recover(_signature);
    }

    /**
     * @notice
     *  Return true if the user is allowlisted, false otherwise
     *
     * @param _user user address
     * @param _collection NFT contract address which user is attempting to mint
     * @param _tokenId token which user is attempting to mint
     * @param _phaseId phase at which user is attempting to mint
     * @param _signature signature generated by AB Backend and signed by AB Allowlist Signer
     *
     * @return _isValid boolean corresponding to the user's allowlist inclusion
     */
    function verifySignature1155(
        address _user,
        address _collection,
        uint256 _tokenId,
        uint256 _phaseId,
        bytes calldata _signature
    ) external view returns (bool _isValid) {
        address signer = _getSigner(_collection);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_user, _collection, _tokenId, _phaseId))
            )
        );
        _isValid = signer == digest.recover(_signature);
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Set the default allowlist signer address
     *
     * @param _defaultSigner : address signing the allowed user for a given drop / phase
     */
    function setDefaultSigner(address _defaultSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultSigner = _defaultSigner;
    }

    /**
     * @notice
     *  Set a specific allowlist `_signer` for a given `_collection`
     *
     * @param _collection : collection contract address associated to the signer
     * @param _signer : address signing the allowed user for the given collection
     */
    function setCollectionSigner(address _collection, address _signer) external onlyRole(AB_ADMIN_ROLE) {
        signerPerCollection[_collection] = _signer;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get allowlist signer for a given `_collection`
     *
     * @param _collection NFT contract address
     *
     * @return _signer signer for the given `_collection`
     */
    function getSigner(address _collection) external view returns (address _signer) {
        _signer = _getSigner(_collection);
    }
    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get allowlist signer for a given `_collection`
     *
     * @param _collection NFT contract address
     *
     * @return _signer signer for the given `_collection`
     */
    function _getSigner(address _collection) internal view returns (address _signer) {
        _signer = defaultSigner;
        address collectionSigner = signerPerCollection[_collection];
        if (collectionSigner != address(0)) {
            _signer = collectionSigner;
        }
    }
}
