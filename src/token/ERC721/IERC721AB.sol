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
 * @title ERC721AB
 * @author anotherblock Technical Team
 * @notice anotherblock ERC721 contract standard
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ERC721AB {
    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //               /____/

    /**
     * @notice
     *  Update the Base URI
     *  Only the contract owner can perform this operation
     *
     * @param _newBaseURI new base URI
     */
    function setBaseURI(string calldata _newBaseURI) external;

    /**
     * @notice
     *  Update the share per token percentage
     *  Only the contract owner can perform this operation
     *
     * @param _newSharePerToken new share per token value
     */
    function setSharePerToken(uint256 _newSharePerToken) external;

    /**
     * @notice
     *  Set the sale phases for drop
     *  Only the contract owner can perform this operation
     *
     * @param _phases array of phases to be set (see Phase structure format)
     */

    function setDropPhases(ABDataTypes.Phase[] calldata _phases) external;

    /**
     * @notice
     *  Withdraw the mint proceeds
     *  Only the contract owner can perform this operation
     *
     */
    function withdrawToRightholder() external;

    /**
     * @notice
     *  Withdraw ERC20 tokens from this contract to the caller
     *  Only the contract owner can perform this operation
     *
     * @param _token token contract address to be withdrawn
     * @param _amount amount to be withdrawn
     */
    function withdrawERC20(address _token, uint256 _amount) external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable) returns (bool);

    /**
     * @notice
     *  Returns the NFT symbol
     *
     * @return _symbol NFT symbol
     */
    function symbol() public view virtual override returns (string memory _symbol);

    /**
     * @notice
     *  Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param _tokenId token identifier to be queried
     *
     * @return _tokenURI the token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory _tokenURI);
}
