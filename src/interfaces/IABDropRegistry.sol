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
 * @title IABDropRegistry
 * @author Anotherblock Technical Team
 * @notice Anotherblock Drop Registry interface
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IABDropRegistry {
    //     ____        __         ___                                         __
    //    / __ \____  / /_  __   /   |  ____  ____  _________ _   _____  ____/ /
    //   / / / / __ \/ / / / /  / /| | / __ \/ __ \/ ___/ __ \ | / / _ \/ __  /
    //  / /_/ / / / / / /_/ /  / ___ |/ /_/ / /_/ / /  / /_/ / |/ /  __/ /_/ /
    //  \____/_/ /_/_/\__, /  /_/  |_/ .___/ .___/_/   \____/|___/\___/\__,_/
    //               /____/         /_/   /_/

    /**
     * @notice
     *  Register a new drop
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _nft contract address to be registered
     * @param _publisher address of the drop publisher
     * @param _tokenId token identifier (0 if ERC-721)
     *
     * @return _dropId identifier of the new drop
     */
    function registerDrop(address _nft, address _publisher, uint256 _tokenId) external returns (uint256 _dropId);

    /**
     * @notice
     *  Set allowed status to true for the given `_nft` contract address
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _nft nft contract address to be allowed to register new drop
     */

    function allowNFT(address _nft) external;

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    function setAnotherCloneFactory(address _anotherCloneFactory) external;
}
