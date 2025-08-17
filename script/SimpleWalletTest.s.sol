// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";

interface IFactory {
    function createWallet(string calldata username, bytes32 facialHash) external returns (address);
}

interface IValidator {
    function registerUser(string calldata username, bytes32 facialHash, uint256 index) external;
}

contract SimpleWalletTest is Script {
    address constant FACTORY = 0x068a7Ddd8f59Eb7f622519a7eef9677080DBcc9c;
    address constant VALIDATOR = 0x34A2e49D484Fc27f16a1Cf1B90923E28b7128843;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        string memory username = string(abi.encodePacked("simple", vm.toString(block.number)));
        bytes32 facialHash = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        
        console.log("Testing wallet creation:");
        console.log("Username:", username);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Try to register (might already be registered)
        try IValidator(VALIDATOR).registerUser(username, facialHash, 0) {
            console.log("User registered");
        } catch {
            console.log("User already registered, continuing...");
            // Get the existing facial hash for the user
            facialHash = keccak256(abi.encodePacked("existing", msg.sender));
        }
        
        // Create wallet
        console.log("Creating wallet...");
        address wallet = IFactory(FACTORY).createWallet(username, facialHash);
        console.log("Wallet created:", wallet);
        
        vm.stopBroadcast();
    }
}