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
 * @title ABDataRegistry
 * @author Anotherblock Technical Team
 * @notice Anotherblock Data Registry contract interface
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IABDataRegistry {
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
     * @param _publisher address of the drop publisher
     * @param _tokenId token identifier (0 if ERC-721)
     *
     * @return _dropId identifier of the new drop
     */
    function registerDrop(address _publisher, uint256 _tokenId) external returns (uint256 _dropId);

    /**
     * @notice
     *  Register a new publisher
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _publisher address of the publisher
     * @param _abRoyalty address of ABRoyalty contract associated to this publisher
     *
     */
    function registerPublisher(address _publisher, address _abRoyalty, uint256 _publisherFee) external;

    /**
     * @notice
     *  Update the subscription units on token transfer
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _publisher publisher address
     * @param _from previous holder address
     * @param _to new holder address
     * @param _dropId drop identifier
     * @param _quantity quantity of tokens transferred
     */
    function on721TokenTransfer(address _publisher, address _from, address _to, uint256 _dropId, uint256 _quantity)
        external;

    /**
     * @notice
     *  Update the subscription units on ERC721 token transfer
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _publisher publisher address
     * @param _from previous holder address
     * @param _to new holder address
     * @param _dropIds array of drop identifier
     * @param _quantities array of quantities
     */
    function on1155TokenTransfer(
        address _publisher,
        address _from,
        address _to,
        uint256[] memory _dropIds,
        uint256[] memory _quantities
    ) external;

    /**
     * @notice
     *  Set allowed status to true for the given `_nft` contract address
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _collection nft contract address to be granted with the collection role
     */

    function grantCollectionRole(address _collection) external;
    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Set AnotherCloneFactory contract address
     *  Only the contract owner can perform this operation
     *
     * @param _anotherCloneFactory address of AnotherCloneFactory contract
     */
    function setAnotherCloneFactory(address _anotherCloneFactory) external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Return true if `_account` is a publisher, false otherwise
     *
     * @param _account address to be queried
     *
     * @return _isPublisher true if `_account` is a publisher, false otherwise
     */
    function isPublisher(address _account) external view returns (bool _isPublisher);

    /**
     * @notice
     *  Return the royalty contract address associated to the given `_publisher`
     *
     * @param _publisher publisher to be queried
     *
     * @return _royalty the royalty contract address associated to the given `_publisher`
     */
    function getRoyaltyContract(address _publisher) external view returns (address _royalty);

    /**
     * @notice
     *  Set the treasury account address
     *
     * @param _abTreasury the treasury account address to be set
     */
    function setTreasury(address _abTreasury) external;

    /**
     * @notice
     *  Return the fee percentage associated to the given `_publisher`
     *
     * @param _publisher publisher to be queried
     *
     * @return _fee the royalty contract address associated to the given `_publisher`
     */
    function getPublisherFee(address _publisher) external view returns (uint256 _fee);

    /**
     * @notice
     *  Return the details required to withdraw the mint proceeds
     *
     * @param _publisher publisher to be queried
     *
     * @return _treasury the treasury account address
     * @return _fee the fees associated to the given `_publisher`
     */
    function getPayoutDetails(address _publisher) external view returns (address _treasury, uint256 _fee);
}
