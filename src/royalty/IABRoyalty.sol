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
 * @title IABRoyalty
 * @author Anotherblock Technical Team
 * @notice ABRoyalty contract interface
 *
 */

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
    function claimPayout(uint256 _dropId) external;

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
    function distribute(uint256 _dropId, uint256 _amount, bool _prepaid) external;

    /**
     * @notice
     *  Distribute the royalty for the given Drop ID on behalf of the publisher
     *  Only ABDataRegistry contract can perform this operation
     *
     * @param _dropId drop identifier
     * @param _amount amount to be paid-out
     */
    function distributeOnBehalf(uint256 _dropId, uint256 _amount) external;

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _user address of the user to be claimed for
     */
    function claimPayoutsOnBehalf(uint256 _dropId, address _user) external;

    /**
     * @notice
     *  Claim the owed royalties for the given Drop IDs on behalf of the user
     *  Only EOA with role MANUAL_UPDATER_ROLE can perform this operation
     *
     * @param _users array containing the users addresses to be claimed for
     */
    function claimPayoutsOnMultipleBehalf(uint256 _dropId, address[] memory _users) external;

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
    function initPayoutIndex(address _nft, address _royaltyCurrency, uint256 _dropId) external;

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
    function updatePayout721(address _previousHolder, address _newHolder, uint256 _dropId, uint256 _quantity)
        external;
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
    function getUserSubscription(uint256 _dropId, address _user) external view returns (uint256);
    /**
     * @notice
     *  Get the amount of royalty to be claimed by the user
     *
     * @param _user user address to be queried
     *
     * @return : amount of royalty to be claimed by the user for the given Drop ID
     */
    function getClaimableAmount(uint256 _dropId, address _user) external view returns (uint256);

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
        returns (uint128 indexValue, uint128 totalUnitsApproved, uint128 totalUnitsPending);
}
