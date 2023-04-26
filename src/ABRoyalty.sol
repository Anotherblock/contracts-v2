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
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ABRoyalty is Initializable, OwnableUpgradeable {
    using SuperTokenV1Library for ISuperToken;

    /// @dev Thrown when the passed parameter is invalid
    error INVALID_PARAMETER();

    /// @dev Thrown when caller is not authorized to perform operation
    error FORBIDDEN();

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev AnotherCloneFactory contract address
    address public anotherCloneFactory;

    /// @dev NFT contract address of a given drop identifier
    mapping(address nft => bool isApproved) public approvedNFT;

    /// @dev NFT contract address of a given drop identifier
    mapping(uint256 dropId => address nft) public nftPerDropId;

    /// @dev Royalty currency contract address of a given drop identifier
    mapping(uint256 dropId => ISuperToken royaltyCurrency) public royaltyCurrency;

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

    function initialize(address _anotherCloneFactory) external initializer {
        __Ownable_init();
        anotherCloneFactory = _anotherCloneFactory;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Claim the owed royalties
     */
    function claimPayout(uint256 _dropId) external {
        // Claim payout for the current Drop ID
        _claimPayout(_dropId, msg.sender);
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
     *  Only Anotherblock Vault contract can perform this operation
     *
     * @param _amount amount to be paid-out
     */
    function distribute(uint256 _dropId, uint256 _amount) external onlyOwner {
        royaltyCurrency[_dropId].transferFrom(msg.sender, address(this), _amount);

        // Calculate the amount to be distributed
        (uint256 actualDistributionAmount,) =
            royaltyCurrency[_dropId].calculateDistribution(address(this), uint32(_dropId), _amount);

        // Distribute the token according to the calculated amount
        royaltyCurrency[_dropId].distribute(uint32(_dropId), actualDistributionAmount);
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(uint256 _dropId, address _user) external onlyOwner {
        // Claim payout for the current Drop ID
        _claimPayout(_dropId, _user);
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _users array containing the users addresses to be claimed for
     */
    function claimPayoutsOnMultipleBehalf(uint256 _dropId, address[] memory _users) external onlyOwner {
        // Loop through all users passed as parameter
        for (uint256 i = 0; i < _users.length; ++i) {
            // Claim payout for the current Drop ID
            _claimPayout(_dropId, _users[i]);
        }
    }

    //    ____        __         ______           __
    //   / __ \____  / /_  __   / ____/___ ______/ /_____  _______  __
    //  / / / / __ \/ / / / /  / /_  / __ `/ ___/ __/ __ \/ ___/ / / /
    // / /_/ / / / / / /_/ /  / __/ / /_/ / /__/ /_/ /_/ / /  / /_/ /
    // \____/_/ /_/_/\__, /  /_/    \__,_/\___/\__/\____/_/   \__, /
    //              /____/                                   /____/

    function approveNFT(address _nft) external onlyFactory {
        approvedNFT[_nft] = true;
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
    function initPayoutIndex(address _royaltyCurrency, uint256 _dropId) external onlyNFT {
        nftPerDropId[_dropId] = msg.sender;
        royaltyCurrency[_dropId] = ISuperToken(_royaltyCurrency);
        royaltyCurrency[_dropId].createIndex(uint32(_dropId));
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Relay contract can perform this operation
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
    ) external onlyDropNFTs(_dropIds) {
        for (uint256 i = 0; i < _dropIds.length; ++i) {
            // Remove `_quantity` of `_dropId` shares from `_previousHolder`
            _loseShare(_previousHolder, _dropIds[i], _quantities[i] * IDA_UNITS_PRECISION);

            // Add `_quantity` of `_dropId` shares to `_newHolder`
            _gainShare(_newHolder, _dropIds[i], _quantities[i] * IDA_UNITS_PRECISION);
        }
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Relay contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _quantity array of quantity (per index)
     */
    function updatePayout721(address _previousHolder, address _newHolder, uint256 _dropId, uint256 _quantity)
        external
        onlyDropNFT(_dropId)
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
     * @return : number of units held by the user for the given Drop ID
     */
    function getUserSubscription(uint256 _dropId, address _user) external view returns (uint256) {
        // Get the subscriber's current units
        (,, uint256 currentUnitsHeld,) = royaltyCurrency[_dropId].getSubscription(address(this), uint32(_dropId), _user);
        return currentUnitsHeld;
    }

    /**
     * @notice
     *  Get the amount of royalty to be claimed by the user
     *
     * @param _user user address to be queried
     *
     * @return : amount of royalty to be claimed by the user for the given Drop ID
     */
    function getClaimableAmount(uint256 _dropId, address _user) external view returns (uint256) {
        // Get the subscriber's pending amount to be claimed
        (,,, uint256 pendingDistribution) =
            royaltyCurrency[_dropId].getSubscription(address(this), uint32(_dropId), _user);
        return pendingDistribution;
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
     *  Claim the user's owed royalties for the given Drop IDs
     *
     * @param _user user address
     */
    function _claimPayout(uint256 _dropId, address _user) internal {
        // Claim the distributed Tokens
        royaltyCurrency[_dropId].claim(address(this), uint32(_dropId), _user);
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  _____
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/

    /**
     * @notice
     *  Ensure that the call is coming from associate NFT contract address
     */
    modifier onlyDropNFT(uint256 _dropId) {
        if (msg.sender != nftPerDropId[_dropId]) revert FORBIDDEN();
        _;
    }

    /**
     * @notice
     *  Ensure that the call is coming from associate NFT contract address
     */
    modifier onlyDropNFTs(uint256[] calldata _dropIds) {
        uint256 length = _dropIds.length;
        for (uint256 i = 0; i < length; ++i) {
            if (msg.sender != nftPerDropId[_dropIds[i]]) revert FORBIDDEN();
            _;
        }
    }

    /**
     * @notice
     *  Ensure that the call is coming from associate NFT contract address
     */
    modifier onlyNFT() {
        if (!approvedNFT[msg.sender]) revert FORBIDDEN();
        _;
    }

    /**
     * @notice
     *  Ensure that the call is coming from AnotherCloneFactory contract
     */
    modifier onlyFactory() {
        if (msg.sender != anotherCloneFactory) {
            revert FORBIDDEN();
        }
        _;
    }
}
