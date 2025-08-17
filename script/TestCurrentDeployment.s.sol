// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";
import {IFaceRecognitionValidator} from "../contracts/interfaces/IfaceRecognitionValidator.sol";

contract TestCurrentDeployment is Script {
    // Our working factory and validator
    FRVMWalletFactory constant factory = FRVMWalletFactory(0x068a7Ddd8f59Eb7f622519a7eef9677080DBcc9c);
    IFaceRecognitionValidator constant validator = IFaceRecognitionValidator(0x34A2e49D484Fc27f16a1Cf1B90923E28b7128843);
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("\n=== Testing Current Wallet Deployment ===");
        console.log("Factory:", address(factory));
        console.log("Validator:", address(validator));
        console.log("Deployer:", deployer);
        
        // Generate unique test data
        string memory username = string(abi.encodePacked("test", vm.toString(block.timestamp)));
        bytes32 facialHash = keccak256(abi.encodePacked("debug_test", deployer, block.timestamp));
        
        console.log("\nTest Parameters:");
        console.log("- Username:", username);
        console.log("- Facial hash:", uint256(facialHash));
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Register user
        console.log("\n1. Registering user with validator...");
        try validator.registerUser(username, facialHash, 0) {
            console.log("[OK] User registered");
        } catch Error(string memory reason) {
            console.log("[ERROR] Registration failed:", reason);
            return;
        } catch {
            console.log("[ERROR] Registration failed with unknown error");
            return;
        }
        
        // Step 2: Create wallet
        console.log("\n2. Creating wallet...");
        try factory.createWallet(username, facialHash) returns (address newWallet) {
            console.log("[SUCCESS] Wallet created:", newWallet);
            
            // Verify the wallet was created
            uint256 codeSize;
            assembly { codeSize := extcodesize(newWallet) }
            console.log("- Wallet code size:", codeSize, "bytes");
            
            // Check ENS mapping
            vm.stopBroadcast();
            address resolved = factory.resolveUsername(username);
            console.log("- ENS resolution:", username, "=>", resolved);
            console.log("- Match:", resolved == newWallet);
            vm.startBroadcast(deployerPrivateKey);
            
        } catch Error(string memory reason) {
            console.log("[ERROR] Wallet creation failed:", reason);
        } catch (bytes memory errorData) {
            console.log("[ERROR] Wallet creation failed with error data:");
            if (errorData.length >= 4) {
                bytes4 selector;
                assembly {
                    selector := mload(add(errorData, 0x20))
                }
                console.log("- Error selector:", uint256(uint32(selector)));
            }
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== Test Complete ===");
    }
}