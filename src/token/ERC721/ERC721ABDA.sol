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
 * @title ERC721ABDA
 * @author anotherblock Technical Team
 * @notice anotherblock ERC721 contract standard implementing Dutch Auction
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* anotherblock Contract */
import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";

/* anotherblock Libraries */
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

contract ERC721ABDA is ERC721AB {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Supply cap for this collection
    uint256 public maxSupply;

    ///@dev DUTCH AUCTION PARAMETERS
    uint256 public startingPrice;
    uint256 public startAt;
    uint256 public expiresAt;
    uint256 public discountRate;

    /// @dev Implementation Type
    bytes32 public constant IMPLEMENTATION_TYPE = keccak256("DUTCH_AUCTION");

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

    function mint(address _to, uint256 _quantity) external payable {
        // Check that there are enough tokens available for sale
        if (_totalMinted() + _quantity > maxSupply) {
            revert ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check that the dutch auction is in progress
        if (block.timestamp >= expiresAt || block.timestamp < startAt) revert ABErrors.PHASE_NOT_ACTIVE();

        // Get current auction price
        uint256 price = getPrice();

        // Ensure that the sender sent enough ETH
        if (msg.value < price) revert ABErrors.INCORRECT_ETH_SENT();

        // Mint the NFT to `_to` address
        _mint(_to, 1);

        // Calculate if there are refunds to be made
        uint256 refund = msg.value - price;

        if (refund > 0) {
            // Transfer the excess ETH sent
            (bool success,) = _to.call{value: refund}("");
            if (!success) revert ABErrors.TRANSFER_FAILED();
        }
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

    function initAuction(uint256 _startingPrice, uint256 _startAt, uint256 _discountRate, uint256 _duration)
        external
        onlyOwner
    {
        if (_startingPrice < _discountRate * _duration) revert ABErrors.INVALID_PARAMETER();

        // Set Dutch Auction parameters
        startingPrice = _startingPrice;
        startAt = _startAt;
        expiresAt = _startAt + _duration;
        discountRate = _discountRate;

        // Emit Dutch Auction Initialized event
        emit ABEvents.DutchAuctionInitialized(_startingPrice, _startAt, expiresAt, _discountRate);
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

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function getPrice() public view returns (uint256 _price) {
        // Calculate the time elapsed since the auction start
        uint256 timeElapsed = block.timestamp - startAt;

        // Calculate the rebate
        uint256 discount = discountRate * timeElapsed;

        // Return the current auction price
        _price = startingPrice - discount;
    }
}
