// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ABDataRegistry} from "src/utils/ABDataRegistry.sol";
import {ABDataRegistryTestData} from "test/_testdata/ABDataRegistry.td.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ABDataRegistryTest is Test, ABDataRegistryTestData {
    /* Contracts */
    ABDataRegistry public abDataRegistry;

    function setUp() public {}

    function test_registerDrop_correctRole() public {}
    function test_registerDrop_incorrectRole() public {}

    function test_registerPublisher_correctRole() public {}
    function test_registerPublisher_incorrectRole() public {}

    function test_grantCollectionRole_correctRole() public {}
    function test_grantCollectionRole_incorrectRole() public {}

    function test_setAnotherCloneFactory_correctRole() public {}
    function test_setAnotherCloneFactory_incorrectRole() public {}

    function test_isPublisher() public {}
    function test_getRoyaltyContract() public {}
}
