// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* ERC721A Contract */
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* Custom Interfaces */
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";

contract ERC721AB is ERC721AUpgradeable, OwnableUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    IABRoyalty public payoutContract;
    uint256 public maxSupply;
    uint256 public price;

    /// @dev Base Token URI
    string private baseTokenURI;

    uint8 public constant IMPLEMENTATION_VERSION = 1;

    error DropSoldOut();
    error NotEnoughTokensAvailable();
    error IncorrectETHSent();

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

    function initialize(
        address _payoutContract,
        address _genesisRecipient,
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _mintGenesis
    ) external initializerERC721A initializer {
        // Initialize ERC721A
        __ERC721A_init(_name, _symbol);

        // Initialize Ownable
        __Ownable_init();

        if (_payoutContract != address(0)) {
            // Assign payout contract address
            payoutContract = IABRoyalty(_payoutContract);

            // Initialize payout index
            payoutContract.initPayoutIndex(0);
        }

        // Set unit price
        price = _price;

        // Set supply cap
        maxSupply = _maxSupply;

        // Set base URI
        baseTokenURI = _baseUri;

        // Mint Genesis (?)
        if (_mintGenesis > 0) _mint(_genesisRecipient, _mintGenesis);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function mint(address _to, uint256 _quantity) external payable {
        // Get the current minted supply
        uint256 currentSupply = _totalMinted();

        // Check if the drop is not sold-out
        if (currentSupply == maxSupply) revert DropSoldOut();

        // Check that there are enough tokens available for sale
        if (currentSupply + _quantity > maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != price * _quantity) revert IncorrectETHSent();

        // Mint `_quantity` amount to `_to`
        _mint(_to, _quantity);
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Update the Base URI
     *  Only the contract owner can perform this operation
     *
     * @param _newBaseURI : new base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
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
     * @return : base token URI state
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _hasPayout() internal view returns (bool) {
        return address(payoutContract) != address(0);
    }

    function _beforeTokenTransfers(address _from, address _to, uint256 _startTokenId, uint256 _quantity)
        internal
        override(ERC721AUpgradeable)
    {
        if (_hasPayout()) payoutContract.updatePayout721(_from, _to, _quantity);
    }
}
