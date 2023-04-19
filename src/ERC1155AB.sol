// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* Custom Interfaces */
import {IABVerifier} from "./interfaces/IABVerifier.sol";
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";

contract ERC1155AB is ERC1155Upgradeable, OwnableUpgradeable {
    /**
     * @notice
     *  TokenDetails Structure format
     *
     * @param mintedSupply : amount of tokens minted
     * @param maxSupply : maximum supply
     * @param numOfPhase : number of phases
     * @param phases : mint phases (see phase structure format)
     * @param uri : token URI
     */
    struct TokenDetails {
        uint256 mintedSupply;
        uint256 maxSupply;
        uint256 numOfPhase;
        mapping(uint256 phaseId => Phase phase) phases;
        string uri;
    }
    // uint256 dropId; (?)

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

    IABRoyalty public royaltyContract;

    uint256 public tokenCount;

    mapping(uint256 tokenId => TokenDetails tokenDetails) public tokensDetails;

    ///@dev Mapping storing the amount minted per wallet and per phase
    mapping(address user => mapping(uint256 tokenId => mapping(uint256 phaseId => uint256 minted))) public
        mintedPerPhase;

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

    function initialize(address _royaltyContract, address _abVerifier) external initializer {
        __ERC1155_init("");
        __Ownable_init();

        tokenCount = 0;
        abVerifier = IABVerifier(_abVerifier);
        royaltyContract = IABRoyalty(_royaltyContract);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function mint(address _to, uint256 _tokenId, uint256 _phaseId, uint256 _quantity, bytes calldata _signature)
        external
        payable
    {
        // temporary hardcode dropId
        uint256 dropId = 0;
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        if (tokenDetails.numOfPhase == 0) revert PhasesNotSet();

        if (!_isPhaseActive(_tokenId, _phaseId)) revert PhaseNotActive();

        Phase memory phase = tokenDetails.phases[_phaseId];

        // Check if the drop is not sold-out
        if (tokenDetails.mintedSupply == tokenDetails.maxSupply) {
            revert DropSoldOut();
        }

        // Check that there are enough tokens available for sale
        if (tokenDetails.mintedSupply + _quantity > tokenDetails.maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        if (!abVerifier.verifySignature1155(_to, dropId, _tokenId, _phaseId, _signature)) {
            revert NotEligible();
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_tokenId][_phaseId] + _quantity > phase.maxMint) revert MaxMintPerAddress();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) {
            revert IncorrectETHSent();
        }

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_tokenId][_phaseId] += _quantity;

        tokenDetails.mintedSupply += _quantity;

        _mint(_to, _tokenId, _quantity, "");
    }

    function mintBatch(address _to, uint256[] memory _tokenIds, uint256[] memory _quantities) external payable {
        _mintBatch(_to, _tokenIds, _quantities, "");
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    function initDrop(uint256 _maxSupply, uint256 _mintGenesis, string memory _uri) external onlyOwner {
        TokenDetails storage newTokenDetails = tokensDetails[tokenCount];

        newTokenDetails.maxSupply = _maxSupply;
        newTokenDetails.uri = _uri;
        // tokensDetails[tokenCount] = TokenDetails({mintedSupply: 0, maxSupply: _maxSupply, numOfPhase: 0, uri: _uri});

        if (_hasPayout()) {
            // Initialize payout index
            royaltyContract.initPayoutIndex(uint32(tokenCount));
        }

        // Mint Genesis tokens to the drop owner
        if (_mintGenesis > 0) {
            if (_mintGenesis > _maxSupply) revert InvalidParameter();
            tokensDetails[tokenCount].mintedSupply += _mintGenesis;
            _mint(msg.sender, tokenCount, _mintGenesis, "");
        }

        // Increment tokenDetails count
        tokenCount++;
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *
     * @param _tokenId : token ID for which the phases are set
     * @param _phases : array of phases to be set
     */
    function setDropPhases(uint256 _tokenId, Phase[] memory _phases) external onlyOwner {
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        uint256 previousPhaseStart = 0;

        uint256 length = _phases.length;
        for (uint256 i = 0; i < length; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order and consistence between phase start & phase end)
            if (phase.phaseStart <= previousPhaseStart) {
                revert InvalidParameter();
            }
            tokenDetails.phases[i] = phase;
            previousPhaseStart = phase.phaseStart;
        }

        tokenDetails.numOfPhase = _phases.length;

        emit UpdatedPhase(length);
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
        tokensDetails[_tokenId].uri = _uri;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return (tokensDetails[_tokenId].uri);
    }

    function getPhaseInfo(uint256 _tokenId, uint256 _phaseId) public view returns (Phase memory) {
        return tokensDetails[_tokenId].phases[_phaseId];
    }
    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns true if the passed phase ID is active for the given token ID
     *
     * @return : true if phase is active, false otherwise
     */
    function _isPhaseActive(uint256 _tokenId, uint256 _phaseId) internal view returns (bool) {
        if (tokensDetails[_tokenId].phases[_phaseId].phaseStart <= block.timestamp) return true;
        return false;
    }

    function _hasPayout() internal view returns (bool) {
        return address(royaltyContract) != address(0);
    }

    function _beforeTokenTransfer(
        address, /* _operator */
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) internal override(ERC1155Upgradeable) {
        if (_hasPayout()) {
            royaltyContract.updatePayout1155(_from, _to, _tokenIds, _amounts);
        }
    }
}
