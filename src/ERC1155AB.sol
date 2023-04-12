// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* Custom Interfaces */
import {IABRoyalty} from "./interfaces/IABRoyalty.sol";

contract ERC1155AB is ERC1155Upgradeable, OwnableUpgradeable {
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
     * @param phaseStart : timestamp at which the phase ends
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
    error SaleNotStarted();

    event UpdatedPhase(uint256 numOfPhase);

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    IABRoyalty public royaltyContract;

    uint256 public tokenCount;

    mapping(uint256 tokenId => TokenDetails tokenDetails) public tokensDetails;

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

    function initialize(address _royaltyContract) external initializer {
        __ERC1155_init("");
        __Ownable_init();

        tokenCount = 0;
        royaltyContract = IABRoyalty(_royaltyContract);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function mint(address _to, uint256 _tokenId, uint256 _quantity) external payable {
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        uint256 phaseId = _getActivePhaseId(_tokenId);

        Phase memory phase = tokenDetails.phases[phaseId];

        // Check if the drop is not sold-out
        if (tokenDetails.mintedSupply == tokenDetails.maxSupply) {
            revert DropSoldOut();
        }

        // Check that there are enough tokens available for sale
        if (tokenDetails.mintedSupply + _quantity > tokenDetails.maxSupply) {
            revert NotEnoughTokensAvailable();
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.price * _quantity) {
            revert IncorrectETHSent();
        }

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

        tokenDetails.numOfPhase = _phases.length;

        uint256 previousPhaseStart = 0;

        uint256 length = _phases.length;

        for (uint256 i = 0; i < length; ++i) {
            Phase memory phase = _phases[i];

            // Check parameter correctness (phase order and consistence between phase start & phase end)
            if (phase.phaseStart > phase.phaseEnd || phase.phaseStart <= previousPhaseStart) {
                revert InvalidParameter();
            }
            tokenDetails.phases[i] = phase;
            previousPhaseStart = phase.phaseStart;
        }

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
     *  Returns currently active phase ID
     *
     * @param _tokenId : token ID for which the phases are corresponding to
     *
     * @return : active phase ID
     */
    function _getActivePhaseId(uint256 _tokenId) internal view returns (uint256) {
        TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        if (tokenDetails.numOfPhase == 0) revert PhasesNotSet();

        if (tokenDetails.phases[0].phaseStart > block.timestamp) revert SaleNotStarted();

        for (uint256 i = 0; i < tokenDetails.numOfPhase; ++i) {
            if (
                tokenDetails.phases[i].phaseStart <= block.timestamp
                    && tokenDetails.phases[i].phaseEnd > block.timestamp
            ) return i;
        }
        revert NoSaleInProgress();
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
