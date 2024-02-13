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
 * @title IABMockRoyalty
 * @author anotherblock Technical Team
 * @notice anotherblock contract responsible for paying out royalties
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IABMockRoyalty {
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
    function initPayoutIndex(address _nft, address _royaltyCurrency, uint256 _dropId) external;

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
    ) external;

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
        external;
}
