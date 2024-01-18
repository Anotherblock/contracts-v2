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
 * @title ERC1155AB
 * @author anotherblock Technical Team
 * @notice anotherblock ERC1155 contract standard
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* anotherblock Libraries */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";

/* anotherblock Interfaces */
import {IABVerifier} from "src/utils/IABVerifier.sol";
import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";

contract ERC1155AB is ERC1155Upgradeable, OwnableUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev anotherblock Drop Registry contract interface (see IABDataRegistry.sol)
    IABDataRegistry public abDataRegistry;

    /// @dev anotherblock Verifier contract interface (see IABVerifier.sol)
    IABVerifier public abVerifier;

    /// @dev Publisher address
    address public publisher;

    /// @dev Next Token ID available in this collection
    uint256 public nextTokenId;

    /// @dev Mapping storing the Token Details for a given Token ID
    mapping(uint256 tokenId => ABDataTypes.TokenDetails tokenDetails) public tokensDetails;

    ///@dev Mapping storing the amount of token(s) minted per wallet and per phase
    mapping(address user => mapping(uint256 tokenId => mapping(uint256 phaseId => uint256 minted))) public
        mintedPerPhase;

    ///@dev ERC1155AB implementation version
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

    /**
     * @notice
     *  Contract Initializer (Minimal Proxy Contract)
     *
     * @param _abDataRegistry address of ABDropRegistry contract
     * @param _abVerifier address of ABVerifier contract
     */
    function initialize(address _publisher, address _abDataRegistry, address _abVerifier) external initializer {
        // Initialize ERC1155
        __ERC1155_init("");

        // Initialize Ownable
        __Ownable_init();
        _transferOwnership(_publisher);

        // Initialize `nextTokenId`
        nextTokenId = 1;

        // Assign ABDataRegistry address
        abDataRegistry = IABDataRegistry(_abDataRegistry);

        // Assign ABVerifier address
        abVerifier = IABVerifier(_abVerifier);

        // Assign the publisher address
        publisher = _publisher;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Mint `_quantity` tokens of `_tokenId` to `_to` address based on the current `_phaseId` if `_signature` is valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _mintParams mint parameters (see MintParams structure)
     */
    function mint(address _to, ABDataTypes.MintParams calldata _mintParams) external payable {
        // Get the Token Details for the requested tokenID
        ABDataTypes.TokenDetails storage tokenDetails = tokensDetails[_mintParams.tokenId];

        // Check that the phases are defined
        if (tokenDetails.numOfPhase == 0) revert ABErrors.PHASES_NOT_SET();

        // Get the requested phase details
        ABDataTypes.Phase memory phase = tokenDetails.phases[_mintParams.phaseId];

        // Check that the requested minting phase has started
        if (!_isPhaseActive(phase)) revert ABErrors.PHASE_NOT_ACTIVE();

        // Check that there are enough tokens available for sale
        if (tokenDetails.mintedSupply + _mintParams.quantity > tokenDetails.maxSupply) {
            revert ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check if the current phase is private
        if (!phase.isPublic) {
            // Check that the user is included in the allowlist
            if (
                !abVerifier.verifySignature1155(
                    _to, address(this), _mintParams.tokenId, _mintParams.phaseId, _mintParams.signature
                )
            ) {
                revert ABErrors.NOT_ELIGIBLE();
            }
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_mintParams.tokenId][_mintParams.phaseId] + _mintParams.quantity > phase.maxMint) {
            revert ABErrors.MAX_MINT_PER_ADDRESS();
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.priceETH * _mintParams.quantity) {
            revert ABErrors.INCORRECT_ETH_SENT();
        }

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_mintParams.tokenId][_mintParams.phaseId] += _mintParams.quantity;

        // Update the minted supply for this token
        tokenDetails.mintedSupply += _mintParams.quantity;

        // Mint `_quantity` amount of `_tokenId` to `_to` address
        _mint(_to, _mintParams.tokenId, _mintParams.quantity, "");
    }

    /**
     * @notice
     *  Mint tokens in batch to `_to` address
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _mintParams mint parameters array (see MintParams structure)
     */
    function mintBatch(address _to, ABDataTypes.MintParams[] calldata _mintParams) external payable {
        uint256 length = _mintParams.length;

        uint256[] memory tokenIds = new uint256[](length);
        uint256[] memory quantities = new uint256[](length);

        uint256 totalCost = 0;

        ABDataTypes.TokenDetails storage tokenDetails;

        for (uint256 i = 0; i < length; ++i) {
            // Get the Token Details for the requested tokenID
            tokenDetails = tokensDetails[_mintParams[i].tokenId];

            // Check that the phases are defined
            if (tokenDetails.numOfPhase == 0) revert ABErrors.PHASES_NOT_SET();

            // Get the requested phase details
            ABDataTypes.Phase memory phase = tokenDetails.phases[_mintParams[i].phaseId];

            // Check that the requested minting phase has started
            if (!_isPhaseActive(phase)) revert ABErrors.PHASE_NOT_ACTIVE();

            // Check that there are enough tokens available for sale
            if (tokenDetails.mintedSupply + _mintParams[i].quantity > tokenDetails.maxSupply) {
                revert ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE();
            }

            // Check if the current phase is private
            if (!phase.isPublic) {
                // Check that the user is included in the allowlist
                if (
                    !abVerifier.verifySignature1155(
                        _to, address(this), _mintParams[i].tokenId, _mintParams[i].phaseId, _mintParams[i].signature
                    )
                ) {
                    revert ABErrors.NOT_ELIGIBLE();
                }
            }
            // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
            if (
                mintedPerPhase[_to][_mintParams[i].tokenId][_mintParams[i].phaseId] + _mintParams[i].quantity
                    > phase.maxMint
            ) {
                revert ABErrors.MAX_MINT_PER_ADDRESS();
            }

            // Set quantity minted for `_to` during the current phase
            mintedPerPhase[_to][_mintParams[i].tokenId][_mintParams[i].phaseId] += _mintParams[i].quantity;

            // Update the minted supply for this token
            tokenDetails.mintedSupply += _mintParams[i].quantity;

            // Increment total cost
            totalCost += phase.priceETH * _mintParams[i].quantity;

            // Populate arrays used to mint ERC1155 in batch
            tokenIds[i] = _mintParams[i].tokenId;
            quantities[i] = _mintParams[i].quantity;
        }

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != totalCost) {
            revert ABErrors.INCORRECT_ETH_SENT();
        }
        _mintBatch(_to, tokenIds, quantities, "");
    }

    //     ____        __         ___       __          _
    //    / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //   / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //  / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //  \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //               /____/

    /**
     * @notice
     *  Initialize the drop parameters
     *  Only the contract owner can perform this operation
     *
     * @param _initDropParams drop initialisation parameters (see InitDropParams structure)
     */
    function initDrop(ABDataTypes.InitDropParams calldata _initDropParams) external onlyOwner {
        _initDrop(_initDropParams);
    }

    /**
     * @notice
     *  Initialize multiple drops parameters
     *  Only the contract owner can perform this operation
     *
     * @param _initDropParams drop initialisation parameters array (see InitDropParams structure)
     */
    function initDrop(ABDataTypes.InitDropParams[] calldata _initDropParams) external onlyOwner {
        uint256 length = _initDropParams.length;

        for (uint256 i = 0; i < length; ++i) {
            _initDrop(_initDropParams[i]);
        }
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId : token ID for which the phases are set
     * @param _phases : array of phases to be set
     */
    function setDropPhases(uint256 _tokenId, ABDataTypes.Phase[] calldata _phases) external onlyOwner {
        // Get the requested token details
        ABDataTypes.TokenDetails storage tokenDetails = tokensDetails[_tokenId];

        uint256 previousPhaseStart = 0;

        uint256 length = _phases.length;
        for (uint256 i = 0; i < length; ++i) {
            ABDataTypes.Phase memory phase = _phases[i];

            // Check parameter correctness (phase order consistence)
            if (phase.phaseStart < previousPhaseStart || phase.phaseStart > phase.phaseEnd) {
                revert ABErrors.INVALID_PARAMETER();
            }

            // Set the phase
            tokenDetails.phases[i] = phase;
            previousPhaseStart = phase.phaseStart;
        }

        // Set the number of phase
        tokenDetails.numOfPhase = _phases.length;

        emit ABEvents.UpdatedPhase(_tokenId);
    }

    /**
     * @notice
     *  Withdraw the mint proceeds
     *  Only the contract owner can perform this operation
     *
     */
    function withdrawToRightholder() external onlyOwner {
        (address abTreasury, uint256 fee) = abDataRegistry.getPayoutDetails(publisher, 0);

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
     *  Update the token URI
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId token ID to be updated
     * @param _uri new token URI to be set
     */

    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
        tokensDetails[_tokenId].uri = _uri;
    }

    /**
     * @notice
     *  Set the maximum supply for the given `_tokenId`
     *  Only the contract owner can perform this operation
     *
     * @param _tokenId token ID to be updated
     * @param _maxSupply new maximum supply to be set
     */
    function setMaxSupply(uint256 _tokenId, uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < tokensDetails[_tokenId].mintedSupply) revert ABErrors.INVALID_PARAMETER();
        tokensDetails[_tokenId].maxSupply = _maxSupply;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the token URI
     *
     * @param _tokenId requested token ID
     *
     * @return _tokenURI token URI
     */
    function uri(uint256 _tokenId) public view override returns (string memory _tokenURI) {
        _tokenURI = tokensDetails[_tokenId].uri;
    }

    /**
     * @notice
     *  Returns `_phaseId` phase details for `_tokenId`
     *
     * @param _tokenId requested token ID
     * @param _phaseId requested phase ID
     *
     * @return _phase phase details
     */
    function getPhaseInfo(uint256 _tokenId, uint256 _phaseId) public view returns (ABDataTypes.Phase memory _phase) {
        _phase = tokensDetails[_tokenId].phases[_phaseId];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return ERC1155Upgradeable.supportsInterface(interfaceId);
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Initialize the Drop parameters
     *
     * @param _initDropParams drop initialisation parameters (see InitDropParams structure)
     */
    function _initDrop(ABDataTypes.InitDropParams calldata _initDropParams) internal {
        // Check that share per token & royalty currency are consistent
        if (
            (_initDropParams.sharePerToken == 0 && _initDropParams.royaltyCurrency != address(0))
                || (_initDropParams.royaltyCurrency == address(0) && _initDropParams.sharePerToken != 0)
        ) revert ABErrors.INVALID_PARAMETER();

        ABDataTypes.TokenDetails storage newTokenDetails = tokensDetails[nextTokenId];

        // Register the drop and get an unique drop identifier
        uint256 dropId = abDataRegistry.registerDrop(publisher, _initDropParams.royaltyCurrency, nextTokenId);

        // Set the drop identifier
        newTokenDetails.dropId = dropId;

        // Set supply cap
        newTokenDetails.maxSupply = _initDropParams.maxSupply;

        // Set share per token
        newTokenDetails.sharePerToken = _initDropParams.sharePerToken;

        // Set Token URI
        newTokenDetails.uri = _initDropParams.uri;

        // Mint Genesis tokens to `_genesisRecipient` address
        if (_initDropParams.mintGenesis > 0) {
            // Check that the requested amount of genesis token does not exceed the supply cap
            if (_initDropParams.mintGenesis > _initDropParams.maxSupply) revert ABErrors.INVALID_PARAMETER();

            // Increment the amount of token minted
            newTokenDetails.mintedSupply = _initDropParams.mintGenesis;

            // Mint the genesis token(s) to the genesis recipient
            _mint(_initDropParams.genesisRecipient, nextTokenId, _initDropParams.mintGenesis, "");
        }

        // Increment nextTokenId
        nextTokenId++;
    }

    /**
     * @notice
     *  Returns true if the passed phase ID is active
     *
     * @param _phase phase to be analyzed
     *
     * @return _isActive true if phase is active, false otherwise
     */
    function _isPhaseActive(ABDataTypes.Phase memory _phase) internal view returns (bool _isActive) {
        // Check that the requested phase ID exists
        if (_phase.phaseStart == 0) revert ABErrors.INVALID_PARAMETER();

        // Check if the requested phase has started
        _isActive = _phase.phaseStart <= block.timestamp && _phase.phaseEnd > block.timestamp;
    }

    function _beforeTokenTransfer(
        address, /* _operator */
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory /* _data */
    ) internal override(ERC1155Upgradeable) {
        uint256 royaltyCount = 0;
        uint256 length = _tokenIds.length;

        // Count the number of tokens paying out royalties
        for (uint256 i = 0; i < length; ++i) {
            if (tokensDetails[_tokenIds[i]].sharePerToken > 0) ++royaltyCount;
        }

        // Initialize arrays of dropIds and amounts
        uint256[] memory dropIds = new uint256[](royaltyCount);
        uint256[] memory amounts = new uint256[](royaltyCount);

        uint256 j = 0;

        // Convert each token ID into its associated drop ID if the drop pays royalty
        for (uint256 i = 0; i < length; ++i) {
            if (tokensDetails[_tokenIds[i]].sharePerToken > 0) {
                dropIds[j] = tokensDetails[_tokenIds[i]].dropId;
                amounts[j] = _amounts[i];
                ++j;
            }
        }
        abDataRegistry.on1155TokenTransfer(publisher, _from, _to, dropIds, amounts);
    }
}
