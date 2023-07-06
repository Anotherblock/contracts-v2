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
 * @author Anotherblock Technical Team
 * @notice Anotherblock contract to payout royalty
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Superfluid Contracts */
import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/* Anotherblock Libraries */
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

contract ABRoyalty is Initializable, AccessControlUpgradeable {
    using SuperTokenV1Library for ISuperToken;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev AnotherCloneFactory contract address
    address public anotherCloneFactory;

    /// @dev Publisher address
    address public publisher;

    /// @dev NFT contract address of a given drop identifier
    mapping(uint256 dropId => address nft) public nftPerDropId;

    /// @dev Royalty currency contract address of a given drop identifier
    mapping(uint256 dropId => ISuperToken royaltyCurrency) public royaltyCurrency;

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /// @dev Factory Role
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

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

    function initialize(address _publisher, address _anotherCloneFactory, address _abDataRegistry)
        external
        initializer
    {
        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _publisher);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _grantRole(FACTORY_ROLE, _anotherCloneFactory);
        _grantRole(REGISTRY_ROLE, _abDataRegistry);

        // Assign AnotherCloneFactory address
        anotherCloneFactory = _anotherCloneFactory;

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
    function claimPayout(uint256 _dropId) external {
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
    function claimPayouts(uint256[] calldata _dropIds) external {
        uint256 length = _dropIds.length;
        for (uint256 i = 0; i < length; ++i) {
            _claimPayout(_dropIds[i], msg.sender);
        }
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

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
        if (!_prepaid) {
            royaltyCurrency[_dropId].transferFrom(msg.sender, address(this), _amount);
        }
        _distribute(_dropId, _amount);
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

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(uint256 _dropId, address _user) external onlyRole(AB_ADMIN_ROLE) {
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
    function claimPayoutsOnBehalf(uint256[] calldata _dropIds, address _user) external onlyRole(AB_ADMIN_ROLE) {
        uint256 length = _dropIds.length;
        for (uint256 i = 0; i < length; ++i) {
            _claimPayout(_dropIds[i], _user);
        }
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _dropId drop identifier to be claimed
     * @param _users array containing the users addresses to be claimed for
     */
    function claimPayoutsOnMultipleBehalf(uint256 _dropId, address[] calldata _users)
        external
        onlyRole(AB_ADMIN_ROLE)
    {
        // Loop through all users passed as parameter
        for (uint256 i = 0; i < _users.length; ++i) {
            // Claim payout for the current Drop ID
            _claimPayout(_dropId, _users[i]);
        }
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only contract owner can perform this operation
     *
     * @param _dropIds array containing the Drop IDs to be claimed
     * @param _users array containing the users addresses to be claimed for
     */
    function claimPayoutsOnMultipleBehalf(uint256[] calldata _dropIds, address[] calldata _users)
        external
        onlyRole(AB_ADMIN_ROLE)
    {
        uint256 uLength = _users.length;
        uint256 dLength = _dropIds.length;

        // Loop through all users passed as parameter
        for (uint256 i = 0; i < uLength; ++i) {
            // Loop through all Drop IDs passed as parameter
            for (uint256 j = 0; j < dLength; ++j) {
                // Claim payout for the current Drop ID
                _claimPayout(_dropIds[j], _users[i]);
            }
        }
    }

    //     ____        __         _   ______________
    //    / __ \____  / /_  __   / | / / ____/_  __/
    //   / / / / __ \/ / / / /  /  |/ / /_    / /
    //  / /_/ / / / / / /_/ /  / /|  / __/   / /
    //  \____/_/ /_/_/\__, /  /_/ |_/_/     /_/
    //               /____/

    /**
     * @notice
     *  Initialize the Superfluid IDA Payout Index for a given Drop
     *  Only allowed NFT contract can perform this operation
     *
     */
    function initPayoutIndex(address _nft, address _royaltyCurrency, uint256 _dropId)
        external
        onlyRole(REGISTRY_ROLE)
    {
        nftPerDropId[_dropId] = _nft;
        ISuperToken(_royaltyCurrency).createIndex(uint32(_dropId));
        royaltyCurrency[_dropId] = ISuperToken(_royaltyCurrency);
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Data Registry contract can perform this operation
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

        for (uint256 i = 0; i < length; ++i) {
            // Remove `_quantity` of `_dropId` shares from `_previousHolder`
            _loseShare(_previousHolder, _dropIds[i], _quantities[i] * IDA_UNITS_PRECISION);

            // Add `_quantity` of `_dropId` shares to `_newHolder`
            _gainShare(_newHolder, _dropIds[i], _quantities[i] * IDA_UNITS_PRECISION);
        }
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Data Registry contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
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

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get the user amount of subscription units
     *
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
     * @param _user user address
     */
    function _claimPayout(uint256 _dropId, address _user) internal {
        // Claim the distributed Tokens
        royaltyCurrency[_dropId].claim(address(this), uint32(_dropId), _user);
    }
}
