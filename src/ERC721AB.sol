// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* ERC721A Contract */
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* Custom Interfaces */
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";
import {IABVerifier} from "./interfaces/IABVerifier.sol";

contract ERC721AB is ERC721AUpgradeable, OwnableUpgradeable {
    /**
     * @notice
     *  Phase Structure format
     *
     * @param phaseStart : timestamp at which the phase starts
     * @param price : price for one token during the phase
     * @param maxMint : maximum number of token to be minted per user during the phase
     */
    struct Phase {
        uint256 phaseStart;
        uint256 price;
        uint256 maxMint;
    }

    /// @dev Error returned if the drop is sold out
    error DropSoldOut();

    /// @dev Error returned if supply is insufficient
    error NotEnoughTokensAvailable();

    /// @dev Error returned if user did not send the correct amount of ETH
    error IncorrectETHSent();

    /// @dev Error returned if the requested phase is not active
    error PhaseNotActive();

    /// @dev Error returned if user attempt to mint more than allowed
    error MaxMintPerAddress();

    /// @dev Error returned if user is not eligible to mint during the current phase
    error NotEligible();

    /// @dev Error returned when the passed parameter is incorrect
    error InvalidParameter();

    /// @dev Error returned if user attempt to mint while the phases are not set
    error PhasesNotSet();

    /// @dev Event emitted upon phase update
    event UpdatedPhase(uint256 numOfPhase);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    IABVerifier public abVerifier;
    IABRoyalty public payoutContract;
    uint256 public maxSupply;
    uint256 public price;

    /// @dev Base Token URI
    string private baseTokenURI;

    ///@dev Dynamic array of phases
    Phase[] public phases;

    ///@dev Mapping storing the amount minted per wallet and per phase
    mapping(address user => mapping(uint256 phaseId => uint256 minted)) public mintedPerPhase;

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

    function initialize(
        address _payoutContract,
        address _genesisRecipient,
        address _abVerifier,
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

        abVerifier = IABVerifier(_abVerifier);

        // Mint Genesis (?)
        if (_mintGenesis > 0) _mint(_genesisRecipient, _mintGenesis);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function mint(address _to, uint256 _phaseId, uint256 _quantity, bytes calldata _signature) external payable {
        if (phases.length == 0) revert PhasesNotSet();

        if (!_isPhaseActive(_phaseId)) revert PhaseNotActive();

        Phase memory phase = phases[_phaseId];

        uint256 dropId = 0;

        // Get the current minted supply
        uint256 currentSupply = _totalMinted();

        // Check that the drop is not sold out
        if (currentSupply == maxSupply) revert DropSoldOut();

        // Check that there are enough tokens available for sale
        if (currentSupply + _quantity > maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        if (!abVerifier.verifySignature(_to, dropId, _phaseId, _signature)) {
            revert NotEligible();
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_phaseId] + _quantity > phase.maxMint) revert MaxMintPerAddress();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert IncorrectETHSent();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_phaseId] += _quantity;

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

    /**
     * @notice
     *  Set the sale phases for drop
     *
     * @param _phases : array of phases to be set
     */
    function setDropPhases(Phase[] memory _phases) external onlyOwner {
        // Delete previously set phases (if any)
        if (phases.length > 0) {
            delete phases;
        }

        uint256 previousPhaseStart = 0;

        uint256 numOfPhase = _phases.length;

        for (uint256 i = 0; i < numOfPhase; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order)
            if (phase.phaseStart <= previousPhaseStart) {
                revert InvalidParameter();
            }
            phases.push(phase);
            previousPhaseStart = phase.phaseStart;
        }

        emit UpdatedPhase(numOfPhase);
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns true if the passed phase ID is active
     *
     * @return : true if phase is active, false otherwise
     */
    function _isPhaseActive(uint256 _phaseId) internal view returns (bool) {
        if (_phaseId >= phases.length) revert InvalidParameter();
        if (phases[_phaseId].phaseStart <= block.timestamp) return true;
        return false;
    }

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

    function _beforeTokenTransfers(address _from, address _to, uint256, /* _startTokenId */ uint256 _quantity)
        internal
        override(ERC721AUpgradeable)
    {
        if (_hasPayout()) payoutContract.updatePayout721(_from, _to, _quantity);
    }
}
