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
 * @title ABMockRoyalty
 * @author anotherblock Technical Team
 * @notice anotherblock contract responsible for paying out royalties
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/* anotherblock Interfaces */
import {IABMockRoyalty} from "src/royalty/IABMockRoyalty.sol";
import {IABKYCModule} from "src/utils/IABKYCModule.sol";

contract ABMockRoyalty is IABMockRoyalty, Initializable, AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Publisher address
    address public publisher;

    /// @dev anotherblock KYC Module contract interface (see IABKYCModule.sol)
    IABKYCModule public abKycModule;

    /// @dev NFT contract address of a given drop identifier
    mapping(uint256 dropId => address nft) public nftPerDropId;

    /// @dev Royalty currency contract address of a given drop identifier
    mapping(uint256 dropId => address royaltyCurrency) public royaltyCurrency;

    /// @dev anotherblock Admin Role
    bytes32 public constant AB_ADMIN_ROLE = keccak256("AB_ADMIN_ROLE");

    /// @dev Registry Role
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");

    /// @dev Instant Distribution Agreement units precision
    uint256 public constant IDA_UNITS_PRECISION = 1_000;

    ///@dev ABRoyalty implementation version
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
     *  Contract Initializer
     *
     * @param _publisher collection publisher address
     * @param _abDataRegistry anotherblock data registry contract address
     */
    function initialize(address _publisher, address _abDataRegistry, address _abKycModule) external initializer {
        // Initialize Access Control
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _publisher);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRY_ROLE, _abDataRegistry);

        // Assign ABKYCModule address
        abKycModule = IABKYCModule(_abKycModule);

        // Assign the publisher address
        publisher = _publisher;
    }

    //     ____        __         ____             _      __
    //    / __ \____  / /_  __   / __ \___  ____ _(_)____/ /________  __
    //   / / / / __ \/ / / / /  / /_/ / _ \/ __ `/ / ___/ __/ ___/ / / /
    //  / /_/ / / / / / /_/ /  / _, _/  __/ /_/ / (__  ) /_/ /  / /_/ /
    //  \____/_/ /_/_/\__, /  /_/ |_|\___/\__, /_/____/\__/_/   \__, /
    //               /____/              /____/                /____/

    /**
     * @notice
     *  Initialize the Superfluid IDA Payout Index for a given Drop
     *  Only anotherblock Data Registry contract can perform this operation
     *
     * @param _nft nft contract address
     * @param _royaltyCurrency super token currency used for payout
     * @param _dropId drop identifier
     */
    function initPayoutIndex(address _nft, address _royaltyCurrency, uint256 _dropId)
        external
        onlyRole(REGISTRY_ROLE)
    {}

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only anotherblock Data Registry contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _dropIds array of corresponding index
     * @param _quantities array of quantity (per index)
     */
    function updatePayout1155(
        address _previousHolder,
        address _newHolder,
        uint256[] calldata _dropIds,
        uint256[] calldata _quantities
    ) external onlyRole(REGISTRY_ROLE) {}

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only anotherblock Data Registry contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _dropId drop identifier
     * @param _quantity array of quantity (per index)
     */
    function updatePayout721(address _previousHolder, address _newHolder, uint256 _dropId, uint256 _quantity)
        external
        onlyRole(REGISTRY_ROLE)
    {}
}
