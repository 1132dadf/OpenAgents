// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contributor: 1132dadf
// Runtime: Windows 11, x64, C:\Users\1, PowerShell

contract TokenBridge {
    address public validator;
    // Fix: track used transaction hashes to prevent cross-chain replay attacks
    mapping(bytes32 => bool) public usedTransactions;

    event TokensReleased(address to, uint256 amount, bytes32 txHash);

    function releaseTokens(
        address to,
        uint256 amount,
        bytes32 sourceTxHash,
        bytes calldata signature
    ) external {
        // Fix: reject if this transaction was already used (replay protection)
        require(!usedTransactions[sourceTxHash], "Transaction already executed");

        // Verify validator signature
        bytes32 messageHash = keccak256(abi.encodePacked(to, amount, sourceTxHash, block.chainid));
        require(isValidSignature(messageHash, signature), "Invalid signature");

        // Mark transaction as used BEFORE transferring tokens
        usedTransactions[sourceTxHash] = true;

        // Transfer tokens to user
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");

        emit TokensReleased(to, amount, sourceTxHash);
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s) == validator;
    }

    function splitSignature(bytes calldata sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
