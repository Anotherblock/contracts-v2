// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IABRoyalty {
    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Claim the owed royalties
     */
    function claimPayout() external;

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
    ) external;

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Relay contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _quantity array of quantity (per index)
     */
    function updatePayout721(
        address _previousHolder,
        address _newHolder,
        uint256 _quantity
    ) external;

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
    function distribute(uint256 _amount) external;

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(address _user) external;

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _users array containing the users addresses to be claimed for
     */
    function claimPayoutsOnMultipleBehalf(address[] memory _users) external;

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
    function initPayoutIndex(uint32 _index) external;

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
    function getUserSubscription(address _user) external view returns (uint256);

    /**
     * @notice
     *  Get the amount of royalty to be claimed by the user
     *
     * @param _user user address to be queried
     *
     * @return : amount of royalty to be claimed by the user for the given Drop ID
     */
    function getClaimableAmount(address _user) external view returns (uint256);

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
        returns (
            uint128 indexValue,
            uint128 totalUnitsApproved,
            uint128 totalUnitsPending
        );
}
