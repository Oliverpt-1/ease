// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";

contract CreateWallet is Script {
    // Factory address that's registered as ENS resolver
    FRVMWalletFactory constant FACTORY = FRVMWalletFactory(0x117C9bd5CBbEcf0bddB71C79C6FAD412754EC272);
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Username for the wallet (will be username.eaze.eth)
        string memory username = string(abi.encodePacked("test", vm.toString(block.timestamp % 1000)));
        
        // Generate a facial hash (in production, this would come from face recognition)
        bytes32 facialHash = keccak256(abi.encodePacked("test_facial_data", block.timestamp));
        
        console.log("\n=== Creating Wallet with ENS ===");
        console.log("Factory:", address(FACTORY));
        console.log("Creator:", deployer);
        console.log("Username:", username);
        console.log("ENS Name: %s.eaze.eth", username);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create the wallet
        address wallet = FACTORY.createWallet(username, facialHash);
        
        vm.stopBroadcast();
        
        console.log("\n=== Wallet Created Successfully ===");
        console.log("Wallet Address:", wallet);
        console.log("ENS Name: %s.eaze.eth", username);
        
        // Verify the wallet can be resolved
        address resolved = FACTORY.resolveUsername(username);
        console.log("\nVerification:");
        console.log("Resolved from username:", resolved);
        console.log("Match:", resolved == wallet);
    }
}