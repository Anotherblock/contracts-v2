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
 * @title KYCVerifier
 * @author anotherblock Technical Team
 * @notice anotherblock contract responsible for verifying signature validity
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/* anotherblock Library */
import {ABErrors} from "src/libraries/ABErrors.sol";

/* anotherblock Interfaces */
import {IKYCVerifier} from "src/utils/IKYCVerifier.sol";

contract KYCVerifier is IKYCVerifier, AccessControlUpgradeable {
    using ECDSA for bytes32;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Default signer address
    address public defaultSigner;

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

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

    function beforeMint(address _to, bytes calldata _signature) external {
        if (!_verifyKYC(_to, _signature)) revert ABErrors.INVALID_SIGNATURE();
    }

    function beforeRoyaltyMint(address _to, bytes calldata _signature) external {
        if (!_verifyKYC(_to, _signature)) revert ABErrors.INVALID_SIGNATURE();
    }

    function beforeRoyaltyClaim(address _to, bytes calldata _signature) external {
        if (!_verifyKYC(_to, _signature)) revert ABErrors.INVALID_SIGNATURE();
    }
    //   beforePubliserCreated()

    //   beforeRoyaltyNftTransder() {}
    //   beforeTransfer() {

    //     kyc.users.include(_to)
    //   }

    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
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

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get KYC signer
     *
     * @return _signer signer for the given `_collection`
     */
    function getSigner() external view returns (address _signer) {
        _signer = defaultSigner;
    }

    /**
     * @notice
     *  Return true if the user is allowlisted, false otherwise
     *
     * @param _user user address
     * @param _signature signature generated by AB Backend and signed by AB Allowlist Signer
     *
     * @return _isValid boolean corresponding to the user's allowlist inclusion
     */
    function _verifyKYC(address _user, bytes calldata _signature) internal view returns (bool _isValid) {
        bytes32 digest =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_user))));
        _isValid = defaultSigner == digest.recover(_signature);
    }
}
