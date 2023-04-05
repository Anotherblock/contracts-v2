// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ABRoyaltyMock {
    address private nft;

    mapping(address holder => uint256 units) private holderUnits;

    uint256 public constant IDA_UNITS_PRECISION = 1000;

    constructor(address _nft) {
        nft = _nft;
    }

    /**
     * @notice
     *  Update the subscription units for the previous holder and the new holder
     *  Only Anotherblock Relay contract can perform this operation
     *
     * @param _previousHolder previous holder address
     * @param _newHolder new holder address
     * @param _quantity array of quantity (per index)
     */
    function updatePayout721(address _previousHolder, address _newHolder, uint256 _quantity) external {
        // Remove `_quantity` of `_dropId` shares from `_previousHolder`
        _loseShare(_previousHolder, 0, _quantity * IDA_UNITS_PRECISION);

        // Add `_quantity` of `_dropId` shares to `_newHolder`
        _gainShare(_newHolder, 0, _quantity * IDA_UNITS_PRECISION);
    }

    /**
     * @notice
     *  Add subscription units to the subscriber
     *
     * @param _subscriber subscriber address
     * @param _units amount of units to add
     */
    function _gainShare(address _subscriber, uint256 _index, uint256 _units) internal {
        // Ensure subscriber address is not zero-address
        if (_subscriber == address(0)) return;

        holderUnits[_subscriber] += _units;
    }

    /**
     * @notice
     *  Remove subscription units from the subscriber
     *
     * @param _subscriber subscriber address
     * @param _units amount of units to remove
     */
    function _loseShare(address _subscriber, uint256 _index, uint256 _units) internal {
        // Ensure subscriber address is not zero-address
        if (_subscriber == address(0)) return;

        // Get the subscriber's current units
        uint256 currentUnitsHeld = holderUnits[_subscriber];

        holderUnits[_subscriber] -= _units;
    }
}
