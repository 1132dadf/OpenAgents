// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

contract Timelock {
    uint public constant MINIMUM_DELAY = 1 hours;
    uint public constant GRACE_PERIOD = 14 days;
    uint public delay;
    address public admin;

    mapping(bytes32 => bool) public queuedTransactions;

    event NewAdmin(address indexed newAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: admin only");
        _;
    }

    constructor(uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "Timelock: delay must exceed minimum delay");
        delay = delay_;
        admin = msg.sender;
    }

    function setDelay(uint delay_) public onlyAdmin {
        require(delay_ >= MINIMUM_DELAY, "Timelock: delay must exceed minimum delay");
        delay = delay_;
        emit NewDelay(delay);
    }

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public onlyAdmin returns (bytes32) {
        require(eta >= block.timestamp + delay, "Timelock: eta must be at least delay from now");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;
        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public onlyAdmin {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;
        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public onlyAdmin returns (bytes memory) {
        require(eta >= block.timestamp, "Timelock: transaction isn't ready");
        require(eta <= block.timestamp + GRACE_PERIOD, "Timelock: stale transaction");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock: unknown transaction");
        queuedTransactions[txHash] = false;

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock: transaction execution reverted");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);
        return returnData;
    }
}
