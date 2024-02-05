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
 * @title ABEvents
 * @author anotherblock Technical Team
 * @notice A standard library of events used throughout anotherblock contracts
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ABEvents {
    /// @dev Event emitted when a new publisher is registered
    event PublisherRegistered(address account, address indexed abRoyalty);

    /// @dev Event emitted when a new collection is created
    event CollectionCreated(address indexed nft, address indexed publisher);

    /// @dev Event emitted when a new drop is registered
    event DropRegistered(uint256 indexed dropId, uint256 indexed tokenId, address nft, address publisher);

    /// @dev Event emitted upon phase update
    event UpdatedPhase(uint256 numOfPhase);

    /// @dev Event emitted upon royalty distribution
    event RoyaltyDistributed(uint256 dropId, uint256 amount);

    /// @dev Event emitted upon royalty distribution for multiple drops
    event RoyaltyDistributedMultiDrop(uint256[] dropIds, uint256[] amount);

    /// @dev Event emitted upon royalty claimed
    event RoyaltyClaimed(uint256 dropId, uint256[] tokenIds, uint256 amount);

    /// @dev Event emitted upon initialization of Data Registry
    event DataRegistryInitialized(address treasury, uint256 dropIdOffset);

    /// @dev Event emitted upon publisher fee updates
    event PublisherFeesUpdated(address publisher, uint256 fee);

    /// @dev Event emitted upon approving or updating an ERC721 implementation within AnotherCloneFactory
    event UpdatedERC721Implementation(uint256 implementationId, address implementationAddress);

    /// @dev Event emitted upon updating the L1 ownership registry in ABClaim contract
    event HoldingsUpdated(uint256 dropId, uint256 tokenId, address newOwner);

    /// @dev Event emitted upon updating by batch the L1 ownership registry in ABClaim contract
    event HoldingsBatchUpdated(uint256 dropId, uint256[] tokenIds, address[] newOwners);

    /// @dev Event emitted upon updating drop data in ABClaim contract
    event DropDataUpdated(uint256 dropId, address nft, bool isL1, uint256 supply);

    /// @dev Event emitted upon updating drop data by batch in ABClaim contract
    event DropDataBatchUpdated(uint256[] dropId, address[] nft, bool[] isL1, uint256[] supply);
}
