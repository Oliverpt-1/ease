// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/ILayerZeroEndpoint.sol";

contract CrossChainAssigner {
    struct Assignment {
        address user;
        string username;
        bytes32 facialHash;
        uint16[] targetChains;
        bool executed;
        uint256 timestamp;
    }

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(bytes32 => Assignment) public assignments;
    mapping(address => bytes32[]) public userAssignments;

    event AssignmentCreated(bytes32 indexed assignmentId, address indexed user, uint16[] targetChains);
    event AssignmentExecuted(bytes32 indexed assignmentId, uint16 chainId);

    constructor(address _lzEndpoint) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function createAssignment(
        address user,
        string calldata username,
        bytes32 facialHash,
        uint16[] calldata targetChains
    ) external payable returns (bytes32 assignmentId) {
        assignmentId = keccak256(abi.encodePacked(
            user, username, facialHash, block.timestamp
        ));

        assignments[assignmentId] = Assignment({
            user: user,
            username: username,
            facialHash: facialHash,
            targetChains: targetChains,
            executed: false,
            timestamp: block.timestamp
        });

        userAssignments[user].push(assignmentId);

        emit AssignmentCreated(assignmentId, user, targetChains);
    }

    function executeAssignment(bytes32 assignmentId) external payable {
        Assignment storage assignment = assignments[assignmentId];
        require(assignment.user != address(0), "Assignment not found");
        require(!assignment.executed, "Already executed");

        bytes memory payload = abi.encode(
            assignment.user,
            assignment.username,
            assignment.facialHash
        );

        for (uint256 i = 0; i < assignment.targetChains.length; i++) {
            uint16 chainId = assignment.targetChains[i];
            
            (uint256 nativeFee,) = lzEndpoint.estimateFees(
                chainId,
                address(this),
                payload,
                false,
                bytes("")
            );

            require(msg.value >= nativeFee, "Insufficient fee");

            lzEndpoint.send{value: nativeFee}(
                chainId,
                trustedRemoteLookup[chainId],
                payload,
                payable(msg.sender),
                address(0),
                bytes("")
            );

            emit AssignmentExecuted(assignmentId, chainId);
        }

        assignment.executed = true;
    }

    function getAssignment(bytes32 assignmentId) external view returns (Assignment memory) {
        return assignments[assignmentId];
    }

    function getUserAssignments(address user) external view returns (bytes32[] memory) {
        return userAssignments[user];
    }

    function estimateExecutionFee(bytes32 assignmentId) external view returns (uint256 totalFee) {
        Assignment storage assignment = assignments[assignmentId];
        require(assignment.user != address(0), "Assignment not found");

        bytes memory payload = abi.encode(
            assignment.user,
            assignment.username,
            assignment.facialHash
        );

        for (uint256 i = 0; i < assignment.targetChains.length; i++) {
            (uint256 nativeFee,) = lzEndpoint.estimateFees(
                assignment.targetChains[i],
                address(this),
                payload,
                false,
                bytes("")
            );
            totalFee += nativeFee;
        }
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _path) external {
        trustedRemoteLookup[_chainId] = _path;
    }
}