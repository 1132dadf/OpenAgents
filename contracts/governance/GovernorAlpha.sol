// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contributor: 1132dadf
// Runtime: Windows 11, x64, C:\Users\1, PowerShell

contract GovernorAlpha {
    struct Proposal {
        uint256 id;
        address proposer;
        bool executed;
    }

    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => Proposal) public proposals;

    function vote(uint256 proposalId, bool support) external {
        // Fix: use msg.sender instead of tx.origin to prevent phishing attacks
        // Attacker can trick a user into signing a tx that calls attacker contract,
        // which then calls this vote function - tx.origin would be the user,
        // allowing attacker to vote on behalf of the user without their consent
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(proposals[proposalId].proposer != address(0), "Proposal does not exist");

        hasVoted[proposalId][msg.sender] = true;
    }
}
