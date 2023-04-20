//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ERC721AB} from "./ERC721AB.sol";
import {ERC1155AB} from "./ERC1155AB.sol";
import {ABRoyalty} from "./ABRoyalty.sol";

contract AnotherCloneFactory is Ownable {
    ///@dev Custom Error when caller is not authorized to perform operation
    error FORBIDDEN();

    event CollectionCreated(address nft, address payout, address owner, uint256 collectionId);

    ///@dev Collection Structure
    struct Collection {
        uint256 collectionId;
        address nftContract;
        address payoutContract;
    }

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    uint256 private immutable DROP_ID_OFFSET;

    // Array of all Collection created by this factory
    Collection[] public collections;

    // Approval status for a given account
    mapping(address account => bool isApproved) public approvedAccount;

    // ABVerifier contract address
    address public abVerifier;

    // Standard Anotherblock ERC721 contract implementation address
    address public erc721Impl;

    // Standard Anotherblock ERC1155 contract implementation address
    address public erc1155Impl;

    // Standard Anotherblock Royalty Payout (IDA) contract implementation address
    address public royaltyImpl;

    constructor(uint256 _offset, address _abVerifier, address _erc721Impl, address _erc1155Impl, address _royaltyImpl) {
        DROP_ID_OFFSET = _offset;
        abVerifier = _abVerifier;
        erc721Impl = _erc721Impl;
        erc1155Impl = _erc1155Impl;
        royaltyImpl = _royaltyImpl;
    }

    //     ____        __         ___                                         __
    //    / __ \____  / /_  __   /   |  ____  ____  _________ _   _____  ____/ /
    //   / / / / __ \/ / / / /  / /| | / __ \/ __ \/ ___/ __ \ | / / _ \/ __  /
    //  / /_/ / / / / / /_/ /  / ___ |/ /_/ / /_/ / /  / /_/ / |/ /  __/ /_/ /
    //  \____/_/ /_/_/\__, /  /_/  |_/ .___/ .___/_/   \____/|___/\___/\__,_/
    //               /____/         /_/   /_/

    function createCollection721(
        string memory _name,
        string memory _symbol,
        bool hasPayout,
        address _payoutToken,
        bytes32 _salt
    ) external onlyPublisher {
        // Calculate new Collection ID
        uint256 newCollectionId = _getNewCollectionId();

        // Create new NFT contract
        ERC721AB newCollection = ERC721AB(Clones.cloneDeterministic(erc721Impl, _salt));

        if (hasPayout) {
            // Create new Payout contract
            ABRoyalty newPayout = ABRoyalty(Clones.clone(royaltyImpl));

            // Initialize Payout contract
            newPayout.initialize(address(this), _payoutToken, address(newCollection));

            // Initialize NFT contract
            newCollection.initialize(address(newPayout), abVerifier, _name, _symbol);

            // Transfer Payout contract ownership
            newPayout.transferOwnership(msg.sender);

            // Log drop details in Collections array
            collections.push(Collection(newCollectionId, address(newCollection), address(newPayout)));

            // emit Collection creation event
            emit CollectionCreated(address(newCollection), address(newPayout), msg.sender, newCollectionId);
        } else {
            // Initialize NFT contract (with no payout address)
            newCollection.initialize(address(0), abVerifier, _name, _symbol);

            // Log drop details in Collections array
            collections.push(Collection(newCollectionId, address(newCollection), address(0)));

            // emit Collection creation event
            emit CollectionCreated(address(newCollection), address(0), msg.sender, newCollectionId);
        }

        // Transfer NFT contract ownership
        newCollection.transferOwnership(msg.sender);
    }

    function createCollection1155(address _payoutToken, bytes32 _salt) external onlyPublisher {
        // Calculate new Collection ID
        uint256 newCollectionId = _getNewCollectionId();

        // Create new Payout contract
        ABRoyalty newPayout = ABRoyalty(Clones.clone(royaltyImpl));

        // Create new NFT contract
        ERC1155AB newCollection = ERC1155AB(Clones.cloneDeterministic(erc1155Impl, _salt));

        newPayout.initialize(address(this), _payoutToken, address(newCollection));
        newCollection.initialize(address(newPayout), abVerifier);

        // Transfer Ownership of NFT contract and Payout contract to the caller
        newPayout.transferOwnership(msg.sender);
        newCollection.transferOwnership(msg.sender);

        emit CollectionCreated(address(newCollection), address(newPayout), msg.sender, collections.length);

        // Store the new Collection contracts addresses
        collections.push(Collection(newCollectionId, address(newCollection), address(newPayout)));
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    function setApproval(address _account, bool _isApproved) external onlyOwner {
        approvedAccount[_account] = _isApproved;
    }

    function setERC721Implementation(address _newImpl) external onlyOwner {
        erc721Impl = _newImpl;
    }

    function setERC1155Implementation(address _newImpl) external onlyOwner {
        erc1155Impl = _newImpl;
    }

    function setABRoyaltyImplementation(address _newImpl) external onlyOwner {
        royaltyImpl = _newImpl;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function predictERC721Address(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721Impl, salt, address(this));
    }

    function predictERC1155Address(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc1155Impl, salt, address(this));
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _getNewCollectionId() internal view returns (uint256 newCollectionId) {
        newCollectionId = collections.length + DROP_ID_OFFSET + 1;
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  _____
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/

    modifier onlyPublisher() {
        if (msg.sender != owner() && !approvedAccount[msg.sender]) {
            revert FORBIDDEN();
        }
        _;
    }
}
