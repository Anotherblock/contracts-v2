// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* ERC721A Contract */
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

/* Openzeppelin Contract */
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/* Custom Interfaces */
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";

contract ERC721AB is ERC721AUpgradeable, OwnableUpgradeable {
    /**
     * @notice
     *  Phase Structure format
     *
     * @param phaseStart : timestamp at which the phase starts
     * @param price : price for one token during the phase
     * @param maxMint : maximum number of token to be minted per user during the phase
     * @param merkle : merkle tree root containing user address and associated parameters
     */
    struct Phase {
        uint256 phaseStart;
        uint256 phaseEnd;
        uint256 price;
        uint256 maxMint;
        bytes32 merkle;
    }

    error DropSoldOut();
    error NotEnoughTokensAvailable();
    error IncorrectETHSent();
    error NoSaleInProgress();
    error MaxMintPerAddress();
    error NotEligible();
    error InvalidParameter();
    error PhasesNotSet();

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
        // Get the active sale phase (revert if no active phase)
        uint256 phaseId = _getActivePhaseId();
        Phase memory phase = phases[phaseId];

        // Get the current minted supply
        uint256 currentSupply = _totalMinted();

        // Check that the drop is not sold out
        if (currentSupply == maxSupply) revert DropSoldOut();

        // Check that there are enough tokens available for sale
        if (currentSupply + _quantity > maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][phaseId] + _quantity > phase.maxMint) revert MaxMintPerAddress();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert IncorrectETHSent();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][phaseId] += _quantity;

        // Mint `_quantity` amount to `_to`
        _mint(_to, _quantity);
    }

    function mintMerkle(address _to, uint256 _quantity, bytes32[] memory _proof) external payable {
        // Get the active sale phase (revert if no active phase)
        uint256 phaseId = _getActivePhaseId();
        Phase memory phase = phases[phaseId];

        // Get the current minted supply
        uint256 currentSupply = _totalMinted();

        // Check that the drop is not sold out
        if (currentSupply == maxSupply) revert DropSoldOut();

        // Check that there are enough tokens available for sale
        if (currentSupply + _quantity > maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        // Check that `_to` is in the merkle tree (if applicable)
        if (phase.merkle != 0x0) {
            bool isWhitelisted = MerkleProof.verify(_proof, phase.merkle, keccak256(abi.encodePacked(_to)));
            if (!isWhitelisted) {
                revert NotEligible();
            }
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][phaseId] + _quantity > phase.maxMint) revert MaxMintPerAddress();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) revert IncorrectETHSent();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][phaseId] += _quantity;

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

        uint256 length = _phases.length;

        for (uint256 i = 0; i < length; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order and consistence between phase start & phase end)
            if (phase.phaseStart > phase.phaseEnd || phase.phaseStart <= previousPhaseStart) {
                revert InvalidParameter();
            }
            phases.push(phase);
            previousPhaseStart = phase.phaseStart;
        }

        // emit UpdatedPhase(dropId);
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _getActivePhaseId() internal view returns (uint256) {
        uint256 length = phases.length;

        if (length == 0) revert PhasesNotSet();

        if (phases[0].phaseStart < block.timestamp) revert NoSaleInProgress();

        for (uint256 i = 0; i < length; ++i) {
            if (phases[i].phaseStart >= block.timestamp && phases[i].phaseEnd < block.timestamp) return i;
        }
        revert NoSaleInProgress();
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

    function _beforeTokenTransfers(address _from, address _to, uint256 _startTokenId, uint256 _quantity)
        internal
        override(ERC721AUpgradeable)
    {
        if (_hasPayout()) payoutContract.updatePayout721(_from, _to, _quantity);
    }
}
