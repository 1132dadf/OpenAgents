// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contributor: 1132dadf
// Runtime: Windows 11, x64, C:\Users\1, PowerShell

contract MultiTokenStaking {
    mapping(address => mapping(address => uint256)) public stakedBalances;

    function stake(address token, uint256 amount) external {
        stakedBalances[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        require(stakedBalances[msg.sender][token] >= amount, "Insufficient balance");
        stakedBalances[msg.sender][token] -= amount;
    }

    // Fix: add emergency withdraw function to let users recover funds when contract is in emergency
    function emergencyWithdraw(address token) external {
        uint256 balance = stakedBalances[msg.sender][token];
        require(balance > 0, "No balance to withdraw");

        // Zero balance BEFORE transfer to prevent reentrancy
        stakedBalances[msg.sender][token] = 0;

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}
