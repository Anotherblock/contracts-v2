// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ABVerifier} from "src/utils/ABVerifier.sol";
import {ABVerifierTestData} from "test/_testdata/ABVerifier.td.sol";

contract ABVerifierTest is Test, ABVerifierTestData {
    /* Contracts */
    ABVerifier public abVerifier;

    function setUp() public {
        /* Contracts Deployments & Initialization */
        abVerifier = new ABVerifier(abSigner);
        vm.label(address(abVerifier), "abVerifier");
    }

    function test_verifySignature721_isValid() public {}
    function test_verifySignature721_isInvalid() public {}

    function test_verifySignature1155_isValid() public {}
    function test_verifySignature1155_isInvalid() public {}

    function test_setDefaultSigner_correctRole() public {}
    function test_setDefaultSigner_incorrectRole() public {}

    function test_setCollectionSigner_correctRole() public {}
    function test_setCollectionSigner_incorrectRole() public {}

    function test_getSigner_defaultSigner() public {}
    function test_getSigner_customSigner() public {}
}
