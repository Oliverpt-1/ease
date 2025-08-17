// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";

contract DebugFactory is Script {
    function run() external view {
        // Check the Kernel Meta Factory
        address metaFactory = 0xd703aaE79538628d27099B8c4f621bE4CCd142d5;
        
        console.log("\n=== Checking Kernel Meta Factory ===");
        console.log("Address:", metaFactory);
        
        // Check if it has code
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(metaFactory)
        }
        console.log("Code size:", codeSize, "bytes");
        
        if (codeSize == 0) {
            console.log("[ERROR] No code at this address!");
            console.log("The Meta Factory might not be deployed on this network");
        } else {
            console.log("[OK] Contract exists");
            
            // Try to check the factory interface
            // The Meta Factory expects: createAccount(bytes calldata data, bytes32 salt)
            // Where data should contain the kernel implementation and init data
            
            console.log("\nMeta Factory expects:");
            console.log("- data: encoded (implementation, initData)");
            console.log("- salt: unique salt for deterministic address");
        }
        
        // Check our deployed factory
        address ourFactory = 0x42aA7A5d3A1dA5486F4DcA91D613ec5601624201;
        console.log("\n=== Our Wallet Factory ===");
        console.log("Address:", ourFactory);
        
        assembly {
            codeSize := extcodesize(ourFactory)
        }
        console.log("Code size:", codeSize, "bytes");
    }
}