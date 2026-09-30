// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contributor: 1132dadf
// Runtime: Windows 11, x64, C:\Users\1, PowerShell

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AMMPool {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLP;
    mapping(address => uint256) public lpBalance;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        if (totalLP == 0) {
            // Fix: First depositor inflation attack protection
            // Mint 1e3 LP tokens to dead address to prevent price manipulation
            uint256 lp = amountA + amountB;
            totalLP = lp;
            lpBalance[msg.sender] = lp;
            // Burn first 1e3 tokens to dead address to prevent small first deposit attack
            lpBalance[deadAddress] = 1e3;
            totalLP += 1e3;
        } else {
            uint256 lpA = amountA * totalLP / reserveA;
            uint256 lpB = amountB * totalLP / reserveB;
            uint256 lp = lpA < lpB ? lpA : lpB;
            totalLP += lp;
            lpBalance[msg.sender] += lp;
        }

        reserveA += amountA;
        reserveB += amountB;
    }

    function swap(uint256 amountIn) external returns (uint256 amountOut) {
        // Constant product swap logic
        amountOut = reserveB * amountIn / (reserveA + amountIn);
        reserveA += amountIn;
        reserveB -= amountOut;
        IERC20(tokenB).transfer(msg.sender, amountOut);
    }
}
