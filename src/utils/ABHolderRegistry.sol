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
 * @title ABHolderRegistry
 * @author Anotherblock Technical Team
 * @notice Anotherblock Holder Registry contract responsible for housekeeping AB NFT holders details
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ABHolderRegistry is AccessControl {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Amount of `units` held by `account` for a given `dropId`
    mapping(address account => mapping(uint256 dropId => uint256 units)) public userUnitsPerDrop;

    /// @dev Collection Role
    bytes32 public constant COLLECTION_ROLE = keccak256("COLLECTION_ROLE");

    /// @dev Factory Role
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    constructor() {
        // Grant `DEFAULT_ADMIN_ROLE` to the sender
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //     ____        __         ___                                         __
    //    / __ \____  / /_  __   /   |  ____  ____  _________ _   _____  ____/ /
    //   / / / / __ \/ / / / /  / /| | / __ \/ __ \/ ___/ __ \ | / / _ \/ __  /
    //  / /_/ / / / / / /_/ /  / ___ |/ /_/ / /_/ / /  / /_/ / |/ /  __/ /_/ /
    //  \____/_/ /_/_/\__, /  /_/  |_/ .___/ .___/_/   \____/|___/\___/\__,_/
    //               /____/         /_/   /_/

    /**
     * @notice
     *  Update the units counts for the previous holder and the new holder
     *  Only contracts with COLLECTION_ROLE can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _dropId drop identifier
     * @param _quantity amount of token transferred
     */
    function registerHolderChange721(address _previousHolder, address _newHolder, uint256 _dropId, uint256 _quantity)
        external
        onlyRole(COLLECTION_ROLE)
    {
        // Remove `_quantity` of `_dropId` shares from `_previousHolder`
        _loseShare(_previousHolder, _dropId, _quantity);

        // Add `_quantity` of `_dropId` shares to `_newHolder`
        _gainShare(_newHolder, _dropId, _quantity);
    }

    /**
     * @notice
     *  Update the units counts for the previous holder and the new holder
     *  Only contracts with COLLECTION_ROLE can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _dropIds drop identifiers
     * @param _quantities amount of token transferred
     */
    function registerHolderChange1155(
        address _previousHolder,
        address _newHolder,
        uint256[] calldata _dropIds,
        uint256[] calldata _quantities
    ) external onlyRole(COLLECTION_ROLE) {
        for (uint256 i = 0; i < _dropIds.length; ++i) {
            // Remove `_quantity` of `_dropId` shares from `_previousHolder`
            _loseShare(_previousHolder, _dropIds[i], _quantities[i]);

            // Add `_quantity` of `_dropId` shares to `_newHolder`
            _gainShare(_newHolder, _dropIds[i], _quantities[i]);
        }
    }

    /**
     * @notice
     *  Set allowed status to true for the given `_collection` contract address
     *  Only AnotherCloneFactory can perform this operation
     *
     * @param _collection nft contract address to be granted with the collection role
     */

    function grantCollectionRole(address _collection) external onlyRole(FACTORY_ROLE) {
        // Grant `COLLECTION_ROLE` to the given `_collection`
        _grantRole(COLLECTION_ROLE, _collection);
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Return the amount of `_dropId` nft held by `_user`
     *
     * @param _user user address to be queried
     * @param _dropId drop identifier to be queried
     *
     * @return _amount amount of `dropId` nft held by `_user`
     */
    function getUserUnits(address _user, uint256 _dropId) external view returns (uint256 _amount) {
        _amount = userUnitsPerDrop[_user][_dropId];
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    /**
     * @notice
     *  Add subscription units to the user
     *
     * @param _user user address
     * @param _units amount of units to add
     */
    function _gainShare(address _user, uint256 _dropId, uint256 _units) internal {
        // Ensure user address is not zero-address
        if (_user == address(0)) return;

        // Add `_units` to the user current units amount
        userUnitsPerDrop[_user][_dropId] += _units;
    }

    /**
     * @notice
     *  Remove subscription units from the user
     *
     * @param _user user address
     * @param _units amount of units to remove
     */
    function _loseShare(address _user, uint256 _dropId, uint256 _units) internal {
        // Ensure user address is not zero-address
        if (_user == address(0)) return;

        // Remove `_units` from the user current units amount
        userUnitsPerDrop[_user][_dropId] -= _units;
    }
}
