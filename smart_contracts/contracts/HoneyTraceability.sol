// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract HoneyTraceability is AccessControl {
    bytes32 public constant BEEKEEPER_ROLE = keccak256("BEEKEEPER_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant RETAILER_ROLE  = keccak256("RETAILER_ROLE");

    enum BatchState { Harvested, Processed, Packaged, InRetail, Sold }

    struct HoneyBatch {
        uint256 batchId;
        address beekeeper;
        address currentOwner;
        BatchState state;
        uint256 weight;           // in grams (weight_kg * 1000)
        string ipfsMetadataHash;
        uint256 timestamp;
    }

    struct StateCheckpoint {
        BatchState state;
        address actor;
        uint256 timestamp;
        string ipfsMetadataHash;
    }

    uint256 private _batchIdCounter;
    mapping(uint256 => HoneyBatch) private _batches;
    mapping(uint256 => StateCheckpoint[]) private _batchHistories;

    event BatchStateUpdated(
        uint256 indexed batchId,
        BatchState state,
        address actor,
        string ipfsHash
    );

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function registerBatch(
        uint256 weight,
        string calldata ipfsMetadataHash
    ) external onlyRole(BEEKEEPER_ROLE) returns (uint256) {
        _batchIdCounter++;
        uint256 newId = _batchIdCounter;

        _batches[newId] = HoneyBatch(
            newId, msg.sender, msg.sender,
            BatchState.Harvested, weight, ipfsMetadataHash, block.timestamp
        );
        _batchHistories[newId].push(StateCheckpoint(
            BatchState.Harvested, msg.sender, block.timestamp, ipfsMetadataHash
        ));

        emit BatchStateUpdated(newId, BatchState.Harvested, msg.sender, ipfsMetadataHash);
        return newId;
    }

    function processBatch(
        uint256 batchId,
        string calldata newIpfsHash
    ) external onlyRole(PROCESSOR_ROLE) {
        require(_batches[batchId].state == BatchState.Harvested, "Must be Harvested first");
        _batches[batchId].state = BatchState.Processed;
        _batches[batchId].currentOwner = msg.sender;
        _batches[batchId].ipfsMetadataHash = newIpfsHash;
        _batches[batchId].timestamp = block.timestamp;

        _batchHistories[batchId].push(StateCheckpoint(
            BatchState.Processed, msg.sender, block.timestamp, newIpfsHash
        ));
        emit BatchStateUpdated(batchId, BatchState.Processed, msg.sender, newIpfsHash);
    }

    function getBatchHistory(
        uint256 batchId
    ) external view returns (HoneyBatch memory, StateCheckpoint[] memory) {
        return (_batches[batchId], _batchHistories[batchId]);
    }

    function getTotalBatches() external view returns (uint256) {
        return _batchIdCounter;
    }
}
