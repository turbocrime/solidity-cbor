// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract PeekTest is Test {
    bytes private constant unsignedCbor = hex"00";
    bytes private constant negativeCbor = hex"20";
    bytes private constant bytesCbor = hex"40";
    bytes private constant textCbor = hex"60";
    bytes private constant arrayCbor = hex"80";
    bytes private constant mapCbor = hex"a0";
    bytes private constant tagCbor = hex"c0";
    bytes private constant falseCbor = hex"f4";
    bytes private constant nullCbor = hex"f6";
    bytes private constant trueCbor = hex"f5";
    bytes private constant undefinedCbor = hex"f7";

    function test_isArray_false() public pure {
        assert(!mapCbor.isArray(0));
    }

    function test_isArray_true() public pure {
        assert(arrayCbor.isArray(0));
    }

    function test_isBool_false() public pure {
        assert(!undefinedCbor.isBool(0));
    }

    function test_isBool_true() public pure {
        assert(falseCbor.isBool(0));
        assert(trueCbor.isBool(0));
    }

    function test_isBytes_false() public pure {
        assert(!textCbor.isBytes(0));
    }

    function test_isBytes_true() public pure {
        assert(bytesCbor.isBytes(0));
    }

    function test_isInt_false() public pure {
        assert(!nullCbor.isInt(0));
    }

    function test_isInt_true() public pure {
        assert(unsignedCbor.isInt(0));
        assert(negativeCbor.isInt(0));
    }

    function test_isMap_false() public pure {
        assert(!arrayCbor.isMap(0));
    }

    function test_isMap_true() public pure {
        assert(mapCbor.isMap(0));
    }

    function test_isNInt_false() public pure {
        assert(!unsignedCbor.isNInt(0));
    }

    function test_isNInt_true() public pure {
        assert(negativeCbor.isNInt(0));
    }

    function test_isNull_false() public pure {
        assert(!unsignedCbor.isNull(0));
    }

    function test_isNull_true() public pure {
        assert(nullCbor.isNull(0));
    }

    function test_isString_false() public pure {
        assert(!bytesCbor.isString(0));
    }

    function test_isString_true() public pure {
        assert(textCbor.isString(0));
    }

    function test_isTag_expect_false() public pure {
        assert(!tagCbor.isTag(0, 1));
    }

    function test_isTag_expect_true() public pure {
        assert(tagCbor.isTag(0, 0));
    }

    function test_isTag_expect_rand_64(uint64 rand64) public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | MinorExtendU64), bytes8(rand64));
        assert(cbor.isTag(0, uint64(rand64)));
    }

    function test_isTag_expect_rand_64(uint32 rand32) public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | MinorExtendU32), bytes4(rand32));
        assert(cbor.isTag(0, uint32(rand32)));
    }

    function test_isTag_expect_rand_16(uint16 rand16) public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | MinorExtendU16), bytes2(rand16));
        assert(cbor.isTag(0, uint16(rand16)));
    }

    function test_isTag_expect_badminor() public pure {
        bytes memory cbor = bytes.concat(bytes1(MajorTag << shiftMajor | (MinorExtendU64 + 1)));
        assert(!cbor.isTag(0, MinorExtendU64 + 1));
    }

    function test_isTag_false() public pure {
        assert(!arrayCbor.isTag(0));
    }

    function test_isTag_false_expect() public pure {
        assert(!arrayCbor.isTag(0, 0));
    }

    function test_isTag_true() public pure {
        assert(tagCbor.isTag(0));
    }

    function test_isUInt_false() public pure {
        assert(!negativeCbor.isUInt(0));
    }

    function test_isUInt_true() public pure {
        assert(unsignedCbor.isUInt(0));
    }

    function test_isUndefined_false() public pure {
        assert(!unsignedCbor.isUndefined(0));
    }

    function test_isUndefined_true() public pure {
        assert(undefinedCbor.isUndefined(0));
    }
}
