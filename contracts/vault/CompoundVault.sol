// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contributor: 1132dadf
// Runtime: Windows 11, x64, C:\Users\1, PowerShell

contract CompoundVault {
    uint256 public rewardEndTime;
    uint256 public rewardRate;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        // Fix: stop accruing rewards after reward period ends
        if (block.timestamp < rewardEndTime) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // Fix: cap the time delta at rewardEndTime to prevent phantom rewards after expiry
        uint256 timeElapsed = block.timestamp < rewardEndTime 
            ? block.timestamp 
            : rewardEndTime;
        return rewardPerTokenStored + (rewardRate * timeElapsed * 1e18 / totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return (balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        balances[msg.sender] += amount;
        totalSupply += amount;
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        balances[msg.sender] -= amount;
        totalSupply -= amount;
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed");
    }
}
