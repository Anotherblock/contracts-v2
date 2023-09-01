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

/* ERC721A Contract */
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/* anotherblock Libraries */
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

/* anotherblock Interfaces */
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";

contract ERC721ABEA is ERC721AUpgradeable, OwnableUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev anotherblock Drop Registry contract interface (see IABDataRegistry.sol)
    IABDataRegistry public abDataRegistry;

    /// @dev Publisher address
    address public publisher;

    /// @dev Drop Identifier
    uint256 public dropId;

    /// @dev Supply cap for this collection
    uint256 public maxSupply;

    /// @dev Percentage ownership of the full master right for one token (to be divided by 1e6)
    uint256 public sharePerToken;

    /// @dev Base Token URI
    string internal baseTokenURI;

    /// @dev ERC721AB implementation version
    uint8 public constant IMPLEMENTATION_VERSION = 1;

    /// @dev ENGLISH AUCTION PARAMETERS
    uint256 public endAt;
    uint256 public startAt;
    uint256 public expiresAt;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

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

    /**
     * @notice
     *  Contract Initializer (Minimal Proxy Contract)
     *
     * @param _publisher publisher address of this collection
     * @param _abDataRegistry ABDropRegistry contract address
     * @param _name NFT collection name
     */
    function initialize(address _publisher, address _abDataRegistry, address, string memory _name)
        external
        initializerERC721A
        initializer
    {
        // Initialize ERC721A
        __ERC721A_init(_name, "");

        // Initialize Ownable
        __Ownable_init();
        _transferOwnership(_publisher);

        dropId = 0;

        // Assign ABDataRegistry address
        abDataRegistry = IABDataRegistry(_abDataRegistry);

        // Assign the publisher address
        publisher = _publisher;
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
        // Check that the drop hasn't been already initialized
        if (dropId != 0) revert ABErrors.DROP_ALREADY_INITIALIZED();

        // Check that share per token & royalty currency are consistent
        if (
            (_sharePerToken == 0 && _royaltyCurrency != address(0))
                || (_royaltyCurrency == address(0) && _sharePerToken != 0)
        ) revert ABErrors.INVALID_PARAMETER();

        // Register Drop within ABDropRegistry
        dropId = abDataRegistry.registerDrop(publisher, _royaltyCurrency, 0);

        // Set supply cap
        maxSupply = _maxSupply;

        // Set the royalty share
        sharePerToken = _sharePerToken;

        // Set base URI
        baseTokenURI = _baseUri;

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_mintGenesis > 0) {
            if (_mintGenesis > _maxSupply) revert ABErrors.INVALID_PARAMETER();
            _mint(_genesisRecipient, _mintGenesis);
        }
    }

    function initAuction(uint256 _startingBid, uint256 _startAt, uint256 _expiresAt) external onlyOwner {
        highestBid = _startingBid;
        startAt = _startAt;
        expiresAt = _expiresAt;

        emit ABEvents.EnglishAuctionInitialized(_startingBid, _startAt, _expiresAt);
    }

    /**
     * @notice
     *  Update the Base URI
     *  Only the contract owner can perform this operation
     *
     * @param _newBaseURI new base URI
     */

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice
     *  Update the share per token percentage
     *  Only the contract owner can perform this operation
     *
     * @param _newSharePerToken new share per token value
     */
    function setSharePerToken(uint256 _newSharePerToken) external onlyOwner {
        sharePerToken = _newSharePerToken;
    }

    /**
     * @notice
     *  Withdraw the mint proceeds
     *  Only the contract owner can perform this operation
     *
     */
    function withdrawToRightholder() external onlyOwner {
        (address abTreasury, uint256 fee) = abDataRegistry.getPayoutDetails(publisher);

        if (abTreasury == address(0)) revert ABErrors.INVALID_PARAMETER();

        uint256 balance = address(this).balance;
        uint256 amountToRH = balance * fee / 10_000;
        uint256 amountToTreasury = balance - amountToRH;

        if (amountToTreasury > 0) {
            (bool success,) = abTreasury.call{value: amountToTreasury}("");
            if (!success) revert ABErrors.TRANSFER_FAILED();
        }

        if (amountToRH > 0) {
            (bool success,) = publisher.call{value: amountToRH}("");
            if (!success) revert ABErrors.TRANSFER_FAILED();
        }
    }

    /**
     * @notice
     *  Withdraw ERC20 tokens from this contract to the caller
     *  Only the contract owner can perform this operation
     *
     * @param _token token contract address to be withdrawn
     * @param _amount amount to be withdrawn
     */
    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        // Transfer amount of underlying token to the caller
        IERC20(_token).transfer(msg.sender, _amount);
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice
     *  Returns the NFT symbol
     *
     * @return _symbol NFT symbol
     */
    function symbol() public view virtual override returns (string memory _symbol) {
        if (dropId != 0) {
            _symbol = string.concat("AB", Strings.toString(dropId));
        }
    }

    /**
     * @notice
     *  Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param _tokenId token identifier to be queried
     *
     * @return _tokenURI the token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory _tokenURI) {
        if (!_exists(_tokenId)) revert ABErrors.INVALID_PARAMETER();

        string memory baseURI = _baseURI();

        if (bytes(baseURI).length == 0) {
            _tokenURI = "";
        } else {
            bytes memory lastByte = new bytes(1);

            lastByte[0] = bytes(baseURI)[bytes(baseURI).length - 1];
            string memory lastChar = string(lastByte);

            if (keccak256(abi.encodePacked(lastChar)) == keccak256(abi.encodePacked("/"))) {
                _tokenURI = string(abi.encodePacked(baseURI, _toString(_tokenId)));
            } else {
                _tokenURI = baseURI;
            }
        }
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the base URI
     *
     * @return _uri token URI state
     */
    function _baseURI() internal view virtual override returns (string memory _uri) {
        _uri = baseTokenURI;
    }

    /**
     * @notice
     *  Returns the starting token ID
     *
     * @return _firstTokenId start token index
     */
    function _startTokenId() internal view virtual override returns (uint256 _firstTokenId) {
        _firstTokenId = 1;
    }

    function _beforeTokenTransfers(address _from, address _to, uint256, /* _startTokenId */ uint256 _quantity)
        internal
        override(ERC721AUpgradeable)
    {
        if (sharePerToken > 0) {
            abDataRegistry.on721TokenTransfer(publisher, _from, _to, dropId, _quantity);
        }
    }
}
