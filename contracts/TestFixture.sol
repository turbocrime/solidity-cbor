// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../src/ReadCbor.sol";

/// @title TestFixture
/// @notice A small example contract fixture to confirm minimal function.
contract TestFixture {
    uint public unlockTime;
    address payable public owner;

    event ParsedBytes32(uint i, bytes32 item, uint8 len);

    constructor() payable {
        owner = payable(msg.sender);
    }

    using ReadCbor for bytes;
    function readThis(bytes calldata cbor) public {
        require(msg.sender == owner, "You aren't the owner");

        uint8 limit = 12;
        (uint i, bytes32 parsed, uint8 len) = cbor.Bytes32(0, limit);

        require(!(i > cbor.length), "TestFixture Must read within bounds of cbor");
        require(i == cbor.length, "TestFixture Must read entire cbor");

        emit ParsedBytes32(i, parsed, len);

        owner.transfer(address(this).balance);
    }
}
