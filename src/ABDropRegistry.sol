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
 * @title ABDropRegistry
 * @author Anotherblock Technical Team
 * @notice Anotherblock Drop Registry contract responsible for housekeeping drop details
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ABDropRegistry is Ownable {
    /**
     * @notice
     *  Drop Structure format
     *
     * @param dropId drop identifier
     * @param tokenId token identifier (0 if ERC-721)
     * @param publisher address of the drop publisher
     * @param nft NFT contract address
     */
    struct Drop {
        uint256 dropId;
        uint256 tokenId;
        address publisher;
        address nft;
    }

    /// @dev Error returned when caller is not authorized to perform operation
    error FORBIDDEN();

    /// @dev Event emitted when a new drop is registered
    event DropRegistered(uint256 dropId, uint256 tokenId, address nft, address publisher);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Collection identifier offset
    uint256 private immutable DROP_ID_OFFSET;

    /// @dev AnotherCloneFactory contract address
    address public anotherCloneFactory;

    /// @dev Mapping storing the allowed status of a given NFT contract
    mapping(address nft => bool isAllowed) private allowedNFT;

    /// @dev Array of all Drops (see Drop structure format)
    Drop[] public drops;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    constructor(uint256 _offset) {
        DROP_ID_OFFSET = _offset;
    }

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
    function registerDrop(address _nft, address _publisher, uint256 _tokenId)
        external
        onlyAllowed
        returns (uint256 _dropId)
    {
        // Get the next drop identifier available
        _dropId = _getNextDropId();

        // Store the new drop details in the drops array
        drops.push(Drop(_dropId, _tokenId, _publisher, _nft));

        // Emit the DropRegistered event
        emit DropRegistered(_dropId, _tokenId, _nft, _publisher);
    }

    /**
     * @notice
     *  Set allowed status to true for the given `_nft` contract address
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _nft nft contract address to be allowed to register new drop
     */

    function allowNFT(address _nft) external onlyFactory {
        // Set the allowed registration status to TRUE
        allowedNFT[_nft] = true;
    }

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
     *
     */
    function setAnotherCloneFactory(address _anotherCloneFactory) external onlyOwner {
        anotherCloneFactory = _anotherCloneFactory;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Calculate and return the next drop ID available
     *
     * @return _nextDropId next drop ID available
     */
    function _getNextDropId() internal view returns (uint256 _nextDropId) {
        _nextDropId = DROP_ID_OFFSET + drops.length + 1;
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  _____
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/

    /**
     * @notice
     *  Ensure that the call is coming from an approved NFT collection contract
     */
    modifier onlyAllowed() {
        if (!allowedNFT[msg.sender]) {
            revert FORBIDDEN();
        }
        _;
    }

    /**
     * @notice
     *  Ensure that the call is coming from AnotherCloneFactory contract
     */
    modifier onlyFactory() {
        if (msg.sender != anotherCloneFactory) {
            revert FORBIDDEN();
        }
        _;
    }
}

//     ______     __                        __   ______                 __  _
//    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
//   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
//  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
// /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

//   _    ___                 ______                 __  _
//  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
//  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
//  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
//  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
