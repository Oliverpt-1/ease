// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library CrossChainLib {
    struct ChainConfig {
        uint16 chainId;
        bytes trustedRemote;
        bool isActive;
        uint256 gasLimit;
        uint256 gasPrice;
    }

    struct CrossChainMessage {
        uint16 srcChainId;
        uint16 dstChainId;
        bytes payload;
        uint64 nonce;
        uint256 timestamp;
    }

    event ChainConfigUpdated(uint16 indexed chainId, bool isActive);
    event MessageSent(uint16 indexed dstChainId, bytes payload, uint64 nonce);
    event MessageReceived(uint16 indexed srcChainId, bytes payload, uint64 nonce);

    function encodeUserData(
        address user,
        string memory username,
        bytes32 facialHash,
        uint256 index
    ) internal pure returns (bytes memory) {
        return abi.encode(user, username, facialHash, index);
    }

    function decodeUserData(
        bytes memory payload
    ) internal pure returns (
        address user,
        string memory username,
        bytes32 facialHash,
        uint256 index
    ) {
        return abi.decode(payload, (address, string, bytes32, uint256));
    }

    function validateChainId(uint16 chainId) internal pure returns (bool) {
        return chainId > 0 && chainId != 0xFFFF;
    }

    function computeMessageHash(
        uint16 srcChainId,
        uint16 dstChainId,
        bytes memory payload,
        uint64 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(srcChainId, dstChainId, payload, nonce));
    }

    function validateTrustedRemote(
        bytes memory remote,
        bytes memory expected
    ) internal pure returns (bool) {
        return keccak256(remote) == keccak256(expected);
    }

    function formatChainPath(
        address contractAddress,
        uint16 chainId
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(contractAddress, chainId);
    }

    function extractAddressFromPath(
        bytes memory path
    ) internal pure returns (address) {
        require(path.length >= 20, "Invalid path length");
        
        address addr;
        assembly {
            addr := mload(add(path, 20))
        }
        return addr;
    }

    function createSyncPayload(
        bytes32 facialHash,
        string memory username,
        address wallet,
        uint256 action // 0: register, 1: update, 2: deactivate
    ) internal view returns (bytes memory) {
        return abi.encode(facialHash, username, wallet, action, block.timestamp);
    }

    function parseSyncPayload(
        bytes memory payload
    ) internal pure returns (
        bytes32 facialHash,
        string memory username,
        address wallet,
        uint256 action,
        uint256 timestamp
    ) {
        return abi.decode(payload, (bytes32, string, address, uint256, uint256));
    }

    function estimateGasFee(
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 multiplier
    ) internal pure returns (uint256) {
        return (gasLimit * gasPrice * multiplier) / 100;
    }

    function isMessageExpired(
        uint256 timestamp,
        uint256 expiryDuration
    ) internal view returns (bool) {
        return block.timestamp > timestamp + expiryDuration;
    }

    function generateNonce(
        address sender,
        uint16 dstChainId
    ) internal view returns (uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(
            sender,
            dstChainId,
            block.timestamp,
            block.prevrandao
        ))));
    }

    function validateMessageIntegrity(
        bytes memory payload,
        bytes32 expectedHash
    ) internal pure returns (bool) {
        return keccak256(payload) == expectedHash;
    }

    function packChainData(
        uint16 chainId,
        address validator,
        bool isActive
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(chainId, validator, isActive));
    }

    function unpackChainData(
        bytes32 /* data */
    ) internal pure returns (uint16 /* chainId */, address /* validator */, bool /* isActive */) {
        // This is a simplified unpacking - in practice you'd store this data separately
        // and use the hash as a key to retrieve the actual values
        revert("Use separate storage for chain data");
    }
}