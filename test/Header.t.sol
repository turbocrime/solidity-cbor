// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import "../src/ReadCbor.sol";

using ReadCbor for bytes;

contract HeaderTest is Test {
    function test_header() public pure {
        bytes memory cbor = hex"69616361622031333132";
        (uint i, uint64 arg, uint8 major) = cbor.header(0);
        assert(i == 1);
        assert(arg == 9);
        assert(major == MajorText);
    }

    function testRevert_parseArg_unsupportedMinor(uint8 minor) public {
        vm.assume(minor < 32);
        vm.assume(minor > MinorExtendU64);
        bytes memory cbor = abi.encodePacked(
            ((uint8(MajorUnsigned) << shiftMajor) | minor)
        );
        vm.expectRevert();
        (uint i, uint64 arg, uint8 major) = cbor.header(0);
        assert(i == 1);
        assert(arg > 0);
        assert(major == MajorUnsigned);
    }

    function testRevert_header_expectMajor() public {
        bytes memory cbor = hex"00";
        vm.expectRevert();
        cbor.header(0, 1);
    }

    function testRevert_header_expectMinor_failmajor() public {
        bytes memory cbor = hex"00";
        vm.expectRevert();
        cbor.header(0, 1, 0);
    }

    function testRevert_header_badext() public {
        bytes memory cbor = abi.encodePacked(
            ((uint8(MajorUnsigned) << shiftMajor) | MinorExtendU8),
            uint8(0x00)
        );
        vm.expectRevert();
        cbor.header(0);
    }

    function testRevert_header8_expectMajor() public {
        bytes memory cbor = hex"00";
        vm.expectRevert();
        cbor.header8(0, 1);
    }

    function testRevert_header32_badu8() public {
        bytes memory cbor = abi.encodePacked(
            ((uint8(MajorUnsigned) << shiftMajor) | MinorExtendU8),
            uint8(0x00)
        );
        vm.expectRevert();
        (uint i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        assert(i == cbor.length);
        assert(arg == 0x00);
    }

    function test_header32_u16() public pure {
        bytes memory cbor = abi.encodePacked(
            ((uint8(MajorUnsigned) << shiftMajor) | MinorExtendU16),
            uint16(0xFFFF)
        );
        (uint i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        assert(i == cbor.length);
        assert(arg == 0xFFFF);
    }

    function test_header32_u32() public pure {
        bytes memory cbor = abi.encodePacked(
            ((uint8(MajorUnsigned) << shiftMajor) | MinorExtendU32),
            uint32(0xFFFF1234)
        );
        (uint i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        assert(i == cbor.length);
        assert(arg == 0xFFFF1234);
    }

    function testRevert_header32_u64() public {
        bytes memory cbor = abi.encodePacked(
            ((uint8(MajorUnsigned) << shiftMajor) | MinorExtendU64),
            uint64(0xFFFF12345678)
        );
        vm.expectRevert();
        (uint i, uint32 arg) = cbor.header32(0, MajorUnsigned);
        assert(i == cbor.length);
        assert(arg == 0xFFFF12345678);
    }
}
