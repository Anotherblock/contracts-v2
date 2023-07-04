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
 * @title ABErrors
 * @author Anotherblock Technical Team
 * @notice A standard library of custom revert errors used throughout Anotherblock contracts
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ABErrors {
    ///@dev Error returned if the drop has already been initialized
    error DROP_ALREADY_INITIALIZED();

    /// @dev Error returned if supply is insufficient
    error NOT_ENOUGH_TOKEN_AVAILABLE();

    /// @dev Error returned if user did not send the correct amount of ETH
    error INCORRECT_ETH_SENT();

    /// @dev Error returned if the requested phase is not active
    error PHASE_NOT_ACTIVE();

    /// @dev Error returned if user attempt to mint more than allowed
    error MAX_MINT_PER_ADDRESS();

    /// @dev Error returned if user is not eligible to mint during the current phase
    error NOT_ELIGIBLE();

    /// @dev Error returned when the passed parameter is incorrect
    error INVALID_PARAMETER();

    /// @dev Error returned if user attempt to mint while the phases are not set
    error PHASES_NOT_SET();

    /// @dev Error returned when the withdraw transfer fails
    error TRANSFER_FAILED();

    /// @dev Error returned when attempting to create a publisher profile with an account already publisher
    error ACCOUNT_ALREADY_PUBLISHER();

    /// @dev Error returned when attempting to create a collection with an account that is not registered publisher
    error ACCOUNT_NOT_PUBLISHER();
}
