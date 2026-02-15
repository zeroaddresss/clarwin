// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title EpochRegistry — On-chain record of Clarwin evolutionary epochs
/// @notice Stretch goal: Records epoch hashes on Monad for transparency
contract EpochRegistry {
    struct Epoch {
        uint256 epochNumber;
        bytes32 populationHash;
        bytes32 fitnessHash;
        uint256 bestFitness;    // Scaled by 1e4 (e.g., 9200 = 0.92)
        uint256 meanFitness;    // Scaled by 1e4
        uint256 timestamp;
        string bestGenomeId;
    }

    address public immutable darwin;
    uint256 public epochCount;
    mapping(uint256 => Epoch) public epochs;

    event EpochRecorded(
        uint256 indexed epochNumber,
        bytes32 populationHash,
        bytes32 fitnessHash,
        uint256 bestFitness,
        string bestGenomeId
    );

    modifier onlyDarwin() {
        require(msg.sender == darwin, "Only Clarwin can record epochs");
        _;
    }

    constructor() {
        darwin = msg.sender;
    }

    function recordEpoch(
        bytes32 populationHash,
        bytes32 fitnessHash,
        uint256 bestFitness,
        uint256 meanFitness,
        string calldata bestGenomeId
    ) external onlyDarwin {
        epochCount++;
        epochs[epochCount] = Epoch({
            epochNumber: epochCount,
            populationHash: populationHash,
            fitnessHash: fitnessHash,
            bestFitness: bestFitness,
            meanFitness: meanFitness,
            timestamp: block.timestamp,
            bestGenomeId: bestGenomeId
        });

        emit EpochRecorded(epochCount, populationHash, fitnessHash, bestFitness, bestGenomeId);
    }

    function getEpoch(uint256 epochNumber) external view returns (Epoch memory) {
        require(epochNumber > 0 && epochNumber <= epochCount, "Invalid epoch");
        return epochs[epochNumber];
    }

    function getLatestEpoch() external view returns (Epoch memory) {
        require(epochCount > 0, "No epochs recorded");
        return epochs[epochCount];
    }
}
