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
 * @title ERC721ABEA
 * @author anotherblock Technical Team
 * @notice anotherblock ERC721 contract standard implementing English Auction
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* anotherblock Contract */
import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";

/* anotherblock Libraries */
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

contract ERC721ABEA is ERC721AB {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Supply cap for this collection
    uint256 public maxSupply;

    /// @dev ENGLISH AUCTION PARAMETERS
    uint256 public endAt;
    uint256 public startAt;
    uint256 public expiresAt;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

    /// @dev Implementation Type
    bytes32 public constant IMPLEMENTATION_TYPE = keccak256("ENGLISH_AUCTION");

    /// @dev ERC721AB implementation version
    uint8 public constant IMPLEMENTATION_VERSION = 1;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function bid() external payable {
        if (block.timestamp < startAt || block.timestamp >= expiresAt) revert ABErrors.PHASE_NOT_ACTIVE();
        if (msg.value <= highestBid) revert ABErrors.INCORRECT_ETH_SENT();

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit ABEvents.EnglishAuctionBid(msg.sender, msg.value);
    }

    function withdraw() external {
        address sender = msg.sender;

        // Cannot withdraw if highestBidder
        if (sender == highestBidder) revert ABErrors.INVALID_PARAMETER();

        uint256 bal = bids[sender];
        bids[sender] = 0;

        (bool success,) = sender.call{value: bal}("");
        if (!success) revert ABErrors.TRANSFER_FAILED();

        emit ABEvents.EnglishAuctionWithdraw(sender, bal);
    }

    function end() external {
        if (block.timestamp < startAt || block.timestamp < expiresAt) revert ABErrors.PHASE_NOT_ACTIVE();

        if (highestBidder != address(0)) {
            _mint(highestBidder, 1);
        }

        emit ABEvents.EnglishAuctionEnd(highestBidder, highestBid);
    }

    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //               /____/

    /**
     * @notice
     *  Initialize the Drop parameters
     *  Only the contract owner can perform this operation
     *
     * @param _maxSupply supply cap for this drop
     * @param _sharePerToken percentage ownership of the full master right for one token (to be divided by 1e6)
     * @param _mintGenesis amount of genesis tokens to be minted
     * @param _genesisRecipient recipient address of genesis tokens
     * @param _royaltyCurrency royalty currency contract address
     * @param _baseUri base URI for this drop
     */
    function initDrop(
        uint256 _maxSupply,
        uint256 _sharePerToken,
        uint256 _mintGenesis,
        address _genesisRecipient,
        address _royaltyCurrency,
        string calldata _baseUri
    ) external virtual onlyOwner {
        // Set supply cap
        maxSupply = _maxSupply;
        if (_mintGenesis > _maxSupply) revert ABErrors.INVALID_PARAMETER();

        // initialize drop
        _initDrop(_sharePerToken, _mintGenesis, _genesisRecipient, _royaltyCurrency, _baseUri);
    }

    function initAuction(uint256 _startingBid, uint256 _startAt, uint256 _expiresAt) external onlyOwner {
        highestBid = _startingBid;
        startAt = _startAt;
        expiresAt = _expiresAt;

        emit ABEvents.EnglishAuctionInitialized(_startingBid, _startAt, _expiresAt);
    }

    /**
     * @notice
     *  Set the maximum supply
     *  Only the contract owner can perform this operation
     *
     * @param _maxSupply new maximum supply to be set
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < _totalMinted()) revert ABErrors.INVALID_PARAMETER();
        maxSupply = _maxSupply;
    }
}
