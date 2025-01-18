// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "../src/ReadCbor.sol";

contract TestHardhat {
    uint public unlockTime;
    address payable public owner;

    event ParsedBytes32(bytes32 item, uint when);

    constructor() payable {
        owner = payable(msg.sender);
    }

    using ReadCbor for bytes;
    function readThis(bytes calldata cbor) public {
        require(msg.sender == owner, "You aren't the owner");

        (uint i, bytes32 parsed, uint len ) = cbor.Bytes32(0);

        require(i == cbor.length, "Must read the entire cbor");
        require(len <= 32, "Must be less than 32 bytes");

        emit ParsedBytes32(parsed, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
