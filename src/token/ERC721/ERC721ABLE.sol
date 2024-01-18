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
 * @title ERC721ABLE
 * @author anotherblock Technical Team
 * @notice anotherblock ERC721 contract used for regular mint mechanism & limited edition
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/* anotherblock Contract */
import {ERC721AB} from "src/token/ERC721/ERC721AB.sol";

/* anotherblock Libraries */
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";
import {ABErrors} from "src/libraries/ABErrors.sol";

contract ERC721ABLE is ERC721AB {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Supply cap for this collection
    uint256 public maxSupply;

    /// @dev Implementation Type
    bytes32 public constant IMPLEMENTATION_TYPE = keccak256("LIMITED_EDITION");

    /// @dev ERC721AB implementation version
    uint8 public constant IMPLEMENTATION_VERSION = 1;

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Mint `_quantity` tokens to `_to` address based on the current `_phaseId` if `_signature` & `_kycSignature` are valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _phaseId current minting phase (must be started)
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     * @param _kycSignature signature to verify user's KYC status
     */
    function mintWithETH(
        address _to,
        uint256 _phaseId,
        uint256 _quantity,
        bytes calldata _signature,
        bytes calldata _kycSignature
    ) external payable {
        // Perform before mint checks (KYC verification)
        _beforeMint(_to, _kycSignature);

        // Check that the requested minting phase has started
        if (!_isPhaseActive(_phaseId)) revert ABErrors.PHASE_NOT_ACTIVE();

        // Get requested phase details
        ABDataTypes.Phase memory phase = phases[_phaseId];

        // Check that there are enough tokens available for sale
        if (_totalMinted() + _quantity > maxSupply) {
            revert ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check if the current phase is private
        if (!phase.isPublic) {
            // Check that the user is included in the allowlist
            if (!abVerifier.verifySignature721(_to, address(this), _phaseId, _signature)) {
                revert ABErrors.NOT_ELIGIBLE();
            }
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_phaseId] + _quantity > phase.maxMint) revert ABErrors.MAX_MINT_PER_ADDRESS();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != phase.priceETH * _quantity) revert ABErrors.INCORRECT_ETH_SENT();

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_phaseId] += _quantity;

        // Mint `_quantity` amount to `_to` address
        _mint(_to, _quantity);
    }

    /**
     * @notice
     *  Mint `_quantity` tokens to `_to` address based on the current `_phaseId` if `_signature` & `_kycSignature` are valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _phaseId current minting phase (must be started)
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     * @param _kycSignature signature to verify user's KYC status
     */
    function mintWithERC20(
        address _to,
        uint256 _phaseId,
        uint256 _quantity,
        bytes calldata _signature,
        bytes calldata _kycSignature
    ) external {
        _mintWithERC20(_to, _phaseId, _quantity, _signature, _kycSignature);
    }

    /**
     * @notice
     *  Mint `_quantity` tokens to `_to` address based on the current `_phaseId` if `_signature` & `_kycSignature` are valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _phaseId current minting phase (must be started)
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     * @param _deadline timestamp at which the permit signature expires
     * @param _sigV V component of the permit signature
     * @param _sigR R component of the permit signature
     * @param _sigS S component of the permit signature
     * @param _kycSignature signature to verify user's KYC status
     */
    function mintWithERC20Permit(
        address _to,
        uint256 _phaseId,
        uint256 _quantity,
        uint256 _deadline,
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes calldata _signature,
        bytes calldata _kycSignature
    ) external {
        // Approve token spending using user's permit signature
        IERC20Permit(address(acceptedCurrency)).permit(
            msg.sender, address(this), phases[_phaseId].priceERC20 * _quantity, _deadline, _sigV, _sigR, _sigS
        );

        _mintWithERC20(_to, _phaseId, _quantity, _signature, _kycSignature);
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
     * @param _acceptedCurrency accepted currency contract address used to buy tokens
     * @param _baseUri base URI for this drop
     */
    function initDrop(
        uint256 _maxSupply,
        uint256 _sharePerToken,
        uint256 _mintGenesis,
        address _genesisRecipient,
        address _royaltyCurrency,
        address _acceptedCurrency,
        string calldata _baseUri
    ) external onlyOwner {
        // Set supply cap
        maxSupply = _maxSupply;
        if (_mintGenesis > _maxSupply) revert ABErrors.INVALID_PARAMETER();

        _initDrop(_sharePerToken, _mintGenesis, _genesisRecipient, _royaltyCurrency, _acceptedCurrency, _baseUri);
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

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Mint `_quantity` tokens to `_to` address based on the current `_phaseId` if `_signature` & `_kycSignature` are valid
     *
     * @param _to token recipient address (must be whitelisted)
     * @param _phaseId current minting phase (must be started)
     * @param _quantity quantity of tokens requested (must be less than max mint per phase)
     * @param _signature signature to verify allowlist status
     * @param _kycSignature signature to verify user's KYC status
     */
    function _mintWithERC20(
        address _to,
        uint256 _phaseId,
        uint256 _quantity,
        bytes calldata _signature,
        bytes calldata _kycSignature
    ) internal {
        // Perform before mint checks (KYC verification)
        _beforeMint(_to, _kycSignature);

        // Check that the contract accepts ERC20 payment
        if (address(acceptedCurrency) == address(0)) revert ABErrors.MINT_WITH_ERC20_NOT_AVAILABLE();

        // Check that the requested minting phase has started
        if (!_isPhaseActive(_phaseId)) revert ABErrors.PHASE_NOT_ACTIVE();

        // Get requested phase details
        ABDataTypes.Phase memory phase = phases[_phaseId];

        // Check that there are enough tokens available for sale
        if (_totalMinted() + _quantity > maxSupply) {
            revert ABErrors.NOT_ENOUGH_TOKEN_AVAILABLE();
        }

        // Check if the current phase is private
        if (!phase.isPublic) {
            // Check that the user is included in the allowlist
            if (!abVerifier.verifySignature721(_to, address(this), _phaseId, _signature)) {
                revert ABErrors.NOT_ELIGIBLE();
            }
        }

        // Check that user did not mint / is not asking to mint more than the max mint per address for the current phase
        if (mintedPerPhase[_to][_phaseId] + _quantity > phase.maxMint) revert ABErrors.MAX_MINT_PER_ADDRESS();

        // Transfer the ERC20 from the buyer to this contract
        if (!acceptedCurrency.transferFrom(msg.sender, address(this), phase.priceERC20 * _quantity)) {
            revert ABErrors.ERROR_PROCEEDING_PAYMENT();
        }

        // Set quantity minted for `_to` during the current phase
        mintedPerPhase[_to][_phaseId] += _quantity;

        // Mint `_quantity` amount to `_to` address
        _mint(_to, _quantity);
    }
}
