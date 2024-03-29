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
 * @author anotherblock Technical Team
 * @notice A standard library of custom revert errors used throughout anotherblock contracts
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ABErrors {
    ///@dev Error returned if the drop has already been initialized
    error DROP_ALREADY_INITIALIZED();

    ///@dev Error returned if the drop has not been initialized
    error DROP_NOT_INITIALIZED();

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

    /// @dev Error returned if supertoken is unable to create a new index
    error SUPERTOKEN_INDEX_ERROR();

    /// @dev Error returned when a user is trying to claim royalties for a token that they doesn't own
    error NOT_TOKEN_OWNER();

    /// @dev Error returned when a non-KYC user attempt an operation that requires KYC
    error NO_KYC();

    /// @dev Error returned when attempting to mint using ERC20 while it is not accepted
    error MINT_WITH_ERC20_NOT_AVAILABLE();

    /// @dev Error returned when the ERC-20 transfer failed when minting NFTs
    error ERROR_PROCEEDING_PAYMENT();
}
