// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";

contract DebugWallet is Script {
    FRVMWalletFactory constant FACTORY = FRVMWalletFactory(0xd0280ac9EB3605DfF823bD09F6Db2Fc9FF280FE8);
    
    function run() external view {
        console.log("\n=== Debug Wallet Factory ===");
        console.log("Factory:", address(FACTORY));
        console.log("Kernel Factory:", address(FACTORY.kernelFactory()));
        console.log("FRVM Validator:", address(FACTORY.frvmValidator()));
        console.log("Kernel Implementation:", FACTORY.kernelImplementation());
        
        // Test parameters
        string memory username = "testuser";
        bytes32 facialHash = keccak256(abi.encodePacked("test_facial_data"));
        
        // Check if username is available
        address existing = FACTORY.subdomainToWallet(username);
        console.log("\nUsername '%s' status:", username);
        console.log("Existing wallet:", existing);
        console.log("Available:", existing == address(0));
        
        // Generate the salt that would be used
        uint256 index = FACTORY.nextWalletIndex(facialHash);
        bytes32 salt = keccak256(abi.encodePacked(facialHash, index));
        console.log("\nWallet creation parameters:");
        console.log("Facial hash:", uint256(facialHash));
        console.log("Next index:", index);
        console.log("Salt:", uint256(salt));
    }
}