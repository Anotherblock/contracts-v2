import {IABDataRegistry} from "src/utils/IABDataRegistry.sol";

import {ABErrors} from "src/libraries/ABErrors.sol";

contract ABRoyaltyHelper {
    IABDataRegistry public abDataRegistry;

    struct RoyaltyClaimParams {
        address royalty;
        bool hasKYC;
        uint256[] dropIds;
        bytes kycSig;
    }

    constructor(address _abDataRegistry) {
        abDataRegistry = IABDataRegistry(_abDataRegistry);
    }

    function multiClaim(address[] calldata _publishers, uint256[] calldata _dropIds) external {
        uint256 dLength = _dropIds.length;
        uint256 pLength = _publishers.length;

        if (pLength != dLength) revert ABErrors.INVALID_PARAMETER();

        address royalty;

        for (uint256 i; i < dLength;) {
            royalty = abDataRegistry.getRoyaltyContract(_publishers[i]);

            (bool success,) =
                royalty.call(abi.encodeWithSignature("claimPayoutsOnBehalf(uint256,address)", _dropIds[i], msg.sender));

            if (!success) revert ABErrors.TRANSFER_FAILED();
            unchecked {
                ++i;
            }
        }
    }

    function multiClaim(RoyaltyClaimParams[] calldata _claimParams) external {
        uint256 paramLength = _claimParams.length;

        for (uint256 i; i < paramLength;) {
            if (_claimParams[i].hasKYC) {
                (bool success,) = _claimParams[i].royalty.call(
                    abi.encodeWithSignature(
                        "claimPayoutsOnBehalf(uint256[],address,bytes)",
                        _claimParams[i].dropIds,
                        msg.sender,
                        _claimParams[i].kycSig
                    )
                );
                if (!success) revert ABErrors.TRANSFER_FAILED();
            } else {
                (bool success,) = _claimParams[i].royalty.call(
                    abi.encodeWithSignature(
                        "claimPayoutsOnBehalf(uint256[],address)", _claimParams[i].dropIds, msg.sender
                    )
                );
                if (!success) revert ABErrors.TRANSFER_FAILED();
            }

            unchecked {
                ++i;
            }
        }
    }
}
