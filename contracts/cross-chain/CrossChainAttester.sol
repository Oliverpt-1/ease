// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/ILayerZeroEndpoint.sol";

contract CrossChainAttester is ILayerZeroReceiver {
    struct Attestation {
        address user;
        bytes32 facialHash;
        string username;
        uint256 timestamp;
        bool verified;
    }

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(bytes32 => Attestation) public attestations;
    mapping(address => bytes32[]) public userAttestations;

    event AttestationCreated(bytes32 indexed attestationId, address indexed user, uint16 srcChain);
    event AttestationVerified(bytes32 indexed attestationId, address indexed user);

    modifier onlyEndpoint() {
        require(msg.sender == address(lzEndpoint), "Unauthorized endpoint");
        _;
    }

    constructor(address _lzEndpoint) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64,
        bytes calldata _payload
    ) external override onlyEndpoint {
        require(
            keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]),
            "Untrusted source"
        );

        (address user, bytes32 facialHash, string memory username) = abi.decode(
            _payload,
            (address, bytes32, string)
        );

        bytes32 attestationId = keccak256(abi.encodePacked(
            user, facialHash, username, _srcChainId, block.timestamp
        ));

        attestations[attestationId] = Attestation({
            user: user,
            facialHash: facialHash,
            username: username,
            timestamp: block.timestamp,
            verified: false
        });

        userAttestations[user].push(attestationId);

        emit AttestationCreated(attestationId, user, _srcChainId);
    }

    function verifyAttestation(bytes32 attestationId) external {
        require(attestations[attestationId].user != address(0), "Attestation not found");
        require(!attestations[attestationId].verified, "Already verified");
        
        attestations[attestationId].verified = true;
        
        emit AttestationVerified(attestationId, attestations[attestationId].user);
    }

    function getAttestation(bytes32 attestationId) external view returns (Attestation memory) {
        return attestations[attestationId];
    }

    function getUserAttestations(address user) external view returns (bytes32[] memory) {
        return userAttestations[user];
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _path) external {
        trustedRemoteLookup[_chainId] = _path;
    }
}