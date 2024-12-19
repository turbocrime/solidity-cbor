// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {console, Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract IntTest is Test {
    // Test generic Int method
    function test_Int_zero() public pure {
        bytes memory cbor = hex"00";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
        assert(value == 0);
    }

    function test_Int_neg_one() public pure {
        bytes memory cbor = hex"20";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
        assert(value == -1);
    }

    function test_Int_uint16() public pure {
        bytes memory cbor = hex"19FFFF";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
        assert(value == 0xFFFF);
    }

    function test_Int_nint16() public pure {
        bytes memory cbor = hex"39FFFF";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
        assert(value == -1 - 0xFFFF);
    }

    function test_Int_max() public pure {
        bytes memory cbor = hex"1bffffffffffffffff";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
        assert(value == 0xFFFF_FFFF_FFFF_FFFF);
    }

    function test_Int_min() public pure {
        bytes memory cbor = hex"3bFFFFFFFFFFFFFFFF";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
        assert(value == -1 - 0xFFFF_FFFF_FFFF_FFFF);
    }

    function testFail_Int_not() public pure {
        bytes memory cbor = hex"f7";
        uint i;
        int value;
        (i, value) = cbor.Int(0);
    }
}
