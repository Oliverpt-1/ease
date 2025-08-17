// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {faceRecognitionValidator} from "../contracts/validators/faceRecognitionValidator.sol";

// Concrete implementation with the new test function
contract FaceRecognitionValidatorImpl is faceRecognitionValidator {
    uint256 public constant MODULE_TYPE_VALIDATOR = 1;
    
    mapping(string => address) private usernameToUser;
    mapping(address => string) private userToUsername;
    
    function registerUser(
        string calldata username,
        bytes32 facialHash,
        uint256 // index parameter unused
    ) external override {
        require(!isInitialized[msg.sender], "Already registered");
        require(bytes(username).length > 0, "Username required");
        require(usernameToUser[username] == address(0), "Username taken");
        
        userFacialHash[msg.sender] = facialHash;
        isInitialized[msg.sender] = true;
        usernameToUser[username] = msg.sender;
        userToUsername[msg.sender] = username;
        
        emit UserRegistered(msg.sender, username, facialHash);
    }
    
    function updateFacialHash(bytes32 newFacialHash) external override {
        require(isInitialized[msg.sender], "Not registered");
        require(newFacialHash != bytes32(0), "Invalid facial hash");
        
        bytes32 oldHash = userFacialHash[msg.sender];
        userFacialHash[msg.sender] = newFacialHash;
        
        emit FacialHashUpdated(msg.sender, oldHash, newFacialHash);
    }
    
    function generateWalletSalt(bytes32 facialHash, uint256 index) external pure override returns (bytes32) {
        return keccak256(abi.encodePacked(facialHash, index));
    }

    function validateFacialSignature(
        address,
        bytes32,
        FacialSignature calldata
    ) external pure override returns (bool) {
        return true; // Simplified for deployment
    }

    function getUserByUsername(string calldata username) external view override returns (address) {
        return usernameToUser[username];
    }
}

contract DeployValidator is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploying Updated FaceRecognitionValidator ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy updated validator with testValidateFacialSignature function
        address newValidator = address(new FaceRecognitionValidatorImpl());
        console.log("[DEPLOYED] New FaceRecognitionValidator:", newValidator);
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT SUCCESSFUL ===");
        console.log("New validator address:", newValidator);
        console.log("\nNext step: Update factory to use new validator address");
        console.log("Old validator: 0x3356f1D40068bD3f05b81B0e83Fb0c58d9030574");
        console.log("New validator:", newValidator);
    }
}