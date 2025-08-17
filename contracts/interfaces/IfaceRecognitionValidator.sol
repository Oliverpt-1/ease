// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@erc7579/src/interfaces/IERC7579Module.sol";

interface IFaceRecognitionValidator is IValidator {
    struct UserData {
        bytes32 facialHash;
        bytes encodedEmbedding;
        string username;
        uint256 index;
        bool isRegistered;
        uint256 registrationTimestamp;
    }

    struct FacialSignature {
        bytes32 facialHash;
        uint256 timestamp;
        bytes signature;
    }

    event UserRegistered(address indexed wallet, string username, bytes32 facialHash);
    event FacialHashUpdated(address indexed wallet, bytes32 oldHash, bytes32 newHash);
    event CrossChainSync(address indexed wallet, uint16 chainId, bytes32 facialHash);
    event ValidationSuccessful(address indexed wallet, bytes32 messageHash);
    event ValidationFailed(address indexed wallet, bytes32 messageHash, string reason);

    error InvalidFacialHash();
    error UserNotRegistered();
    error UsernameAlreadyTaken();
    error InvalidSignature();
    error FacialHashMismatch();
    error CrossChainSyncFailed();

    function registerUser(
        string calldata username,
        bytes32 facialHash,
        uint256 index
    ) external;

    function updateFacialHash(bytes32 newFacialHash) external;

    function validateFacialSignature(
        address user,
        bytes32 messageHash,
        FacialSignature calldata facialSig
    ) external view returns (bool);

    function getUserData(address user) external view returns (UserData memory);

    function getUserByUsername(string calldata username) external view returns (address);

    function generateWalletSalt(bytes32 facialHash, uint256 index) external pure returns (bytes32);

    function syncToChain(uint16 chainId, address user) external payable;
}