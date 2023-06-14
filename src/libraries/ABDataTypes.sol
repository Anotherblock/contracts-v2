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
 * @title ABDataTypes
 * @author Anotherblock Technical Team
 * @notice A standard library of data types used throughout Anotherblock contracts
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ABDataTypes {
    /**
     * @notice
     *  Phase Structure format
     *
     * @param phaseStart timestamp at which the phase starts
     * @param phaseEnd timestamp at which the phase ends
     * @param price price for one token during the phase
     * @param maxMint maximum number of token to be minted per user during the phase
     */

    struct Phase {
        uint256 phaseStart;
        uint256 phaseEnd;
        uint256 price;
        uint256 maxMint;
    }

    /**
     * @notice
     *  TokenDetails Structure format
     *
     * @param dropId drop identifier
     * @param mintedSupply amount of tokens minted
     * @param maxSupply maximum supply
     * @param numOfPhase number of phases
     * @param sharePerToken percentage ownership of the full master right for one token (to be divided by 1e6)
     * @param phases mint phases (see phase structure format)
     * @param uri token URI
     */
    struct TokenDetails {
        uint256 dropId;
        uint256 mintedSupply;
        uint256 maxSupply;
        uint256 numOfPhase;
        uint256 sharePerToken;
        mapping(uint256 phaseId => Phase phase) phases;
        string uri;
    }

    /**
     * @notice
     *  MintParams Structure format
     *
     * @param tokenId token identifier to be minted
     * @param phaseId current minting phase
     * @param quantity quantity requested
     * @param signature signature to verify allowlist
     */
    struct MintParams {
        uint256 tokenId;
        uint256 phaseId;
        uint256 quantity;
        bytes signature;
    }

    /**
     * @notice
     *  InitDropParams Structure format
     *
     * @param maxSupply supply cap for this drop
     * @param sharePerToken percentage ownership of the full master right for one token (to be divided by 1e6)
     * @param mintGenesis amount of genesis tokens to be minted
     * @param genesisRecipient recipient address of genesis tokens
     * @param royaltyCurrency royalty currency contract address
     * @param uri token URI for this drop
     */
    struct InitDropParams {
        uint256 maxSupply;
        uint256 sharePerToken;
        uint256 mintGenesis;
        address genesisRecipient;
        address royaltyCurrency;
        string uri;
    }
}
