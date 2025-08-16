// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library SignatureLib {
    bytes4 constant EIP1271_MAGIC_VALUE = 0x1626ba7e;
    bytes4 constant INVALID_SIGNATURE = 0xffffffff;

    struct PackedSignature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function packSignature(
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }

    function unpackSignature(
        bytes memory signature
    ) internal pure returns (PackedSignature memory) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        return PackedSignature(r, s, v);
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        PackedSignature memory sig = unpackSignature(signature);
        return ecrecover(hash, sig.v, sig.r, sig.s);
    }

    function isValidEIP1271Signature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 result) {
            return result == EIP1271_MAGIC_VALUE;
        } catch {
            return false;
        }
    }

    function validateSignatureFormat(bytes memory signature) internal pure returns (bool) {
        return signature.length == 65 || signature.length >= 96; // ECDSA or facial signature
    }

    function hashTypedData(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function getDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            typeHash,
            nameHash,
            versionHash,
            chainId,
            verifyingContract
        ));
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
    }

    function isValidSignatureLength(bytes memory signature) internal pure returns (bool) {
        return signature.length == 65;
    }

    function createFacialSignature(
        bytes32 facialHash,
        uint256 timestampValue,
        bytes memory proof
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(facialHash, timestampValue, proof);
    }

    function parseFacialSignature(
        bytes memory signature
    ) internal pure returns (bytes32 facialHash, uint256 timestampValue, bytes memory proof) {
        require(signature.length >= 96, "Invalid facial signature length");
        
        assembly {
            facialHash := mload(add(signature, 32))
            timestampValue := mload(add(signature, 64))
        }
        
        proof = new bytes(signature.length - 64);
        for (uint256 i = 64; i < signature.length; i++) {
            proof[i - 64] = signature[i];
        }
    }
}

interface IERC1271 {
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4);
}