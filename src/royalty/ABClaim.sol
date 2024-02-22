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
 * @title ABClaim
 * @author anotherblock Technical Team
 * @notice anotherblock contract responsible for paying out royalties
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* anotherblock Libraries */
import {ABErrors} from "src/libraries/ABErrors.sol";
import {ABEvents} from "src/libraries/ABEvents.sol";
import {ABDataTypes} from "src/libraries/ABDataTypes.sol";

/* anotherblock Interfaces */
import {IERC721AB} from "src/token/ERC721/IERC721AB.sol";
import {IABKYCModule} from "src/utils/IABKYCModule.sol";

contract ABClaim is Initializable, AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev USDC contract address
    IERC20 public USDC;

    /// @dev anotherblock KYC module contract address
    IABKYCModule public abKycModule;

    /// @dev total amount deposited per drop
    mapping(uint256 dropId => uint256 totalDeposited) public totalDepositedPerDrop;

    /// @dev drop data (see ABDataTypes.DropData structure)
    mapping(uint256 dropId => ABDataTypes.DropData dropData) public dropData;

    /// @dev total amount claimed for a given tokenID of a given drop
    mapping(uint256 dropId => mapping(uint256 tokenId => uint256 amount) claimedPerTokenId) public claimedAmount;

    /// @dev ownership mapping of a given tokenID of a L1 drop
    mapping(uint256 dropId => mapping(uint256 tokenId => address owner) ownerOf) public ownerOf;

    /// @dev access control relayer role
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructork
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice
     *  Contract Initializer
     *
     * @param _usdc USDC contract address
     * @param _abKycModule anotherblock KYC module contract address
     * @param _relayer OZ relayer address
     */
    function initialize(address _usdc, address _abKycModule, address _relayer) external initializer {
        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RELAYER_ROLE, _relayer);

        // Set ABKYCModule interface
        abKycModule = IABKYCModule(_abKycModule);

        // Set USDC interface
        USDC = IERC20(_usdc);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Let user claim royalties for their tokens for multiple drops
     *
     * @param _dropIds array of drops to claim for
     * @param _tokenIds 2-dim array of tokens to claim for
     * @param _signature signature used to verify KYC
     */
    function claim(uint256[] calldata _dropIds, uint256[][] calldata _tokenIds, bytes calldata _signature) external {
        _claimMultiDrop(_dropIds, _tokenIds, msg.sender, _signature);
    }

    /**
     * @notice
     *  Let user claim royalties for their tokens for a single drop
     *
     * @param _dropId drop to claim for
     * @param _tokenIds array of tokens to claim for
     * @param _signature signature used to verify KYC
     */
    function claim(uint256 _dropId, uint256[] calldata _tokenIds, bytes calldata _signature) external {
        _claimSingleDrop(_dropId, _tokenIds, msg.sender, _signature);
    }

    //      ____        __         ___       __          _
    //     / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //    / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //   / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //   \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //                /____/

    /**
     * @notice
     *  Claim royalties on behalf of a user for their tokens for multiple drops
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dropIds array of drops to claim for
     * @param _tokenIds 2-dim array of tokens to claim for
     * @param _user user address to claim for
     * @param _signature signature used to verify KYC
     */
    function claimOnBehalf(
        uint256[] calldata _dropIds,
        uint256[][] calldata _tokenIds,
        address _user,
        bytes calldata _signature
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimMultiDrop(_dropIds, _tokenIds, _user, _signature);
    }

    /**
     * @notice
     *  Claim royalties on behalf of a user for their tokens for a single drop
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dropId drop to claim for
     * @param _tokenIds array of tokens to claim for
     * @param _user user address to claim for
     * @param _signature signature used to verify KYC
     */
    function claimOnBehalf(uint256 _dropId, uint256[] calldata _tokenIds, address _user, bytes calldata _signature)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _claimSingleDrop(_dropId, _tokenIds, _user, _signature);
    }

    /**
     * @notice
     *  Deposit the royalties for a given drop
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dropId drop to deposit for
     * @param _amount quantity of royalty deposited
     */
    function depositRoyalty(uint256 _dropId, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Increment the total amount deposited for this drop
        totalDepositedPerDrop[_dropId] += _amount;

        // Transfer USDC from the sender to this contract
        USDC.transferFrom(msg.sender, address(this), _amount);

        // Emit Royalty Distributed event
        emit ABEvents.RoyaltyDistributed(_dropId, _amount);
    }

    /**
     * @notice
     *  Deposit the royalties for multiple drops
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dropIds array of drops to deposit for
     * @param _amounts array of quantities of royalty deposited
     */
    function depositRoyalty(uint256[] calldata _dropIds, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 totalAmount;
        uint256 dLength = _dropIds.length;

        // Check parameters validity
        if (dLength != _amounts.length) revert ABErrors.INVALID_PARAMETER();

        // Iterate over each drop
        for (uint256 i; i < dLength;) {
            // Increment the total amount deposited for this drop
            totalDepositedPerDrop[_dropIds[i]] += _amounts[i];

            // Increment the total amount deposited
            totalAmount += _amounts[i];

            unchecked {
                ++i;
            }
        }

        // Transfer USDC from the sender to this contract
        USDC.transferFrom(msg.sender, address(this), totalAmount);

        // Emit Royalty Distributed event
        emit ABEvents.RoyaltyDistributedMultiDrop(_dropIds, _amounts);
    }

    /**
     * @notice
     *  Update drop data
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dropId drop identifier to be updated
     * @param _nft address of the associated nft contract (address(0) if the contract is on L1)
     * @param _isL1 boolean stating if the drop is on L1
     * @param _supply drop supply
     */
    function setDropData(uint256 _dropId, address _nft, bool _isL1, uint256 _supply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Populate drop data mapping
        dropData[_dropId] = ABDataTypes.DropData(_nft, _isL1, _supply);

        // Emit DropDataUpdated event
        emit ABEvents.DropDataUpdated(_dropId, _nft, _isL1, _supply);
    }

    /**
     * @notice
     *  Update multiple drop data
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dropIds drops identifier to be updated
     * @param _nfts addresses of the associated nft contracts (address(0) if the contract is on L1)
     * @param _isL1 boolean stating if the drops are on L1
     * @param _supplies drops supplies
     */
    function setDropData(
        uint256[] calldata _dropIds,
        address[] calldata _nfts,
        bool[] calldata _isL1,
        uint256[] calldata _supplies
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 dLength = _dropIds.length;

        // Check parameters validity
        if (_nfts.length != dLength) revert ABErrors.INVALID_PARAMETER();
        if (_isL1.length != dLength) revert ABErrors.INVALID_PARAMETER();
        if (_supplies.length != dLength) revert ABErrors.INVALID_PARAMETER();

        // Iterate over each drop
        for (uint256 i; i < dLength;) {
            // Populate drop data mapping
            dropData[_dropIds[i]] = ABDataTypes.DropData(_nfts[i], _isL1[i], _supplies[i]);

            unchecked {
                ++i;
            }
        }
        emit ABEvents.DropDataBatchUpdated(_dropIds, _nfts, _isL1, _supplies);
    }
    //     ____        __         ____       __
    //    / __ \____  / /_  __   / __ \___  / /___ ___  _____  _____
    //   / / / / __ \/ / / / /  / /_/ / _ \/ / __ `/ / / / _ \/ ___/
    //  / /_/ / / / / / /_/ /  / _, _/  __/ / /_/ / /_/ /  __/ /
    //  \____/_/ /_/_/\__, /  /_/ |_|\___/_/\__,_/\__, /\___/_/
    //               /____/                      /____/

    /**
     * @notice
     *  Update L1 drop holdings
     *  Only the caller with role `RELAYER_ROLE` can perform this operation
     *
     * @param _dropId drop identifier
     * @param _tokenId tokenID to be updated
     * @param _newOwner new owner address to be updated
     */
    function updateL1Holdings(uint256 _dropId, uint256 _tokenId, address _newOwner) external onlyRole(RELAYER_ROLE) {
        // Update the ownership of the given token
        ownerOf[_dropId][_tokenId] = _newOwner;

        // Emit HoldingUpdated event
        emit ABEvents.HoldingsUpdated(_dropId, _tokenId, _newOwner);
    }

    /**
     * @notice
     *  Update L1 drop holdings in batch
     *  Only the caller with role `RELAYER_ROLE` can perform this operation
     *
     * @param _dropId drop identifier
     * @param _tokenIds array of tokenIDs to be updated
     * @param _owners array of new owner addresses to be updated
     */
    function batchUpdateL1Holdings(uint256 _dropId, uint256[] calldata _tokenIds, address[] calldata _owners)
        external
        onlyRole(RELAYER_ROLE)
    {
        uint256 tLength = _tokenIds.length;

        // Check parameters validity
        if (tLength != _owners.length) revert ABErrors.INVALID_PARAMETER();

        // Iterate over all tokens
        for (uint256 i; i < tLength;) {
            // Update the ownership of the given token
            ownerOf[_dropId][_tokenIds[i]] = _owners[i];

            unchecked {
                ++i;
            }
        }

        // Emit HoldingsBatchUpdated event
        emit ABEvents.HoldingsBatchUpdated(_dropId, _tokenIds, _owners);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the amount of royalties claimable for a given token
     *
     * @param _dropId drop identifier
     * @param _tokenId token identifier
     * @return _totalClaimable amount of royalties claimable
     */
    function getClaimableAmount(uint256 _dropId, uint256 _tokenId) external view returns (uint256 _totalClaimable) {
        // calculate the total amount claimable
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / dropData[_dropId].supply;

        // substract the amount already claimed
        _totalClaimable = royaltiesPerToken - claimedAmount[_dropId][_tokenId];
    }

    /**
     * @notice
     *  Returns the amount of royalties claimable for the given tokens of a single drop
     *
     * @param _dropId drop identifier
     * @param _tokenIds array of token identifiers
     * @return _totalClaimable amount of royalties claimable
     */
    function getClaimableAmount(uint256 _dropId, uint256[] calldata _tokenIds)
        external
        view
        returns (uint256 _totalClaimable)
    {
        ABDataTypes.DropData memory data = dropData[_dropId];

        // calculate the total amount claimable per token
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / data.supply;

        // iterate over each token
        for (uint256 i; i < _tokenIds.length;) {
            // substract the amount already claimed
            uint256 _claimable = royaltiesPerToken - claimedAmount[_dropId][_tokenIds[i]];
            _totalClaimable += _claimable;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     *  Returns the amount of royalties claimable for the given tokens of multiple drops
     *
     * @param _dropIds array of drop identifier
     * @param _tokenIds 2-dim array of token identifiers
     * @return _totalClaimable amount of royalties claimable
     */
    function getClaimableAmount(uint256[] calldata _dropIds, uint256[][] calldata _tokenIds)
        external
        view
        returns (uint256 _totalClaimable)
    {
        uint256 dLength = _dropIds.length;

        // Check parameters validity
        if (dLength != _tokenIds.length) revert ABErrors.INVALID_PARAMETER();

        // Iterate over each drop
        for (uint256 i; i < dLength;) {
            uint256 dropId = _dropIds[i];
            ABDataTypes.DropData memory data = dropData[dropId];

            // calculate the total amount claimable per token
            uint256 royaltiesPerToken = totalDepositedPerDrop[dropId] / data.supply;

            uint256 tLength = _tokenIds[i].length;

            // Iterate over each token
            for (uint256 j; j < tLength;) {
                // substract the amount already claimed
                uint256 _claimable = royaltiesPerToken - claimedAmount[dropId][_tokenIds[i][j]];
                _totalClaimable += _claimable;

                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
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
     *  Hook called before claiming royalty to verify KYC validity
     *
     * @param _user user address to be verified
     * @param _signature signature to be validated
     */
    function _beforeClaim(address _user, bytes calldata _signature) internal view {
        // abKycModule.beforeRoyaltyClaim(_user, _signature);
    }

    /**
     * @notice
     *  Claim royalties for the user's tokens for multiple drops
     *
     * @param _dropIds array of drops to claim for
     * @param _tokenIds 2-dim array of tokens to claim for
     * @param _user user address to claim for
     * @param _signature signature used to verify KYC
     */
    function _claimMultiDrop(
        uint256[] calldata _dropIds,
        uint256[][] calldata _tokenIds,
        address _user,
        bytes calldata _signature
    ) internal {
        // Enforce KYC Signature validity through ABKYCModule contract
        _beforeClaim(_user, _signature);

        uint256 dLength = _dropIds.length;

        // Check parameters validity
        if (dLength != _tokenIds.length) revert ABErrors.INVALID_PARAMETER();

        uint256 totalClaimable;

        for (uint256 i; i < dLength;) {
            // Get drop data
            ABDataTypes.DropData memory data = dropData[_dropIds[i]];

            // Calculate the amount claimable per drop
            uint256 dropClaimable = data.isL1
                ? _handleL1Drop(_dropIds[i], _tokenIds[i], _user)
                : _handleBaseDrop(_dropIds[i], _tokenIds[i], _user, data.nft);

            // Emit RoyaltyClaimed event
            emit ABEvents.RoyaltyClaimed(_dropIds[i], _tokenIds[i], dropClaimable, _user);
            totalClaimable += dropClaimable;

            unchecked {
                ++i;
            }
        }
        // Transfer the total amount claimable of USDC to the user
        USDC.transfer(_user, totalClaimable);
    }

    /**
     * @notice
     *  Claim royalties for the user's tokens for a single drop
     *
     * @param _dropId drop to claim for
     * @param _tokenIds array of tokens to claim for
     * @param _user user address to claim for
     * @param _signature signature used to verify KYC
     */
    function _claimSingleDrop(uint256 _dropId, uint256[] calldata _tokenIds, address _user, bytes calldata _signature)
        internal
    {
        // Enforce KYC Signature validity through ABKYCModule contract
        _beforeClaim(_user, _signature);

        uint256 tLength = _tokenIds.length;
        uint256 totalClaimable;

        // Get drop data
        ABDataTypes.DropData memory data = dropData[_dropId];

        // Calculate royalties per token
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / data.supply;

        // Check if the drop is on Layer 1 or on Base
        if (data.isL1) {
            for (uint256 i; i < tLength;) {
                // Enforce token ownership
                if (ownerOf[_dropId][_tokenIds[i]] != _user) revert ABErrors.NOT_TOKEN_OWNER();

                // Calculate claimable amount
                uint256 _claimable = royaltiesPerToken - claimedAmount[_dropId][_tokenIds[i]];
                totalClaimable += _claimable;
                claimedAmount[_dropId][_tokenIds[i]] += _claimable;

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < tLength;) {
                // Enforce token ownership
                if (IERC721AB(data.nft).ownerOf(_tokenIds[i]) != _user) revert ABErrors.NOT_TOKEN_OWNER();

                // Calculate claimable amount
                uint256 _claimable = royaltiesPerToken - claimedAmount[_dropId][_tokenIds[i]];
                totalClaimable += _claimable;
                claimedAmount[_dropId][_tokenIds[i]] += _claimable;

                unchecked {
                    ++i;
                }
            }
        }
        // Transfer the total amount claimable of USDC to the user
        USDC.transfer(_user, totalClaimable);

        // Emit RoyaltyClaimed event
        emit ABEvents.RoyaltyClaimed(_dropId, _tokenIds, totalClaimable, _user);
    }

    /**
     * @notice
     *  Handler called upon claiming L1 drops
     *
     * @param _dropId drop to claim for
     * @param _tokenIds array of tokens to claim for
     * @param _user user address to claim for
     * @return _totalClaimable the amount of royalties claimable for the given drop
     */
    function _handleL1Drop(uint256 _dropId, uint256[] calldata _tokenIds, address _user)
        internal
        returns (uint256 _totalClaimable)
    {
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / dropData[_dropId].supply;
        uint256 tokenLenght = _tokenIds.length;

        for (uint256 j; j < tokenLenght;) {
            if (ownerOf[_dropId][_tokenIds[j]] != _user) revert ABErrors.NOT_TOKEN_OWNER();

            uint256 claimable = royaltiesPerToken - claimedAmount[_dropId][_tokenIds[j]];
            _totalClaimable += claimable;
            claimedAmount[_dropId][_tokenIds[j]] += claimable;

            unchecked {
                ++j;
            }
        }
    }

    /**
     * @notice
     *  Handler called upon claiming Base drops
     *
     * @param _dropId drop to claim for
     * @param _tokenIds array of tokens to claim for
     * @param _user user address to claim for
     * @param _nft address of Base NFT
     * @return _totalClaimable the amount of royalties claimable for the given drop
     */
    function _handleBaseDrop(uint256 _dropId, uint256[] calldata _tokenIds, address _user, address _nft)
        internal
        returns (uint256 _totalClaimable)
    {
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / dropData[_dropId].supply;
        uint256 tokenLenght = _tokenIds.length;
        IERC721AB nft = IERC721AB(_nft);

        for (uint256 j; j < tokenLenght;) {
            if (nft.ownerOf(_tokenIds[j]) != _user) revert ABErrors.NOT_TOKEN_OWNER();

            uint256 claimable = royaltiesPerToken - claimedAmount[_dropId][_tokenIds[j]];
            _totalClaimable += claimable;
            claimedAmount[_dropId][_tokenIds[j]] += claimable;

            unchecked {
                ++j;
            }
        }
    }
}
