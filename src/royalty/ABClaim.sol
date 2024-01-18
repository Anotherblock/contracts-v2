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

/* anotherblock Interfaces */
import {IERC721AB} from "src/token/ERC721/IERC721AB.sol";

struct DropData {
    address nft;
    bool isL1;
    uint256 supply;
}

contract ABClaim is Initializable, AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    IERC20 public USDC;

    mapping(uint256 dropId => uint256 totalDeposited) public totalDepositedPerDrop;
    mapping(uint256 dropId => DropData dropData) public dropData;
    mapping(uint256 dropId => mapping(uint256 tokenId => uint256 amount) claimedPerTokenId) public claimedAmount;
    mapping(uint256 dropId => mapping(uint256 tokenId => address owner) ownerOf) public ownerOf;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    ///@dev ABClaim implementation version
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
    /// @custom:oz-upgrades-unsafe-allow constructork
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice
     *  Contract Initializer
     *
     */
    function initialize(address _relayer) external initializer {
        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RELAYER_ROLE, _relayer);

        // Backfill existing drop data
        /// TODO : get accurate data for all drops since genesis
        dropData[1] = DropData(address(0), true, 100);
        dropData[2] = DropData(address(0), true, 100);
        dropData[3] = DropData(address(0), true, 100);
        dropData[4] = DropData(address(0), true, 100);
        dropData[5] = DropData(address(0), true, 100);
        dropData[6] = DropData(address(0), true, 100);
        dropData[7] = DropData(address(0), true, 100);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function claim(uint256[] calldata _dropIds, uint256[][] calldata _tokenIds) external {
        uint256 dLength = _dropIds.length;
        if (dLength != _tokenIds.length) revert ABErrors.INVALID_PARAMETER();

        uint256 totalClaimable;

        for (uint256 i; i < dLength;) {
            uint256 dropId = _dropIds[i];
            DropData memory data = dropData[dropId];
            uint256 royaltiesPerToken = totalDepositedPerDrop[dropId] / data.supply;

            if (data.isL1) {
                for (uint256 j; j < _tokenIds[i].length;) {
                    if (ownerOf[dropId][_tokenIds[j][i]] != msg.sender) revert ABErrors.NOT_TOKEN_OWNER();
                    uint256 _claimable = royaltiesPerToken - claimedAmount[dropId][_tokenIds[j][i]];
                    totalClaimable += _claimable;
                    claimedAmount[dropId][_tokenIds[j][i]] += _claimable;

                    unchecked {
                        ++j;
                    }
                }
            } else {
                for (uint256 j; j < _tokenIds[i].length;) {
                    if (IERC721AB(data.nft).ownerOf(_tokenIds[j][i]) != msg.sender) revert ABErrors.NOT_TOKEN_OWNER();
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
        USDC.transfer(msg.sender, totalClaimable);
    }

    /// TODO add claim function for single drop claiming (save gas for users only holding one drop)
    function claim(uint256 _dropId, uint256[] calldata _tokenId) external {}

    //      ____        __         ___       __          _
    //     / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
    //    / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
    //   / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
    //   \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
    //                /____/

    function depositRoyalty(uint256 _dropId, uint256 _amount) external {}
    function depositRoyalty(uint256[] calldata _dropId, uint256[] calldata _amount) external {}

    //     ____        __         ____       __
    //    / __ \____  / /_  __   / __ \___  / /___ ___  _____  _____
    //   / / / / __ \/ / / / /  / /_/ / _ \/ / __ `/ / / / _ \/ ___/
    //  / /_/ / / / / / /_/ /  / _, _/  __/ / /_/ / /_/ /  __/ /
    //  \____/_/ /_/_/\__, /  /_/ |_|\___/_/\__,_/\__, /\___/_/
    //               /____/                      /____/

    function updateL1Holdings(uint256 _dropId, uint256 _tokenId, address _newOwner) external onlyRole(RELAYER_ROLE) {
        ownerOf[_dropId][_tokenId] = _newOwner;
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
        DropData memory data = dropData[_dropId];
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
        if (dLength != _tokenIds.length) revert ABErrors.INVALID_PARAMETER();

        for (uint256 i; i < dLength;) {
            uint256 dropId = _dropIds[i];
            DropData memory data = dropData[dropId];
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
}

//    ____        __         ___       __          _
//   / __ \____  / /_  __   /   | ____/ /___ ___  (_)___
//  / / / / __ \/ / / / /  / /| |/ __  / __ `__ \/ / __ \
// / /_/ / / / / / /_/ /  / ___ / /_/ / / / / / / / / / /
// \____/_/ /_/_/\__, /  /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
//              /____/
