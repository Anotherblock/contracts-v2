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

    address public anotherFactory;
    address public nft;
    ISuperToken public payoutToken;
    uint256 public constant IDA_UNITS_PRECISION = 1000;

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

    function initialize(address _anotherFactory, address _payoutToken, address _nft) external initializer {
        __Ownable_init();
        anotherFactory = _anotherFactory;
        payoutToken = ISuperToken(_payoutToken);
        nft = _nft;
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
    function claimPayout() external {
        // Claim payout for the current Drop ID
        _claimPayout(msg.sender);
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
    function distribute(uint256 _amount) external onlyOwner {
        payoutToken.transferFrom(msg.sender, address(this), _amount);

        // Calculate the amount to be distributed
        (uint256 actualDistributionAmount,) = payoutToken.calculateDistribution(address(this), 0, _amount);

        // Distribute the token according to the calculated amount
        payoutToken.distribute(0, actualDistributionAmount);
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(address _user) external onlyOwner {
        // Claim payout for the current Drop ID
        _claimPayout(_user);
    }

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _users array containing the users addresses to be claimed for
     */
    function claimPayoutsOnMultipleBehalf(address[] memory _users) external onlyOwner {
        // Loop through all users passed as parameter
        for (uint256 i = 0; i < _users.length; ++i) {
            // Claim payout for the current Drop ID
            _claimPayout(_users[i]);
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
     *  Only Anotherblock Relay contract can perform this operation
     *
     */
    function initPayoutIndex(uint32 _index) external onlyNFT {
        payoutToken.createIndex(_index);
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Relay contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _indexes array of corresponding index
     * @param _quantities array of quantity (per index)
     */
    function updatePayout1155(
        address _previousHolder,
        address _newHolder,
        uint256[] calldata _indexes,
        uint256[] calldata _quantities
    ) external onlyNFT {
        for (uint256 i = 0; i < _indexes.length; ++i) {
            // Remove `_quantity` of `_dropId` shares from `_previousHolder`
            _loseShare(_previousHolder, _indexes[i], _quantities[i] * IDA_UNITS_PRECISION);

            // Add `_quantity` of `_dropId` shares to `_newHolder`
            _gainShare(_newHolder, _indexes[i], _quantities[i] * IDA_UNITS_PRECISION);
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
    function updatePayout721(address _previousHolder, address _newHolder, uint256 _quantity) external onlyNFT {
        // Remove `_quantity` of `_dropId` shares from `_previousHolder`
        _loseShare(_previousHolder, 0, _quantity * IDA_UNITS_PRECISION);

        // Add `_quantity` of `_dropId` shares to `_newHolder`
        _gainShare(_newHolder, 0, _quantity * IDA_UNITS_PRECISION);
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
    function getUserSubscription(address _user) external view returns (uint256) {
        // Get the subscriber's current units
        (,, uint256 currentUnitsHeld,) = payoutToken.getSubscription(address(this), 0, _user);
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
    function getClaimableAmount(address _user) external view returns (uint256) {
        // Get the subscriber's pending amount to be claimed
        (,,, uint256 pendingDistribution) = payoutToken.getSubscription(address(this), 0, _user);
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
    function getIndexInfo()
        external
        view
        returns (uint128 indexValue, uint128 totalUnitsApproved, uint128 totalUnitsPending)
    {
        (, indexValue, totalUnitsApproved, totalUnitsPending) = payoutToken.getIndex(address(this), 0);
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
    function _gainShare(address _subscriber, uint256 _index, uint256 _units) internal {
        // Ensure subscriber address is not zero-address
        if (_subscriber == address(0)) return;

        // Get the subscriber's current units
        (,, uint256 currentUnitsHeld,) = payoutToken.getSubscription(address(this), uint32(_index), _subscriber);

        // Add `_units` to the subscriber current units amount
        payoutToken.updateSubscriptionUnits(uint32(_index), _subscriber, uint128(currentUnitsHeld + _units));
    }

    /**
     * @notice
     *  Remove subscription units from the subscriber
     *
     * @param _subscriber subscriber address
     * @param _units amount of units to remove
     */
    function _loseShare(address _subscriber, uint256 _index, uint256 _units) internal {
        // Ensure subscriber address is not zero-address
        if (_subscriber == address(0)) return;

        // Get the subscriber's current units
        (,, uint256 currentUnitsHeld,) = payoutToken.getSubscription(address(this), uint32(_index), _subscriber);

        // Check if the new amount of units is null
        if (currentUnitsHeld - _units <= 0) {
            // Delete the user's subscription
            payoutToken.deleteSubscription(address(this), uint32(_index), _subscriber);
        } else {
            // Remove `_units` from the subscriber current units amount
            payoutToken.updateSubscriptionUnits(uint32(_index), _subscriber, uint128(currentUnitsHeld - _units));
        }
    }

    /**
     * @notice
     *  Claim the user's owed royalties for the given Drop IDs
     *
     * @param _user user address
     */
    function _claimPayout(address _user) internal {
        // Claim the distributed Tokens
        payoutToken.claim(address(this), 0, _user);
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  _____
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/

    modifier onlyFactory() {
        require(msg.sender == anotherFactory);
        _;
    }

    modifier onlyNFT() {
        require(msg.sender == nft);
        _;
    }
}
