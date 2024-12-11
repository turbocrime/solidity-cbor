// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../ReadCbor.sol";

library ReadBignum {
    using ReadCbor for bytes;

    uint8 internal constant TagUnsignedBignum = 0x02;
    uint8 internal constant TagNegativeBignum = 0x03;

    function UInt256(bytes memory cbor, uint32 i) internal pure returns (uint32 n, uint256 bn) {
        uint8 len;
        i = cbor.Tag(i, TagUnsignedBignum);
        (i, len) = cbor.header8(i, MajorBytes);
        require(len <= 32, "bignum too large");

        assembly ("memory-safe") {
            bn :=
                shr(
                    // Shift length within word
                    mul(sub(32, len), 8),
                    // Load bytes
                    mload(add(add(cbor, 0x20), i))
                )
            n := add(i, len)
        }
        require(n <= cbor.length);
    }

    function NInt256(bytes memory cbor, uint32 i) internal pure returns (uint32 n, int256 nbn) {
        uint8 len;
        i = cbor.Tag(i, TagNegativeBignum);
        (i, len) = cbor.header8(i, MajorBytes);
        require(len <= 32, "bignum too large");

        uint256 bn;
        assembly ("memory-safe") {
            bn :=
                shr(
                    // Shift length within word
                    mul(sub(32, len), 8),
                    // Load bytes
                    mload(add(add(cbor, 0x20), i))
                )
            n := add(i, len)
        }

        require(bn < uint256(type(int256).min), "int256 will overflow");
        nbn = -1 - int256(bn);
        require(n <= cbor.length);
    }

    function Int256(bytes memory cbor, uint32 i) internal pure returns (uint32 n, int256 ibn) {
        (, uint64 tag) = cbor.Tag(i);
        if (tag == TagUnsignedBignum) {
            uint256 ubn;
            (n, ubn) = UInt256(cbor, i);
            require(ubn <= uint256(type(int256).max), "int256 will overflow");
            ibn = int256(ubn);
        } else if (tag == TagNegativeBignum) {
            return NInt256(cbor, i);
        } else {
            revert("expected bignum tag");
        }
    }

    function Integer(bytes memory cbor, uint32 i) internal pure returns (uint32, int256) {
        return cbor.isTag(i) ? Int256(cbor, i) : cbor.Int(i);
    }
}
