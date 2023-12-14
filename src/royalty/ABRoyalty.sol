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
 * @title ABRoyalty
 * @author anotherblock Technical Team
 * @notice anotherblock contract responsible for paying out royalties
 * @custom:contact info@anotherblock.io
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Superfluid Contracts */
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/* anotherblock Libraries */
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

/* anotherblock Interfaces */
import {IABRoyalty} from "src/royalty/IABRoyalty.sol";
import {IABKYCModule} from "src/utils/IABKYCModule.sol";

contract ABRoyalty is IABRoyalty, Initializable, AccessControlUpgradeable {
    using SuperTokenV1Library for ISuperToken;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Publisher address
    address public publisher;

    /// @dev anotherblock KYC Module contract interface (see IABKYCModule.sol)
    IABKYCModule public abKycModule;

    /// @dev NFT contract address of a given drop identifier
    mapping(uint256 dropId => address nft) public nftPerDropId;

    /// @dev Royalty currency contract address of a given drop identifier
    mapping(uint256 dropId => ISuperToken royaltyCurrency) public royaltyCurrency;

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /// @dev Registry Role
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");

    /// @dev Instant Distribution Agreement units precision
    uint256 public constant IDA_UNITS_PRECISION = 1_000;

    ///@dev ABRoyalty implementation version
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
     *  Contract Initializer
     *
     * @param _publisher collection publisher address
     * @param _abDataRegistry anotherblock data registry contract address
     */
    function initialize(address _publisher, address _abDataRegistry, address _abKycModule) external initializer {
        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _publisher);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRY_ROLE, _abDataRegistry);

        // Assign ABKYCModule address
        abKycModule = IABKYCModule(_abKycModule);

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
     *  Claim the owed royalties
     *
     * @param _dropId drop identifier to be claimed for
     *
     */
    function claimPayout(uint256 _dropId, bytes calldata _signature) external {
        _beforeClaim(msg.sender, _signature);
        // Claim payout for the current Drop ID
        _claimPayout(_dropId, msg.sender);
    }

    /**
     * @notice
     *  Claim the owed royalties
     *
     * @param _dropIds array of drop identifiers to be claimed for
     *
     */
    function claimPayouts(uint256[] calldata _dropIds, bytes calldata _signature) external {
        _beforeClaim(msg.sender, _signature);

        uint256 length = _dropIds.length;
        for (uint256 i; i < length;) {
            _claimPayout(_dropIds[i], msg.sender);

            unchecked {
                ++i;
            }
        }
    }

    //    ____        __         ___       __          _
    //   / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //  / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    // / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    // \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //              /____/

    /**
     * @notice
     *  Distribute the royalty for the given Drop ID
     *  Only contract owner can perform this operation
     *
     * @param _dropId drop identifier
     * @param _amount amount to be paid-out
     * @param _prepaid boolean indicating if the royalty has already been transferred to this contract
     */
    function distribute(uint256 _dropId, uint256 _amount, bool _prepaid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_prepaid) royaltyCurrency[_dropId].transferFrom(msg.sender, address(this), _amount);
        _distribute(_dropId, _amount);
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(uint256 _dropId, address _user, bytes calldata _signature)
        external
        onlyRole(AB_ADMIN_ROLE)
    {
        _beforeClaim(_user, _signature);

        // Claim payout for the current Drop ID
        _claimPayout(_dropId, _user);
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(uint256[] calldata _dropIds, address _user, bytes calldata _signature)
        external
        onlyRole(AB_ADMIN_ROLE)
    {
        _beforeClaim(_user, _signature);

        uint256 length = _dropIds.length;
        for (uint256 i; i < length;) {
            _claimPayout(_dropIds[i], _user);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _dropId drop identifier to be claimed
     * @param _users array containing the users addresses to be claimed for
     * @param _signatures array containing the KYC signatures (for each user in `_users`)
     */
    function claimPayoutsOnMultipleBehalf(uint256 _dropId, address[] calldata _users, bytes[] calldata _signatures)
        external
        onlyRole(AB_ADMIN_ROLE)
    {
        uint256 uLength = _users.length;
        uint256 sLength = _signatures.length;

        if (sLength != uLength) revert ABErrors.INVALID_PARAMETER();

        // Loop through all users passed as parameter
        for (uint256 i; i < uLength;) {
            _beforeClaim(_users[i], _signatures[i]);

            // Claim payout for the current Drop ID
            _claimPayout(_dropId, _users[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _dropIds array containing the Drop IDs to be claimed
     * @param _users array containing the users addresses to be claimed for
     * @param _signatures array containing the KYC signatures (for each user in `_users`)
     */
    function claimPayoutsOnMultipleBehalf(
        uint256[] calldata _dropIds,
        address[] calldata _users,
        bytes[] calldata _signatures
    ) external onlyRole(AB_ADMIN_ROLE) {
        uint256 uLength = _users.length;
        uint256 dLength = _dropIds.length;
        uint256 sLength = _signatures.length;

        if (sLength != uLength) revert ABErrors.INVALID_PARAMETER();

        // Loop through all users passed as parameter
        for (uint256 i; i < uLength;) {
            _beforeClaim(_users[i], _signatures[i]);

            // Loop through all Drop IDs passed as parameter
            for (uint256 j; j < dLength;) {
                // Claim payout for the current Drop ID
                _claimPayout(_dropIds[j], _users[i]);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    //     ____        __         ____             _      __
    //    / __ \____  / /_  __   / __ \___  ____ _(_)____/ /________  __
    //   / / / / __ \/ / / / /  / /_/ / _ \/ __ `/ / ___/ __/ ___/ / / /
    //  / /_/ / / / / / /_/ /  / _, _/  __/ /_/ / (__  ) /_/ /  / /_/ /
    //  \____/_/ /_/_/\__, /  /_/ |_|\___/\__, /_/____/\__/_/   \__, /
    //               /____/              /____/                /____/

    /**
     * @notice
     *  Initialize the Superfluid IDA Payout Index for a given Drop
     *  Only anotherblock Data Registry contract can perform this operation
     *
     * @param _nft nft contract address
     * @param _royaltyCurrency super token currency used for payout
     * @param _dropId drop identifier
     */
    function initPayoutIndex(address _nft, address _royaltyCurrency, uint256 _dropId)
        external
        onlyRole(REGISTRY_ROLE)
    {
        bool success = ISuperToken(_royaltyCurrency).createIndex(uint32(_dropId));
        if (!success) {
            revert ABErrors.SUPERTOKEN_INDEX_ERROR();
        }
        nftPerDropId[_dropId] = _nft;
        royaltyCurrency[_dropId] = ISuperToken(_royaltyCurrency);
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only anotherblock Data Registry contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _dropIds array of corresponding index
     * @param _quantities array of quantity (per index)
     */
    function updatePayout1155(
        address _previousHolder,
        address _newHolder,
        uint256[] calldata _dropIds,
        uint256[] calldata _quantities
    ) external onlyRole(REGISTRY_ROLE) {
        uint256 length = _dropIds.length;
        if (length != _quantities.length) revert ABErrors.INVALID_PARAMETER();

        for (uint256 i; i < length;) {
            // Remove `_quantity` of `_dropId` shares from `_previousHolder`
            _loseShare(_previousHolder, _dropIds[i], _quantities[i] * IDA_UNITS_PRECISION);

            // Add `_quantity` of `_dropId` shares to `_newHolder`
            _gainShare(_newHolder, _dropIds[i], _quantities[i] * IDA_UNITS_PRECISION);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only anotherblock Data Registry contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _dropId drop identifier
     * @param _quantity array of quantity (per index)
     */
    function updatePayout721(address _previousHolder, address _newHolder, uint256 _dropId, uint256 _quantity)
        external
        onlyRole(REGISTRY_ROLE)
    {
        // Remove `_quantity` of `_dropId` shares from `_previousHolder`
        _loseShare(_previousHolder, _dropId, _quantity * IDA_UNITS_PRECISION);

        // Add `_quantity` of `_dropId` shares to `_newHolder`
        _gainShare(_newHolder, _dropId, _quantity * IDA_UNITS_PRECISION);
    }

    /**
     * @notice
     *  Distribute the royalty for the given Drop ID on behalf of the publisher
     *  Only ABDataRegistry contract can perform this operation
     *
     * @param _dropId drop identifier
     * @param _amount amount to be paid-out
     */
    function distributeOnBehalf(uint256 _dropId, uint256 _amount) external onlyRole(REGISTRY_ROLE) {
        _distribute(_dropId, _amount);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get the user amount of subscription units
     *
     * @param _dropId drop identifier
     * @param _user user address to be queried
     *
     * @return _currentUnitsHeld number of units held by the user for the given Drop ID
     */
    function getUserSubscription(uint256 _dropId, address _user) external view returns (uint256 _currentUnitsHeld) {
        // Get the subscriber's current units
        (,, _currentUnitsHeld,) = royaltyCurrency[_dropId].getSubscription(address(this), uint32(_dropId), _user);
    }

    /**
     * @notice
     *  Get the amount of royalty to be claimed by the user
     *
     * @param _dropId drop identifier
     * @param _user user address to be queried
     *
     * @return _pendingDistribution amount of royalty to be claimed by the user for the given Drop ID
     */
    function getClaimableAmount(uint256 _dropId, address _user) external view returns (uint256 _pendingDistribution) {
        // Get the subscriber's pending amount to be claimed
        (,,, _pendingDistribution) = royaltyCurrency[_dropId].getSubscription(address(this), uint32(_dropId), _user);
    }

    /**
     * @notice
     *  Query the data of a index
     *
     * @param _dropId drop identifier
     *
     * @return indexValue Value of the current index
     * @return totalUnitsApproved Total units approved for the index
     * @return totalUnitsPending Total units pending approval for the index
     */
    function getIndexInfo(uint256 _dropId)
        external
        view
        returns (uint128 indexValue, uint128 totalUnitsApproved, uint128 totalUnitsPending)
    {
        (, indexValue, totalUnitsApproved, totalUnitsPending) =
            royaltyCurrency[_dropId].getIndex(address(this), uint32(_dropId));
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Add subscription units to the subscriber
     *
     * @param _subscriber subscriber address
     * @param _dropId drop identifier
     * @param _units amount of units to add
     */
    function _gainShare(address _subscriber, uint256 _dropId, uint256 _units) internal {
        // Ensure subscriber address is not zero-address
        if (_subscriber == address(0)) return;

        // Get the subscriber's current units
        (,, uint256 currentUnitsHeld,) =
            royaltyCurrency[_dropId].getSubscription(address(this), uint32(_dropId), _subscriber);

        // Add `_units` to the subscriber current units amount
        royaltyCurrency[_dropId].updateSubscriptionUnits(
            uint32(_dropId), _subscriber, uint128(currentUnitsHeld + _units)
        );
    }

    /**
     * @notice
     *  Remove subscription units from the subscriber
     *
     * @param _subscriber subscriber address
     * @param _dropId drop identifier
     * @param _units amount of units to remove
     */
    function _loseShare(address _subscriber, uint256 _dropId, uint256 _units) internal {
        // Ensure subscriber address is not zero-address
        if (_subscriber == address(0)) return;

        // Get the subscriber's current units
        (,, uint256 currentUnitsHeld,) =
            royaltyCurrency[_dropId].getSubscription(address(this), uint32(_dropId), _subscriber);

        // Check if the new amount of units is null
        if (currentUnitsHeld - _units <= 0) {
            // Delete the user's subscription
            royaltyCurrency[_dropId].deleteSubscription(address(this), uint32(_dropId), _subscriber);
        } else {
            // Remove `_units` from the subscriber current units amount
            royaltyCurrency[_dropId].updateSubscriptionUnits(
                uint32(_dropId), _subscriber, uint128(currentUnitsHeld - _units)
            );
        }
    }

    /**
     * @notice
     *  Distribute `_amount` of royalty for the given `_dropId`
     *
     * @param _dropId drop identifier
     * @param _amount amount to be paid-out
     */
    function _distribute(uint256 _dropId, uint256 _amount) internal {
        // Calculate the amount to be distributed
        (uint256 actualDistributionAmount,) =
            royaltyCurrency[_dropId].calculateDistribution(address(this), uint32(_dropId), _amount);

        // Distribute the token according to the calculated amount
        royaltyCurrency[_dropId].distribute(uint32(_dropId), actualDistributionAmount);

        // Emit event
        emit ABEvents.RoyaltyDistributed(_dropId, _amount);
    }

    /**
     * @notice
     *  Claim the user's owed royalties for the given Drop IDs
     *
     * @param _dropId drop identifier
     * @param _user user address
     */
    function _claimPayout(uint256 _dropId, address _user) internal {
        // Claim the distributed Tokens
        royaltyCurrency[_dropId].claim(address(this), uint32(_dropId), _user);
    }

    function _beforeClaim(address _user, bytes calldata _signature) internal view {
        abKycModule.beforeRoyaltyClaim(_user, _signature);
    }
}
