// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";

interface IKernel {
    function installModule(
        uint256 moduleType,
        address module,
        bytes calldata data
    ) external;
}

contract CreateAndInstallWallet is Script {
    // Factory address (using existing deployed factory)
    FRVMWalletFactory constant FACTORY = FRVMWalletFactory(0x117C9bd5CBbEcf0bddB71C79C6FAD412754EC272);
    address constant VALIDATOR = 0x34A2e49D484Fc27f16a1Cf1B90923E28b7128843; // Existing validator
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Username for the wallet (will be username.eaze.eth)
        string memory username = string(abi.encodePacked("test", vm.toString(block.timestamp % 1000)));
        
        // Generate a facial hash (in production, this would come from face recognition)
        bytes32 facialHash = keccak256(abi.encodePacked("test_facial_data", block.timestamp));
        
        console.log("\n=== Creating Wallet with Module Installation ===");
        console.log("Factory:", address(FACTORY));
        console.log("Creator:", deployer);
        console.log("Username:", username);
        console.log("ENS Name: %s.eaze.eth", username);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create the wallet
        address wallet = FACTORY.createWallet(username, facialHash);
        console.log("\n=== Wallet Created ===");
        console.log("Wallet Address:", wallet);
        
        // Step 2: Install the validator module to trigger onInstall
        // This stores the facial hash in the validator
        IKernel(wallet).installModule(
            1, // MODULE_TYPE_VALIDATOR
            VALIDATOR,
            abi.encode(facialHash)
        );
        console.log("\n=== Module Installed ===");
        console.log("Validator module installed with facial hash");
        
        vm.stopBroadcast();
        
        console.log("\n=== Success ===");
        console.log("Wallet Address:", wallet);
        console.log("ENS Name: %s.eaze.eth", username);
        
        // Verify the wallet can be resolved
        address resolved = FACTORY.resolveUsername(username);
        console.log("\nVerification:");
        console.log("Resolved from username:", resolved);
        console.log("Match:", resolved == wallet);
    }
}