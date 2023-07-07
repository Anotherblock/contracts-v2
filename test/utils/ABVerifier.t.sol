// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABVerifierTestData} from "test/_testdata/ABVerifier.td.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ABVerifierTest is Test, ABVerifierTestData {
    using ECDSA for bytes32;

    /* Admin */
    address public abAdmin;

    /* Signers */
    uint256 public abSignerPkey = 69;
    uint256 public customSignerPkey = 420;

    address public abSigner;
    address public customSigner;

    /* Users */
    address payable public alice;
    address payable public bob;

    /* Mock collection address */
    address public collection1;
    address public collection2;

    /* Contracts */
    ABVerifier public abVerifier;

    function setUp() public {
        /* Setup admins */
        abAdmin = vm.addr(100);
        abSigner = vm.addr(abSignerPkey);
        customSigner = vm.addr(customSignerPkey);

        /* Setup users */
        alice = payable(vm.addr(1));
        vm.label(alice, "alice");

        bob = payable(vm.addr(2));
        vm.label(bob, "bob");

        /* Setup mock collection */
        collection1 = vm.addr(10);
        collection2 = vm.addr(20);

        /* Contracts Deployments & Initialization */
        abVerifier = new ABVerifier();
        abVerifier.initialize(abSigner);
        vm.label(address(abVerifier), "abVerifier");

        abVerifier.grantRole(AB_ADMIN_ROLE_HASH, abAdmin);
    }

    function test_verifySignature721_isValid() public {
        bytes memory generatedSignature = _generateSignature721(abSignerPkey, alice, collection1, PHASE_0);
        bool validity = abVerifier.verifySignature721(alice, collection1, PHASE_0, generatedSignature);
        assertEq(validity, true);
    }

    function test_verifySignature721_isInvalid_phase(uint256 _phase) public {
        vm.assume(_phase != PHASE_0);
        bytes memory generatedSignature = _generateSignature721(abSignerPkey, alice, collection1, PHASE_0);
        bool validity = abVerifier.verifySignature721(alice, collection1, _phase, generatedSignature);
        assertEq(validity, false);
    }

    function test_verifySignature721_isInvalid_collection(address _collection) public {
        vm.assume(_collection != collection1);
        bytes memory generatedSignature = _generateSignature721(abSignerPkey, alice, collection1, PHASE_0);
        bool validity = abVerifier.verifySignature721(alice, _collection, PHASE_0, generatedSignature);
        assertEq(validity, false);
    }

    function test_verifySignature721_isInvalid_signer() public {
        bytes memory generatedSignature = _generateSignature721(customSignerPkey, alice, collection1, PHASE_0);
        bool validity = abVerifier.verifySignature721(alice, collection1, PHASE_0, generatedSignature);
        assertEq(validity, false);
    }

    function test_verifySignature1155_isValid() public {
        bytes memory generatedSignature = _generateSignature1155(abSignerPkey, bob, collection2, TOKEN_1, PHASE_1);
        bool validity = abVerifier.verifySignature1155(bob, collection2, TOKEN_1, PHASE_1, generatedSignature);
        assertEq(validity, true);
    }

    function test_verifySignature1155_isInvalid_phase(uint256 _phase) public {
        vm.assume(_phase != PHASE_1);
        bytes memory generatedSignature = _generateSignature1155(abSignerPkey, alice, collection2, TOKEN_1, PHASE_1);
        bool validity = abVerifier.verifySignature1155(alice, collection2, TOKEN_1, _phase, generatedSignature);
        assertEq(validity, false);
    }

    function test_verifySignature1155_isInvalid_token(uint256 _token) public {
        vm.assume(_token != TOKEN_1);
        bytes memory generatedSignature = _generateSignature1155(abSignerPkey, alice, collection2, TOKEN_1, PHASE_1);
        bool validity = abVerifier.verifySignature1155(alice, collection2, _token, PHASE_1, generatedSignature);
        assertEq(validity, false);
    }

    function test_verifySignature1155_isInvalid_collection(address _collection) public {
        vm.assume(_collection != collection2);
        bytes memory generatedSignature = _generateSignature1155(abSignerPkey, alice, collection2, TOKEN_1, PHASE_1);
        bool validity = abVerifier.verifySignature1155(alice, _collection, TOKEN_1, PHASE_1, generatedSignature);
        assertEq(validity, false);
    }

    function test_verifySignature1155_isInvalid_signer() public {
        vm.prank(abAdmin);
        abVerifier.setCollectionSigner(collection1, customSigner);

        bytes memory generatedSignature = _generateSignature1155(abSignerPkey, alice, collection2, TOKEN_1, PHASE_1);
        bool validity = abVerifier.verifySignature1155(alice, collection2, TOKEN_1, PHASE_0, generatedSignature);
        assertEq(validity, false);
    }

    function test_setDefaultSigner_correctRole() public {
        address defaultSigner = abVerifier.defaultSigner();
        assertEq(defaultSigner, abSigner);

        abVerifier.setDefaultSigner(customSigner);

        defaultSigner = abVerifier.defaultSigner();
        assertEq(defaultSigner, customSigner);
    }

    function test_setDefaultSigner_incorrectRole() public {
        vm.expectRevert();
        vm.prank(alice);
        abVerifier.setDefaultSigner(customSigner);
    }

    function test_setCollectionSigner_correctRole() public {
        address signerCollection1 = abVerifier.getSigner(collection1);
        assertEq(signerCollection1, abSigner);

        vm.prank(abAdmin);
        abVerifier.setCollectionSigner(collection1, customSigner);

        signerCollection1 = abVerifier.getSigner(collection1);
        assertEq(signerCollection1, customSigner);
    }

    function test_setCollectionSigner_incorrectRole() public {
        vm.expectRevert();
        vm.prank(bob);
        abVerifier.setCollectionSigner(collection1, customSigner);
    }

    function test_getSigner_defaultSigner() public {
        address signerCollection1 = abVerifier.getSigner(collection1);
        assertEq(signerCollection1, abSigner);
    }

    function test_getSigner_customSigner() public {
        vm.prank(abAdmin);
        abVerifier.setCollectionSigner(collection2, customSigner);
        address signerCollection2 = abVerifier.getSigner(collection2);
        assertEq(signerCollection2, customSigner);
    }

    /* ******************************************************************************************/
    /*                                    UTILITY FUNCTIONS                                     */
    /* ******************************************************************************************/

    function _generateSignature721(uint256 _signerPkey, address _user, address _collection, uint256 _phaseId)
        internal
        pure
        returns (bytes memory signature)
    {
        // Create signature for user `signFor` for drop ID `_dropId` and phase ID `_phaseId`
        bytes32 msgHash = keccak256(abi.encodePacked(_user, _collection, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPkey, msgHash);
        signature = abi.encodePacked(r, s, v);
    }

    function _generateSignature1155(
        uint256 _signerPkey,
        address _user,
        address _collection,
        uint256 _tokenId,
        uint256 _phaseId
    ) internal pure returns (bytes memory signature) {
        // Create signature for user `signFor` for drop ID `_dropId`, token ID `_tokenId` and phase ID `_phaseId`
        bytes32 msgHash = keccak256(abi.encodePacked(_user, _collection, _tokenId, _phaseId)).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerPkey, msgHash);
        signature = abi.encodePacked(r, s, v);
    }
}
