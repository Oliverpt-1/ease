// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";
import {faceRecognitionValidator} from "../contracts/validators/faceRecognitionValidator.sol";
import {IFaceRecognitionValidator} from "../contracts/interfaces/IfaceRecognitionValidator.sol";

// Concrete implementation for testing
contract FaceRecognitionValidatorImpl is faceRecognitionValidator {
    mapping(string => address) private usernameToUser;
    
    function registerUser(
        string calldata username,
        bytes32 facialHash,
        uint256
    ) external {
        require(!isInitialized[msg.sender], "Already initialized");
        require(facialHash != bytes32(0), "Invalid facial hash");
        
        userFacialHash[msg.sender] = facialHash;
        isInitialized[msg.sender] = true;
        usernameToUser[username] = msg.sender;
        
        emit UserRegistered(msg.sender, username, facialHash);
    }
    
    function updateFacialHash(bytes32 newFacialHash) external {
        require(isInitialized[msg.sender], "Not initialized");
        require(newFacialHash != bytes32(0), "Invalid facial hash");
        
        userFacialHash[msg.sender] = newFacialHash;
    }
    
    function getUserByUsername(string calldata username) external view returns (address) {
        return usernameToUser[username];
    }
    
    function generateWalletSalt(bytes32 facialHash, uint256 index) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(facialHash, index));
    }
}

contract ModuleInstallationTest is Test {
    FRVMWalletFactory factory;
    FaceRecognitionValidatorImpl validator;
    
    address constant KERNEL_FACTORY = 0xaac5D4240AF87249B3f71BC8E4A2cae074A3E419;
    address constant KERNEL_IMPL = 0x0DA6a956B9488eD4dd761E59f52FDc6c8068E6B5;
    
    function setUp() public {
        // Deploy validator
        validator = new FaceRecognitionValidatorImpl();
        
        // Deploy factory
        factory = new FRVMWalletFactory(
            KERNEL_FACTORY,
            address(validator),
            KERNEL_IMPL
        );
    }
    
    function testModuleIsInstalledOnWalletCreation() public {
        string memory username = "testuser";
        bytes32 facialHash = keccak256("test_facial_data");
        
        // Create wallet
        address wallet = factory.createWallet(username, facialHash);
        
        console.log("Created wallet:", wallet);
        
        // Check if module is initialized
        bool isInitialized = validator.isInitialized(wallet);
        console.log("Module initialized:", isInitialized);
        
        // Check if facial hash is stored
        bytes32 storedHash = validator.userFacialHash(wallet);
        console.log("Stored facial hash matches:", storedHash == facialHash);
        
        // Assertions
        assertTrue(isInitialized, "Module should be initialized");
        assertEq(storedHash, facialHash, "Facial hash should be stored");
        
        // Verify user data
        IFaceRecognitionValidator.UserData memory userData = validator.getUserData(wallet);
        assertEq(userData.facialHash, facialHash, "User data should contain facial hash");
        assertTrue(userData.isRegistered, "User should be registered");
    }
}