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
 * @title IABKYCModule
 * @author anotherblock Technical Team
 * @notice anotherblock contract responsible for verifying KYC signature validity
 * @custom:contact info@anotherblock.io
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IABKYCModule {
    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Return true if the user is KYC'd, false otherwise
     *
     * @param _user user address
     * @param _signature signature generated by AB Backend and signed by AB KYC Signer
     */
    function beforeMint(address _user, bytes calldata _signature) external view;

    /**
     * @notice
     *  Return true if the user is KYC'd, false otherwise
     *
     * @param _to user address
     */
    function beforeTransfer(address _to) external view;

    /**
     * @notice
     *  Return true if the user is KYC'd, false otherwise
     *
     * @param _user user address
     * @param _signature signature generated by AB Backend and signed by AB KYC Signer
     */
    function beforeRoyaltyClaim(address _user, bytes calldata _signature) external view;

    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //               /____/

    /**
     * @notice
     *  Set the default allowlist signer address
     *
     * @param _defaultSigner : address signing the allowed user for a given drop / phase
     */
    function setDefaultSigner(address _defaultSigner) external;

    /**
     * @notice
     *  Increment the current nonce
     *
     */
    function incrementNonce() external;

    /**
     * @notice
     *  Set a specific allowlist `_signer` for a given `_collection`
     *
     * @param _collection : collection contract address associated to the signer
     * @param _signer : address signing the allowed user for the given collection
     */
    function setCollectionSigner(address _collection, address _signer) external;
    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Get allowlist signer for a given `_collection`
     *
     * @param _collection NFT contract address
     *
     * @return _signer signer for the given `_collection`
     */
    function getSigner(address _collection) external view returns (address _signer);
}
