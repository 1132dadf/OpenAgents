// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Contributor: 1132dadf
// Runtime: Windows 11, x64, C:\Users\1, PowerShell

contract StakingRewards is ReentrancyGuard {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public rewards;
    uint256 public totalStaked;

    function stake() external payable nonReentrant {
        balances[msg.sender] += msg.value;
        totalStaked += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Checks-Effects-Interactions: update state FIRST before external call
        balances[msg.sender] -= amount;
        totalStaked -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function claimRewards() external nonReentrant {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        // Checks-Effects-Interactions: zero rewards FIRST before external call
        rewards[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed");
    }
}
