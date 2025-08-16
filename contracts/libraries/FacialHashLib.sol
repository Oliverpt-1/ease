// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library FacialHashLib {
    error InvalidHashLength();
    error InvalidSignatureLength();
    error HashMismatch();

    function generateFacialHash(
        bytes calldata facialMatrix,
        uint256 salt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(facialMatrix, salt));
    }

    function generateDeterministicSalt(
        bytes32 facialHash,
        uint256 index
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(facialHash, index));
    }

    function verifyFacialSignature(
        bytes32 messageHash,
        bytes32 expectedFacialHash,
        bytes calldata signature
    ) internal view returns (bool) {
        if (signature.length < 96) {
            return false;
        }

        bytes32 recoveredHash = bytes32(signature[0:32]);
        uint256 timestamp = uint256(bytes32(signature[32:64]));
        bytes memory facialProof = signature[64:];

        if (recoveredHash != expectedFacialHash) {
            return false;
        }

        if (block.timestamp > timestamp + 300) { // 5 minute validity
            return false;
        }

        bytes32 proofHash = keccak256(abi.encodePacked(
            messageHash,
            recoveredHash,
            timestamp
        ));

        return keccak256(facialProof) == proofHash;
    }

    function hashFacialMatrix(
        uint256[] calldata matrix,
        uint256 precision
    ) internal pure returns (bytes32) {
        require(matrix.length > 0, "Empty matrix");
        require(precision > 0, "Invalid precision");

        bytes memory packedMatrix = new bytes(matrix.length * 32);
        
        for (uint256 i = 0; i < matrix.length; i++) {
            uint256 normalizedValue = (matrix[i] / precision) * precision;
            bytes32 valueBytes = bytes32(normalizedValue);
            
            for (uint256 j = 0; j < 32; j++) {
                packedMatrix[i * 32 + j] = valueBytes[j];
            }
        }

        return keccak256(packedMatrix);
    }

    function validateHashFormat(bytes32 hash) internal pure returns (bool) {
        return hash != bytes32(0);
    }

    function compareHashes(
        bytes32 hash1,
        bytes32 hash2,
        uint256 tolerance
    ) internal pure returns (bool) {
        if (tolerance == 0) {
            return hash1 == hash2;
        }

        uint256 diff = hash1 > hash2 ? 
            uint256(hash1) - uint256(hash2) : 
            uint256(hash2) - uint256(hash1);
            
        return diff <= tolerance;
    }

    function generateWalletSeed(
        bytes32 facialHash,
        string memory username,
        uint256 chainId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            facialHash,
            keccak256(bytes(username)),
            chainId
        ));
    }

    function extractHashComponents(
        bytes32 compositeHash
    ) internal pure returns (bytes16 high, bytes16 low) {
        high = bytes16(compositeHash);
        low = bytes16(compositeHash << 128);
    }

    function combineHashComponents(
        bytes16 high,
        bytes16 low
    ) internal pure returns (bytes32) {
        return bytes32(high) | (bytes32(low) >> 128);
    }

    function rotateHash(
        bytes32 hash,
        uint8 positions
    ) internal pure returns (bytes32) {
        uint256 hashInt = uint256(hash);
        uint256 rotated = (hashInt << positions) | (hashInt >> (256 - positions));
        return bytes32(rotated);
    }
}