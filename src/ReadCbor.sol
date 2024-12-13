// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

uint8 constant maskMinor = 0x1f; // 0b0001_1111;
uint8 constant shiftMajor = 5;

uint8 constant MajorUnsigned = 0;
uint8 constant MajorNegative = 1;
uint8 constant MajorBytes = 2;
uint8 constant MajorText = 3;
uint8 constant MajorArray = 4;
uint8 constant MajorMap = 5;
uint8 constant MajorTag = 6;
uint8 constant MajorPrimitive = 7;

uint8 constant MinorExtendU8 = 0x17 + 1; // 24
uint8 constant MinorExtendU16 = 0x17 + 2; // 25
uint8 constant MinorExtendU32 = 0x17 + 3; // 26
uint8 constant MinorExtendU64 = 0x17 + 4; // 27

uint8 constant SimpleFalse = 0x14;
uint8 constant SimpleTrue = 0x15;
uint8 constant SimpleNull = 0x16;
uint8 constant SimpleUndefined = 0x17;

library ReadCbor {
    /// @notice Parses a header type argument based on the minor type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current (header) index in the byte array
    /// @param minor The minor bits from the header byte
    /// @return n The new index
    /// @return arg The parsed argument value
    function parseArg(bytes memory cbor, uint i, uint8 minor) private pure returns (uint n, uint64 arg) {
        if (minor < MinorExtendU8) {
            (n, arg) = (i, minor);
        } else if (minor == MinorExtendU8) {
            (n, arg) = u8(cbor, i);
            require(arg >= MinorExtendU8, "invalid type argument (single-byte value too low)");
        } else if (minor == MinorExtendU16) {
            (n, arg) = u16(cbor, i);
        } else if (minor == MinorExtendU32) {
            (n, arg) = u32(cbor, i);
        } else if (minor == MinorExtendU64) {
            (n, arg) = u64(cbor, i);
        } else {
            revert("minor unsupported");
        }
    }

    function u8(bytes memory cbor, uint i) private pure returns (uint n, uint8 ret) {
        assembly ("memory-safe") {
            // Load 1 bytes directly into value starting at position i
            ret := shr(248, mload(add(add(cbor, 0x20), i))) // 248 = 256 - (8 bits)
            n := add(i, 1)
        }
    }

    function u16(bytes memory cbor, uint i) private pure returns (uint n, uint16 ret) {
        assembly ("memory-safe") {
            // Load 2 bytes directly into value starting at position i
            ret := shr(240, mload(add(add(cbor, 0x20), i))) // 240 = 256 - (16 bits)
            n := add(i, 2)
        }
    }

    function u32(bytes memory cbor, uint i) private pure returns (uint n, uint32 ret) {
        assembly ("memory-safe") {
            // Load 4 bytes directly into value starting at position i
            ret := shr(224, mload(add(add(cbor, 0x20), i))) // 224 = 256 - (32 bits)
            n := add(i, 4)
        }
    }

    function u64(bytes memory cbor, uint i) private pure returns (uint n, uint64 ret) {
        assembly ("memory-safe") {
            // Load 8 bytes directly into value starting at position i
            ret := shr(192, mload(add(add(cbor, 0x20), i))) // 192 = 256 - (64 bits)
            n := add(i, 8)
        }
    }

    /// @notice Reads a CBOR header, and possibly header extension
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return arg The type argument
    /// @return major The major type
    function header(bytes memory cbor, uint i) internal pure returns (uint n, uint64 arg, uint8 major) {
        uint8 h;
        (n, h) = u8(cbor, i);
        major = h >> shiftMajor;
        uint8 minor = h & maskMinor;
        (n, arg) = parseArg(cbor, n, minor);
    }

    /// @notice Reads a CBOR header with an expected major type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @return n The new index
    /// @return arg The argument value
    /// @dev Reverts if major type doesn't match expected
    function header(bytes memory cbor, uint i, uint8 expectMajor) internal pure returns (uint n, uint64 arg) {
        uint8 h;
        (n, h) = u8(cbor, i);
        require(h >> shiftMajor == expectMajor, "unexpected major type");
        (n, arg) = parseArg(cbor, n, h & maskMinor);
    }

    /// @notice Reads a CBOR header with expected major and minor types
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @param expectMinor The expected minor type
    /// @return n The new index
    /// @return arg The argument value
    /// @dev Reverts if major or minor types don't match expected
    function header(bytes memory cbor, uint i, uint8 expectMajor, uint8 expectMinor)
        internal
        pure
        returns (uint n, uint64 arg)
    {
        uint8 h;
        (n, h) = u8(cbor, i);
        uint8 major = h >> shiftMajor;
        require(major == expectMajor, "unexpected major type");
        uint8 minor = h & maskMinor;
        require(minor == expectMinor, "unexpected minor type");
        (n, arg) = parseArg(cbor, n, minor);
    }

    /// @notice Optimized header reading for uint8 type arguments of an expected major type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @return n The new index
    /// @return arg The argument value
    /// @dev For u8 type arguments only (literal minor or 1-byte extended)
    function header8(bytes memory cbor, uint i, uint8 expectMajor) internal pure returns (uint n, uint8 arg) {
        uint8 major;

        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))
            major := shr(shiftMajor, h)
            arg := and(h, maskMinor)
            i := add(i, 1)
        }

        require(major == expectMajor, "unexpected major type");

        if (arg >= MinorExtendU8) {
            require(arg == MinorExtendU8, "unexpected minor type");
            assembly ("memory-safe") {
                arg := shr(248, mload(add(add(cbor, 0x20), i)))
                i := add(i, 1)
            }
            require(arg >= MinorExtendU8, "invalid extended header");
        }

        n = i;
    }

    /// @notice Optimized header reading for uint32 type arguments of an expected major type
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectMajor The expected major type
    /// @return n The new index
    /// @return arg The argument value
    /// @dev For type arguments expected to specify a length, uint is sufficient
    function header32(bytes memory cbor, uint i, uint8 expectMajor) internal pure returns (uint n, uint32 arg) {
        uint8 major;

        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))
            major := shr(shiftMajor, h)
            arg := and(h, maskMinor) // minor literal arg
            i := add(i, 1)
        }

        require(major == expectMajor, "unexpected major type");

        if (arg == MinorExtendU8) {
            assembly ("memory-safe") {
                arg := shr(248, mload(add(add(cbor, 0x20), i)))
                i := add(i, 1)
            }
            require(arg >= MinorExtendU8, "invalid extended header");
        } else if (arg >= MinorExtendU8) {
            require(arg <= MinorExtendU32, "unexpected minor type");
            if (arg == MinorExtendU16) {
                assembly ("memory-safe") {
                    arg := shr(240, mload(add(add(cbor, 0x20), i)))
                    i := add(i, 2)
                }
            } else if (arg == MinorExtendU32) {
                assembly ("memory-safe") {
                    arg := shr(224, mload(add(add(cbor, 0x20), i)))
                    i := add(i, 4)
                }
            }
        }

        n = i;
    }

    /// @notice Checks if the next item is null
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is null
    function isNull(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(byte(0, mload(add(add(cbor, 0x20), i))), or(shl(shiftMajor, MajorPrimitive), SimpleNull))
        }
    }

    /// @notice Reads a null item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @dev Reverts if item is not null
    function Null(bytes memory cbor, uint i) internal pure returns (uint n) {
        require(isNull(cbor, i), "expected null");
        n = i + 1;
    }

    /// @notice Checks if the next item is undefined
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is undefined
    function isUndefined(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(byte(0, mload(add(add(cbor, 0x20), i))), or(shl(shiftMajor, MajorPrimitive), SimpleUndefined))
        }
    }

    /// @notice Reads an undefined item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @dev Reverts if item is not undefined
    function Undefined(bytes memory cbor, uint i) internal pure returns (uint n) {
        require(isUndefined(cbor, i), "expected undefined");
        n = i + 1;
    }

    /// @notice Checks if the next item is a boolean
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a boolean
    function isBool(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            let h := byte(0, mload(add(add(cbor, 0x20), i)))
            indeed :=
                or(
                    eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleTrue)),
                    eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleFalse))
                )
        }
    }

    /// @notice Reads a boolean item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return isTrue The boolean value
    /// @dev Reverts if item is not a boolean
    function Bool(bytes memory cbor, uint i) internal pure returns (uint n, bool isTrue) {
        bool isFalse;
        assembly ("memory-safe") {
            let h := byte(0, mload(add(add(cbor, 0x20), i)))
            isTrue := eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleTrue))
            isFalse := eq(h, or(shl(shiftMajor, MajorPrimitive), SimpleFalse))
            n := add(i, 1)
        }
        require(isFalse || isTrue, "expected boolean");
    }

    /// @notice Checks if the next item is an array
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is an array
    function isArray(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorArray)
        }
    }

    /// @notice Reads an array header and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return len The number of items in the array
    function Array(bytes memory cbor, uint i) internal pure returns (uint, uint32) {
        // An array of data items. The argument is the number of data items in the
        // array. Items in an array do not need to all be of the same type.
        return header32(cbor, i, MajorArray);
    }

    /// @notice Checks if the next item is a map
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a map
    function isMap(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorMap)
        }
    }

    /// @notice Reads a map header and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return len The number of key-value pairs in the map
    function Map(bytes memory cbor, uint i) internal pure returns (uint, uint32) {
        // A map is comprised of pairs of data items, each pair consisting of a key
        // that is immediately followed by a value. The argument is the number of
        // pairs of data items in the map.
        return header32(cbor, i, MajorMap);
    }

    /// @notice Checks if the next item is a string
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a string
    function isString(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorText)
        }
    }

    /// @notice Reads a string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return str The string value
    function String(bytes memory cbor, uint i) internal pure returns (uint n, string memory str) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorText);

        str = new string(len);
        assembly ("memory-safe") {
            let src := add(cbor, add(0x20, i))
            let dest := add(str, 0x20)
            mcopy(dest, src, len)
            n := add(i, len)
        }
    }

    /// @notice Reads a string item into a bytes32 and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param maxLen The maximum allowed string length, which must be <= 32
    /// @return n The new index
    /// @return str The bytes32 value
    /// @return len The string length
    /// @dev Reverts if string length exceeds maxLen
    function String32(bytes memory cbor, uint i, uint8 maxLen) internal pure returns (uint n, bytes32 str, uint8 len) {
        assert(maxLen <= 32);
        (i, len) = header8(cbor, i, MajorText);
        require(len <= maxLen);

        assembly ("memory-safe") {
            str := mload(add(cbor, add(0x20, i)))
            str := and(str, not(shr(mul(len, 8), not(0))))
            n := add(i, len)
        }
    }

    function String32(bytes memory cbor, uint i) internal pure returns (uint, bytes32, uint8) {
        return String32(cbor, i, 32);
    }

    /// @notice Reads a single-byte string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return s The single-byte value
    /// @dev Reverts if string length is not exactly 1
    function String1(bytes memory cbor, uint i) internal pure returns (uint n, bytes1 s) {
        bool validItemType;
        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i))) // load header byte
            validItemType := eq(h, or(shl(shiftMajor, MajorText), 1))
            s := mload(add(add(add(cbor, 0x20), i), 1)) // load string byte
            n := add(i, 2)
        }
        require(validItemType, "expected single-byte string");
    }

    /// @notice Skips a string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index after the string
    function skipString(bytes memory cbor, uint i) internal pure returns (uint n) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorText);
        n = i + len;
    }

    /// @notice Checks if the next item is a byte string
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a byte string
    function isBytes(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorBytes)
        }
    }

    /// @notice Reads a byte string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return bts The byte string value
    function Bytes(bytes memory cbor, uint i) internal pure returns (uint n, bytes memory bts) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorBytes);

        bts = new bytes(len);
        assembly ("memory-safe") {
            let src := add(cbor, add(0x20, i))
            let dest := add(bts, 0x20)
            mcopy(dest, src, len)
            n := add(i, len)
        }
    }

    /// @notice Reads a byte string item into a bytes32 and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param maxLen The maximum allowed byte string length, which must be <= 32
    /// @return n The new index
    /// @return bts The bytes32 value
    /// @return len The byte string length
    /// @dev Reverts if byte string length exceeds maxLen
    function Bytes32(bytes memory cbor, uint i, uint8 maxLen) internal pure returns (uint n, bytes32 bts, uint8 len) {
        assert(maxLen <= 32);
        (i, len) = header8(cbor, i, MajorBytes);
        require(len <= maxLen);

        assembly ("memory-safe") {
            bts := mload(add(cbor, add(0x20, i)))
            bts := and(bts, not(shr(mul(len, 8), not(0))))
            n := add(i, len)
        }
    }

    function Bytes32(bytes memory cbor, uint i) internal pure returns (uint, bytes32, uint8) {
        return Bytes32(cbor, i, 32);
    }

    /// @notice Skips a byte string item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index after the byte string
    function skipBytes(bytes memory cbor, uint i) internal pure returns (uint n) {
        uint32 len;
        (i, len) = header32(cbor, i, MajorBytes);
        n = i + len;
    }

    /// @notice Checks if the next item is a tag
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a tag
    function isTag(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorTag)
        }
    }

    /// @notice Checks if the next item is a specific tag
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectTag The expected tag value
    /// @return indeed the next item is the expected tag
    function isTag(bytes memory cbor, uint i, uint64 expectTag) internal pure returns (bool indeed) {
        uint64 arg;
        assembly ("memory-safe") {
            let h := shr(248, mload(add(add(cbor, 0x20), i)))

            if eq(shr(shiftMajor, h), MajorTag) {
                arg := and(h, maskMinor)
                i := add(i, 1)
                if gt(arg, 0x17) {
                    switch arg
                    case 0x18 { arg := shr(248, mload(add(add(cbor, 0x20), i))) }
                    case 0x19 { arg := shr(240, mload(add(add(cbor, 0x20), i))) }
                    case 0x1a { arg := shr(224, mload(add(add(cbor, 0x20), i))) }
                    case 0x1b { arg := shr(192, mload(add(add(cbor, 0x20), i))) }
                    default { arg := not(expectTag) }
                }

                indeed := eq(arg, expectTag)
            }
        }
    }

    /// @notice Reads a tag item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return tag The tag value
    function Tag(bytes memory cbor, uint i) internal pure returns (uint, uint64) {
        return header(cbor, i, MajorTag);
    }

    /// @notice Reads a specific tag item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @param expectTag The expected tag value
    /// @return n The new index
    /// @dev Reverts if tag doesn't match expected value
    function Tag(bytes memory cbor, uint i, uint64 expectTag) internal pure returns (uint) {
        (uint n, uint64 tag) = header(cbor, i, MajorTag);
        require(tag == expectTag, "unexpected tag");
        return n;
    }

    /// @notice Checks if the next item is an unsigned (positive) integer
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is an unsigned integer
    function isUInt(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorUnsigned)
        }
    }

    /// @notice Reads an unsigned integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return arg The unsigned integer value
    function UInt(bytes memory cbor, uint i) internal pure returns (uint, uint64) {
        return header(cbor, i, MajorUnsigned);
    }

    /// @notice Reads a uint8 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return arg The uint8 value
    function UInt8(bytes memory cbor, uint i) internal pure returns (uint n, uint8 arg) {
        return header8(cbor, i, MajorUnsigned);
    }

    /// @notice Reads a uint16 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return arg The uint16 value
    function UInt16(bytes memory cbor, uint i) internal pure returns (uint n, uint16 arg) {
        uint64 arg64;
        (n, arg64) = header(cbor, i, MajorUnsigned, MinorExtendU16);
        arg = uint16(arg64);
    }

    /// @notice Reads a uint32 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return arg The uint32 value
    function UInt32(bytes memory cbor, uint i) internal pure returns (uint n, uint32 arg) {
        uint64 arg64;
        (n, arg64) = header(cbor, i, MajorUnsigned, MinorExtendU32);
        arg = uint32(arg64);
    }

    /// @notice Reads a uint64 item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return arg The uint64 value
    function UInt64(bytes memory cbor, uint i) internal pure returns (uint, uint64) {
        return header(cbor, i, MajorUnsigned, MinorExtendU64);
    }

    /// @notice Checks if the next item is a negative integer
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is a negative integer
    function isNInt(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            indeed := eq(shr(253, mload(add(add(cbor, 0x20), i))), MajorNegative)
        }
    }

    /// @notice Reads a negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return neg A signed int72 value
    function NInt(bytes memory cbor, uint i) internal pure returns (uint n, int72 neg) {
        uint64 arg;
        (n, arg) = header(cbor, i, MajorNegative);
        neg = -1 - int72(uint72(arg));
    }

    /// @notice Reads an 8-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return neg A signed int16 value
    function NInt8(bytes memory cbor, uint i) internal pure returns (uint n, int16 neg) {
        uint8 arg;
        (n, arg) = header8(cbor, i, MajorNegative);
        neg = -1 - int16(uint16(arg));
    }

    /// @notice Reads a 16-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return neg A signed int24 value
    function NInt16(bytes memory cbor, uint i) internal pure returns (uint n, int24 neg) {
        uint64 arg;
        (n, arg) = header(cbor, i, MajorNegative, MinorExtendU16);
        neg = -1 - int24(uint24(arg));
    }

    /// @notice Reads a 32-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return neg A signed int40 value
    function NInt32(bytes memory cbor, uint i) internal pure returns (uint n, int40 neg) {
        uint64 arg;
        (n, arg) = header(cbor, i, MajorNegative, MinorExtendU32);
        neg = -1 - int40(uint40(arg));
    }

    /// @notice Reads a 64-bit negative integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return neg A signed int72 value
    function NInt64(bytes memory cbor, uint i) internal pure returns (uint n, int72 neg) {
        uint64 arg;
        (n, arg) = header(cbor, i, MajorNegative, MinorExtendU64);
        neg = -1 - int72(uint72(arg));
    }

    /// @notice Checks if the next item is any integer (positive or negative)
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return indeed the next item is any integer
    function isInt(bytes memory cbor, uint i) internal pure returns (bool indeed) {
        assembly ("memory-safe") {
            let major := shr(253, mload(add(add(cbor, 0x20), i)))
            indeed := or(eq(major, MajorUnsigned), eq(major, MajorNegative))
        }
    }

    /// @notice Reads any integer item and advances the index
    /// @param cbor The CBOR-encoded bytes
    /// @param i The current index
    /// @return n The new index
    /// @return integer A signed integer value
    function Int(bytes memory cbor, uint i) internal pure returns (uint n, int72 integer) {
        uint8 major;
        uint64 arg;
        (n, arg, major) = header(cbor, i);
        if (major == MajorUnsigned) {
            integer = int72(uint72(arg));
        } else if (major == MajorNegative) {
            integer = -1 - int72(uint72(arg));
        } else {
            revert("unexpected major type");
        }
    }
}
