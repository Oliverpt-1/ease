// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";
import "../interfaces/IERC7579Module.sol";

abstract contract faceRecognitionValidator is IFaceRecognitionValidator {
    
    mapping(address => bytes32) public userFacialHash;
    mapping(address => bool) public isInitialized;
    
    modifier onlyInitialized(address smartAccount) {
        require(isInitialized[smartAccount], "Not initialized");
        _;
    }

    constructor() {}

    function onInstall(bytes calldata data) external override {
        require(!isInitialized[msg.sender], "Already initialized");
        
        bytes32 facialHash = abi.decode(data, (bytes32));
        require(facialHash != bytes32(0), "Invalid facial hash");
        
        userFacialHash[msg.sender] = facialHash;
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

    function validateFacialSignature(
        address user,
        bytes32,
        FacialSignature calldata facialSig
    ) external view override returns (bool) {
        return userFacialHash[user] == facialSig.facialHash;
    }


    function getUserData(address user) external view override returns (UserData memory) {
        return UserData({
            facialHash: userFacialHash[user],
            username: "",
            index: 0,
            isRegistered: isInitialized[user],
            registrationTimestamp: 0
        });
    }
}