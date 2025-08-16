// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/ILayerZeroEndpoint.sol";

interface ICCIPGateway {
    function request(
        bytes32 requestId,
        bytes calldata data,
        address callbackAddress,
        bytes4 callbackSelector
    ) external;
}

contract CrossChainAttester is ILayerZeroReceiver {
    struct Attestation {
        address user;
        bytes32 facialHash;
        string username;
        uint256 timestamp;
        bool verified;
        uint16 sourceChain;
    }

    struct CCIPRequest {
        bytes32 attestationId;
        address requester;
        uint256 timestamp;
        bool resolved;
    }

    ILayerZeroEndpoint public immutable lzEndpoint;
    ICCIPGateway public ccipGateway;
    
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(bytes32 => Attestation) public attestations;
    mapping(address => bytes32[]) public userAttestations;
    mapping(bytes32 => CCIPRequest) public ccipRequests;
    mapping(uint16 => address) public chainValidators;

    event AttestationCreated(bytes32 indexed attestationId, address indexed user, uint16 srcChain);
    event AttestationVerified(bytes32 indexed attestationId, address indexed user);
    event CCIPRequestInitiated(bytes32 indexed requestId, bytes32 attestationId);
    event CCIPResponseReceived(bytes32 indexed requestId, bool verified);

    modifier onlyEndpoint() {
        require(msg.sender == address(lzEndpoint), "Unauthorized endpoint");
        _;
    }

    constructor(address _lzEndpoint) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function setCCIPGateway(address _ccipGateway) external {
        ccipGateway = ICCIPGateway(_ccipGateway);
    }

    function setChainValidator(uint16 chainId, address validator) external {
        chainValidators[chainId] = validator;
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
            verified: false,
            sourceChain: _srcChainId
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

    function requestCrossChainVerification(bytes32 attestationId) external {
        require(attestations[attestationId].user != address(0), "Attestation not found");
        require(!attestations[attestationId].verified, "Already verified");
        require(address(ccipGateway) != address(0), "CCIP Gateway not set");

        bytes32 requestId = keccak256(abi.encodePacked(
            attestationId,
            msg.sender,
            block.timestamp
        ));

        ccipRequests[requestId] = CCIPRequest({
            attestationId: attestationId,
            requester: msg.sender,
            timestamp: block.timestamp,
            resolved: false
        });

        Attestation memory attestation = attestations[attestationId];
        
        bytes memory requestData = abi.encode(
            attestation.user,
            attestation.facialHash,
            attestation.username,
            attestation.sourceChain
        );

        ccipGateway.request(
            requestId,
            requestData,
            address(this),
            this.handleCCIPResponse.selector
        );

        emit CCIPRequestInitiated(requestId, attestationId);
    }

    function handleCCIPResponse(
        bytes32 requestId,
        bool verified,
        bytes calldata /* additionalData */
    ) external {
        require(msg.sender == address(ccipGateway), "Only CCIP Gateway");
        require(ccipRequests[requestId].requester != address(0), "Request not found");
        require(!ccipRequests[requestId].resolved, "Already resolved");

        CCIPRequest storage request = ccipRequests[requestId];
        request.resolved = true;

        if (verified) {
            attestations[request.attestationId].verified = true;
            emit AttestationVerified(request.attestationId, attestations[request.attestationId].user);
        }

        emit CCIPResponseReceived(requestId, verified);
    }

    function getAttestationWithChain(bytes32 attestationId) 
        external 
        view 
        returns (
            address user,
            bytes32 facialHash,
            string memory username,
            uint256 timestamp,
            bool verified,
            uint16 sourceChain
        ) 
    {
        Attestation memory attestation = attestations[attestationId];
        return (
            attestation.user,
            attestation.facialHash,
            attestation.username,
            attestation.timestamp,
            attestation.verified,
            attestation.sourceChain
        );
    }
}