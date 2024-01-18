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

    IERC20 public USDC;
    IABKYCModule public abKycModule;

    mapping(uint256 dropId => uint256 totalDeposited) public totalDepositedPerDrop;
    mapping(uint256 dropId => ABDataTypes.DropData dropData) public dropData;
    mapping(uint256 dropId => mapping(uint256 tokenId => uint256 amount) claimedPerTokenId) public claimedAmount;
    mapping(uint256 dropId => mapping(uint256 tokenId => address owner) ownerOf) public ownerOf;

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
     */
    function initialize(address _abKycModule, address _relayer) external initializer {
        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RELAYER_ROLE, _relayer);

        // Set ABKYCModule interface
        abKycModule = IABKYCModule(_abKycModule);

        // Backfill existing drop data
        /// TODO : get accurate data for all drops since genesis
        dropData[1] = ABDataTypes.DropData(address(0), true, 100);
        dropData[2] = ABDataTypes.DropData(address(0), true, 100);
        dropData[3] = ABDataTypes.DropData(address(0), true, 100);
        dropData[4] = ABDataTypes.DropData(address(0), true, 100);
        dropData[5] = ABDataTypes.DropData(address(0), true, 100);
        dropData[6] = ABDataTypes.DropData(address(0), true, 100);
        dropData[7] = ABDataTypes.DropData(address(0), true, 100);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function claim(uint256[] calldata _dropIds, uint256[][] calldata _tokenIds, bytes calldata _signature) external {
        _claimMultiDrop(_dropIds, _tokenIds, msg.sender, _signature);
    }

    function claim(uint256 _dropId, uint256[] calldata _tokenIds, bytes calldata _signature) external {
        _claimSingleDrop(_dropId, _tokenIds, msg.sender, _signature);
    }

    //      ____        __         ___       __          _
    //     / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //    / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //   / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //   \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //                /____/

    function claimOnBehalf(
        uint256[] calldata _dropIds,
        uint256[][] calldata _tokenIds,
        address _user,
        bytes calldata _signature
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _claimMultiDrop(_dropIds, _tokenIds, _user, _signature);
    }

    function claimOnBehalf(uint256 _dropId, uint256[] calldata _tokenIds, address _user, bytes calldata _signature)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _claimSingleDrop(_dropId, _tokenIds, _user, _signature);
    }

    function depositRoyalty(uint256 _dropId, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalDepositedPerDrop[_dropId] += _amount;
        USDC.transferFrom(msg.sender, address(this), _amount);

        emit ABEvents.RoyaltyDistributed(_dropId, _amount);
    }

    function depositRoyalty(uint256[] calldata _dropIds, uint256[] calldata _amounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 totalAmount;
        uint256 dLength = _dropIds.length;

        // Check parameters validity
        if (dLength != _amounts.length) revert ABErrors.INVALID_PARAMETER();

        for (uint256 i; i < dLength;) {
            totalDepositedPerDrop[_dropIds[i]] += _amounts[i];
            totalAmount += _amounts[i];

            unchecked {
                ++i;
            }
        }
        USDC.transferFrom(msg.sender, address(this), totalAmount);

        emit ABEvents.RoyaltyDistributed(_dropIds, _amounts);
    }

    //     ____        __         ____       __
    //    / __ \____  / /_  __   / __ \___  / /___ ___  _____  _____
    //   / / / / __ \/ / / / /  / /_/ / _ \/ / __ `/ / / / _ \/ ___/
    //  / /_/ / / / / / /_/ /  / _, _/  __/ / /_/ / /_/ /  __/ /
    //  \____/_/ /_/_/\__, /  /_/ |_|\___/_/\__,_/\__, /\___/_/
    //               /____/                      /____/

    function updateL1Holdings(uint256 _dropId, uint256 _tokenId, address _newOwner) external onlyRole(RELAYER_ROLE) {
        ownerOf[_dropId][_tokenId] = _newOwner;
    }

    function batchUpdateL1Holdings(uint256 _dropId, uint256[] calldata _tokenIds, address[] calldata _owners)
        external
        onlyRole(RELAYER_ROLE)
    {
        uint256 tLength = _tokenIds.length;

        // Check parameters validity
        if (tLength != _owners.length) revert ABErrors.INVALID_PARAMETER();

        for (uint256 i; i < tLength;) {
            ownerOf[_dropId][_tokenIds[i]] = _owners[i];
        }
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function getClaimableAmount(uint256 _dropId, uint256[] calldata _tokenIds)
        external
        view
        returns (uint256 _totalClaimable)
    {
        ABDataTypes.DropData memory data = dropData[_dropId];
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / data.supply;

        for (uint256 i; i < _tokenIds.length;) {
            uint256 _claimable = royaltiesPerToken - claimedAmount[_dropId][_tokenIds[i]];
            _totalClaimable += _claimable;

            unchecked {
                ++i;
            }
        }
    }

    function getClaimableAmount(uint256[] calldata _dropIds, uint256[][] calldata _tokenIds)
        external
        view
        returns (uint256 _totalClaimable)
    {
        uint256 dLength = _dropIds.length;

        // Check parameters validity
        if (dLength != _tokenIds.length) revert ABErrors.INVALID_PARAMETER();

        for (uint256 i; i < dLength;) {
            uint256 dropId = _dropIds[i];
            ABDataTypes.DropData memory data = dropData[dropId];
            uint256 royaltiesPerToken = totalDepositedPerDrop[dropId] / data.supply;

            for (uint256 j; j < _tokenIds[i].length;) {
                uint256 _claimable = royaltiesPerToken - claimedAmount[dropId][_tokenIds[j][i]];
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

    function _beforeClaim(address _user, bytes calldata _signature) internal view {
        abKycModule.beforeRoyaltyClaim(_user, _signature);
    }

    function _claimMultiDrop(
        uint256[] calldata _dropIds,
        uint256[][] calldata _tokenIds,
        address _user,
        bytes calldata _signature
    ) internal {
        // Enforce KYC Signature validity through ABKYCModule contract
        _beforeClaim(_user, _signature);

        // Check parameters validity
        uint256 dLength = _dropIds.length;
        if (dLength != _tokenIds.length) revert ABErrors.INVALID_PARAMETER();

        uint256 totalClaimable;

        for (uint256 i; i < dLength;) {
            uint256 dropId = _dropIds[i];

            // Get drop data
            ABDataTypes.DropData memory data = dropData[dropId];

            // Calculate royalties per token
            uint256 royaltiesPerToken = totalDepositedPerDrop[dropId] / data.supply;

            // Check if the drop is on Layer 1 or on Base
            if (data.isL1) {
                for (uint256 j; j < _tokenIds[i].length;) {
                    // Enforce token ownership
                    if (ownerOf[dropId][_tokenIds[j][i]] != _user) revert ABErrors.NOT_TOKEN_OWNER();

                    // Calculate claimable amount
                    uint256 _claimable = royaltiesPerToken - claimedAmount[dropId][_tokenIds[j][i]];
                    totalClaimable += _claimable;
                    claimedAmount[dropId][_tokenIds[j][i]] += _claimable;

                    unchecked {
                        ++j;
                    }
                }
            } else {
                for (uint256 j; j < _tokenIds[i].length;) {
                    // Enforce token ownership
                    if (IERC721AB(data.nft).ownerOf(_tokenIds[j][i]) != _user) revert ABErrors.NOT_TOKEN_OWNER();

                    // Calculate claimable amount
                    uint256 _claimable = royaltiesPerToken - claimedAmount[dropId][_tokenIds[j][i]];
                    totalClaimable += _claimable;
                    claimedAmount[dropId][_tokenIds[j][i]] += _claimable;

                    unchecked {
                        ++j;
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
        // Transfer total claimable amount to the shareholder
        USDC.transfer(_user, totalClaimable);

        emit ABEvents.RoyaltyClaimed(_dropIds, _tokenIds, totalClaimable);
    }

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
        // Transfer total claimable amount to the shareholder
        USDC.transfer(_user, totalClaimable);

        emit ABEvents.RoyaltyClaimed(_dropId, _tokenIds, totalClaimable);
    }
}
