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
 * @author anotherblock Technical Team
 * @notice anotherblock Data Registry contract interface
 * @custom:contact info@anotherblock.io
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IABDataRegistry {
    //     ____        __         ______      ____          __  _
    //    / __ \____  / /_  __   / ____/___  / / /__  _____/ /_(_)___  ____
    //   / / / / __ \/ / / / /  / /   / __ \/ / / _ \/ ___/ __/ / __ \/ __ \
    //  / /_/ / / / / / /_/ /  / /___/ /_/ / / /  __/ /__/ /_/ / /_/ / / / /
    //  \____/_/ /_/_/\__, /   \____/\____/_/_/\___/\___/\__/_/\____/_/ /_/
    //               /____/
    /**
     * @notice
     *  Register a new drop
     *  Only previously allowed NFT contracts can perform this operation
     *
     * @param _publisher address of the drop publisher
     * @param _royaltyCurrency royalty currency contract address
     * @param _tokenId token identifier (0 if ERC-721)
     *
     * @return _dropId identifier of the new drop
     */
    function registerDrop(address _publisher, address _royaltyCurrency, uint256 _tokenId)
        external
        returns (uint256 _dropId);

    /**
     * @notice
     *  Update the subscription units on ERC721 token transfer
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

    //     ____        __         ______           __
    //    / __ \____  / /_  __   / ____/___ ______/ /_____  _______  __
    //   / / / / __ \/ / / / /  / /_  / __ `/ ___/ __/ __ \/ ___/ / / /
    //  / /_/ / / / / / /_/ /  / __/ / /_/ / /__/ /_/ /_/ / /  / /_/ /
    //  \____/_/ /_/_/\__, /  /_/    \__,_/\___/\__/\____/_/   \__, /
    //               /____/                                   /____/

    /**
     * @notice
     *  Register a new publisher
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _publisher address of the publisher
     * @param _abRoyalty address of ABRoyalty contract associated to this publisher
     * @param _publisherFee fees taken by the publisher
     *
     */
    function registerPublisher(address _publisher, address _abRoyalty, uint256 _publisherFee) external;

    /**
     * @notice
     *  Set allowed status to true for the given `_collection` contract address
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _collection nft contract address to be granted with the collection role
     */

    function grantCollectionRole(address _collection) external;

    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //               /____/

    /**
     * @notice
     *  Distribute the royalty for the given Drop ID on behalf of the publisher
     *  Only contract owner can perform this operation
     *
     * @param _publisher publisher address corresponding to the drop id to be paid-out
     * @param _dropId drop identifier
     * @param _amount amount to be paid-out
     */
    function distributeOnBehalf(address _publisher, uint256 _dropId, uint256 _amount) external;

    /**
     * @notice
     *  Set the treasury account address
     *  Only contract owner can perform this operation
     *
     * @param _abTreasury the treasury account address to be set
     */
    function setTreasury(address _abTreasury) external;

    /**
     * @notice
     *  Update a publisher fee
     *  Only contract owner can perform this operation
     *
     * @param _publisher publisher account to be updated
     * @param _fee new fees to be set
     */
    function setPublisherFee(address _publisher, uint256 _fee) external;

    /**
     * @notice
     *  Update a drop specific fee
     *  Only contract owner can perform this operation
     *
     * @param _isSpecific true to apply specific fee or false to apply publisher fee
     * @param _dropId drop identifier to be updated
     * @param _fee new fees to be set
     */
    function setDropFee(bool _isSpecific, uint256 _dropId, uint256 _fee) external;

    /**
     * @notice
     *  Update a publisher royalty contract
     *  Only contract owner can perform this operation
     *
     * @param _publisher publisher account to be updated
     * @param _abRoyalty new ABRoyalty contract address
     */
    function updatePublisher(address _publisher, address _abRoyalty) external;

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
     *  Return the fee percentage associated to the given `_publisher`
     *
     * @param _publisher publisher to be queried
     *
     * @return _fee the fees associated to the given `_publisher`
     */
    function getPublisherFee(address _publisher) external view returns (uint256 _fee);

    /**
     * @notice
     *  Return the details required to withdraw the mint proceeds
     *
     * @param _publisher publisher to be queried
     * @param _dropId drop identifier to be queried
     *
     * @return _treasury the treasury account address
     * @return _fee the fees associated to the given `_publisher`
     */
    function getPayoutDetails(address _publisher, uint256 _dropId)
        external
        view
        returns (address _treasury, uint256 _fee);
}
