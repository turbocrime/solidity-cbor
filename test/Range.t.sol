// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

/// @author turbocrime
contract RangeTest is Test {
    function test_requireRange() public pure {
        bytes memory cbor = hex"0102";
        cbor.requireRange(1); // Should succeed
        cbor.requireRange(2); // Should succeed at end
    }

    function testFail_requireRange() public pure {
        bytes memory cbor = hex"0102";
        cbor.requireRange(3); // Should fail - beyond end
    }

    function test_requireComplete() public pure {
        bytes memory cbor = hex"0102";
        cbor.requireComplete(2); // Should succeed - at end
    }

    function testFail_requireComplete() public pure {
        bytes memory cbor = hex"0102";
        cbor.requireComplete(1); // Should fail - not at end
    }
}
