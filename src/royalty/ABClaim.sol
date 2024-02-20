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

        emit ABEvents.RoyaltyDistributedMultiDrop(_dropIds, _amounts);
    }

    function setDropData(uint256 _dropId, address _nft, bool _isL1, uint256 _supply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dropData[_dropId] = ABDataTypes.DropData(_nft, _isL1, _supply);
        emit ABEvents.DropDataUpdated(_dropId, _nft, _isL1, _supply);
    }

    function setDropData(
        uint256[] calldata _dropIds,
        address[] calldata _nfts,
        bool[] calldata _isL1,
        uint256[] calldata _supplies
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 dLength = _dropIds.length;

        if (_nfts.length != dLength) revert ABErrors.INVALID_PARAMETER();
        if (_isL1.length != dLength) revert ABErrors.INVALID_PARAMETER();
        if (_supplies.length != dLength) revert ABErrors.INVALID_PARAMETER();

        for (uint256 i; i < dLength;) {
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

    function updateL1Holdings(uint256 _dropId, uint256 _tokenId, address _newOwner) external onlyRole(RELAYER_ROLE) {
        ownerOf[_dropId][_tokenId] = _newOwner;
        emit ABEvents.HoldingsUpdated(_dropId, _tokenId, _newOwner);
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

            unchecked {
                ++i;
            }
        }

        emit ABEvents.HoldingsBatchUpdated(_dropId, _tokenIds, _owners);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function getClaimableAmount(uint256 _dropId, uint256 _tokenId) external view returns (uint256 _totalClaimable) {
        uint256 royaltiesPerToken = totalDepositedPerDrop[_dropId] / dropData[_dropId].supply;
        _totalClaimable = royaltiesPerToken - claimedAmount[_dropId][_tokenId];
    }

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

            uint256 tLength = _tokenIds[i].length;
            for (uint256 j; j < tLength;) {
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

    function _beforeClaim(address _user, bytes calldata _signature) internal view {
        // abKycModule.beforeRoyaltyClaim(_user, _signature);
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
            // Get drop data
            ABDataTypes.DropData memory data = dropData[_dropIds[i]];
            // get the claimableAmount depening on L1 or Base
            uint256 dropClaimable = data.isL1 ? 
                                    handleL1Drop(_dropIds[i], _tokenIds[i], _user) : 
                                    handleBaseDrop(_dropIds[i], _tokenIds[i], _user, data.nft);
            
            //emit event with dropClaimable from the handler
            emit ABEvents.RoyaltyClaimed(_dropIds[i], _tokenIds[i], dropClaimable, _user);
            totalClaimable += dropClaimable;

            unchecked {
                ++i;
            }
        }
        //transfer the totalClaimable
        USDC.transfer(_user, totalClaimable);
    }

    function handleL1Drop(uint256 dropId, uint256[] calldata tokenIds, address user) internal returns (uint256) {
        uint256 totalClaimable;
        uint256 royaltiesPerToken = totalDepositedPerDrop[dropId] / dropData[dropId].supply;
        uint256 tokenLenght = tokenIds.length;

        for (uint256 j; j < tokenLenght;) {
            if (ownerOf[dropId][tokenIds[j]] != user) revert ABErrors.NOT_TOKEN_OWNER();

            uint256 claimable = royaltiesPerToken - claimedAmount[dropId][tokenIds[j]];
            totalClaimable += claimable;
            claimedAmount[dropId][tokenIds[j]] += claimable;

            unchecked {
                ++j;
            }
        }

        return totalClaimable;
    }

    function handleBaseDrop(uint256 dropId, uint256[] calldata tokenIds, address user, address nftAddress) internal returns (uint256) {
        uint256 totalClaimable;
        uint256 royaltiesPerToken = totalDepositedPerDrop[dropId] / dropData[dropId].supply;
        uint256 tokenLenght = tokenIds.length;
        IERC721AB nft = IERC721AB(nftAddress);


        for (uint256 j; j < tokenLenght;) {
            if (nft.ownerOf(tokenIds[j]) != user) revert ABErrors.NOT_TOKEN_OWNER();

            uint256 claimable = royaltiesPerToken - claimedAmount[dropId][tokenIds[j]];
            totalClaimable += claimable;
            claimedAmount[dropId][tokenIds[j]] += claimable;

            unchecked {
                ++j;
            }
        }

        return totalClaimable;
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

        emit ABEvents.RoyaltyClaimed(_dropId, _tokenIds, totalClaimable, _user);
    }
}
