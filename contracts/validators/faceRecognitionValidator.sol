// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";
import "../interfaces/IERC7579Module.sol";

interface IChainlinkFacialValidator {
    function sendRequest(uint256 subscriptionId, string[] memory args) external;
}

abstract contract faceRecognitionValidator is IFaceRecognitionValidator {
    
    mapping(address => bytes32) public userFacialHash;
    mapping(address => bool) public isInitialized;
    mapping(address => UserData) public userData;
    mapping(string => address) public usernameToWallet;
    address public chainLinkFacialValidator;
    
    modifier onlyInitialized(address smartAccount) {
        require(isInitialized[smartAccount], "Not initialized");
        _;
    }

    constructor() {}

    function onInstall(bytes calldata data) external override {
        require(!isInitialized[msg.sender], "Already initialized");
        
        (bytes32 facialHash, uint256[] memory facialEmbedding) = abi.decode(data, (bytes32, uint256[]));
        require(facialHash != bytes32(0), "Invalid facial hash");
        
        userFacialHash[msg.sender] = facialHash;
        userData[msg.sender] = UserData({
            facialHash: facialHash,
            encodedEmbedding: abi.encode(facialEmbedding),
            username: "",
            index: 0,
            isRegistered: true,
            registrationTimestamp: block.timestamp
        });
        isInitialized[msg.sender] = true;
        
        emit UserRegistered(msg.sender, "", facialHash);
    }

    function onUninstall(bytes calldata) external override {
        require(isInitialized[msg.sender], "Not initialized");
        
        delete userFacialHash[msg.sender];
        delete isInitialized[msg.sender];
    }

    function isModuleType(uint256 typeID) external pure override returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    function registerUser(
        string calldata username,
        bytes32 facialHash,
        uint256 index
    ) external virtual override {
        uint256[] memory emptyEmbedding = new uint256[](0);
        _registerUser(msg.sender, username, facialHash, emptyEmbedding, index);
    }

    function _registerUser(
        address wallet,
        string memory username,
        bytes32 facialHash,
        uint256[] memory facialEmbedding,
        uint256 index
    ) internal {
        if (facialHash == bytes32(0)) revert InvalidFacialHash();
        if (usernameToWallet[username] != address(0)) revert UsernameAlreadyTaken();
        
        userData[wallet] = UserData({
            facialHash: facialHash,
            encodedEmbedding: abi.encode(facialEmbedding),
            username: username,
            index: index,
            isRegistered: true,
            registrationTimestamp: block.timestamp
        });
        
        usernameToWallet[username] = wallet;
        
        emit UserRegistered(wallet, username, facialHash);
    }

    function updateFacialHash(bytes32 newFacialHash) external virtual override {
        if (!userData[msg.sender].isRegistered) revert UserNotRegistered();
        if (newFacialHash == bytes32(0)) revert InvalidFacialHash();
        
        bytes32 oldHash = userData[msg.sender].facialHash;
        userData[msg.sender].facialHash = newFacialHash;
        
        emit FacialHashUpdated(msg.sender, oldHash, newFacialHash);
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32
    ) external view override returns (uint256 validationData) {
        bytes32 providedHash = abi.decode(userOp.signature, (bytes32));
        
        bool isValid = userFacialHash[userOp.sender] == providedHash;
        
        return isValid ? 0 : 1;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32,
        bytes calldata signature
    ) external view override returns (bytes4) {
        bytes32 providedHash = abi.decode(signature, (bytes32));
        
        bool isValid = userFacialHash[sender] == providedHash;
        
        return isValid ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }

    function _validateFacialSignature(
        address sender,
        bytes32 userOpHash,
        FacialSignature memory facialSig
    ) internal returns (bool) {
        UserData memory user = userData[sender];
        if (!user.isRegistered) return false;
        
        uint256[] memory storedEmbedding = abi.decode(user.encodedEmbedding, (uint256[]));
        uint256[] memory frontendEmbedding = abi.decode(facialSig.signature, (uint256[]));
        
        IChainlinkFacialValidator validator = IChainlinkFacialValidator(chainLinkFacialValidator);
        
        string[] memory args = new string[](2);
        args[0] = _arrayToString(storedEmbedding);
        args[1] = _arrayToString(frontendEmbedding);
        
        // TODO: Replace with actual Chainlink validation when ready
        // validator.sendRequest(5463, args);
        
        // For now, always return true to test payment flow
        return true;
    }
    
    function _arrayToString(uint256[] memory arr) internal pure returns (string memory) {
        return "[1,2,3]";
    }


    function getUserData(address user) external view override returns (UserData memory) {
        return userData[user];
    }
}