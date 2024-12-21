// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

/**
 * @title Rewards for Co-Teaching Sessions
 * @notice This smart contract facilitates a reward system for co-teaching sessions. 
 * Teachers earn tokens for conducting and participating in collaborative teaching activities.
 */
contract CoTeachingRewards is ERC20, Ownable {
    struct CoTeachingSession {
        address[] participants; // List of participants in the session
        uint256 startTime;
        uint256 endTime;
        uint256 rewardAmount;
    }

    mapping(uint256 => CoTeachingSession) public sessions;
    uint256 public sessionCounter;
    uint256 public rewardRatePerMinute = 10 ether; // 10 tokens per minute

    event SessionCreated(uint256 sessionId, address[] participants, uint256 startTime);
    event SessionEnded(uint256 sessionId, uint256 endTime, uint256 rewardAmount);

    constructor() ERC20("CoTeachToken", "CTT") {
        _mint(msg.sender, 1000000 * (10 ** decimals())); // Mint initial token supply to contract owner
    }

    /**
     * @dev Create a new co-teaching session.
     * @param participants List of addresses participating in the session.
     */
    function createSession(address[] memory participants) external onlyOwner {
        require(participants.length > 1, "At least two participants required");

        sessions[sessionCounter] = CoTeachingSession({
            participants: participants,
            startTime: block.timestamp,
            endTime: 0,
            rewardAmount: 0
        });

        emit SessionCreated(sessionCounter, participants, block.timestamp);
        sessionCounter++;
    }

    /**
     * @dev End a co-teaching session and distribute rewards equally among participants.
     * @param sessionId ID of the session to end.
     */
    function endSession(uint256 sessionId) external onlyOwner {
        CoTeachingSession storage session = sessions[sessionId];
        require(session.startTime > 0, "Session does not exist");
        require(session.endTime == 0, "Session already ended");

        session.endTime = block.timestamp;
        uint256 durationInMinutes = (session.endTime - session.startTime) / 60;
        session.rewardAmount = durationInMinutes * rewardRatePerMinute;

        uint256 rewardPerParticipant = session.rewardAmount / session.participants.length;
        for (uint256 i = 0; i < session.participants.length; i++) {
            _mint(session.participants[i], rewardPerParticipant);
        }

        emit SessionEnded(sessionId, session.endTime, session.rewardAmount);
    }

    /**
     * @dev Update the reward rate (only owner can call this).
     * @param newRate New reward rate per minute in wei.
     */
    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerMinute = newRate;
    }
}
