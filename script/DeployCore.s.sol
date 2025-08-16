// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/validators/faceRecognitionValidator.sol";
import "../contracts/merchants/MerchantAccount.sol";
import "../contracts/ens/UsernameRegistry.sol";
import "../contracts/cross-chain/CrossChainAttester.sol";

contract DeployCore is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address layerZeroEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f; // Sepolia LZ endpoint
        
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying to chain:", block.chainid);
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // 1. Deploy Username Registry
        UsernameRegistry usernameRegistry = new UsernameRegistry();
        console.log("UsernameRegistry deployed:", address(usernameRegistry));

        // 2. Deploy Face Recognition Validator
        FacialRecognitionValidator validator = new FacialRecognitionValidator(layerZeroEndpoint);
        console.log("FacialRecognitionValidator deployed:", address(validator));

        // 3. Deploy Merchant Account
        MerchantAccount merchantAccount = new MerchantAccount(
            address(validator),
            address(usernameRegistry)
        );
        console.log("MerchantAccount deployed:", address(merchantAccount));

        // 4. Deploy Cross Chain Attester
        CrossChainAttester attester = new CrossChainAttester(layerZeroEndpoint);
        console.log("CrossChainAttester deployed:", address(attester));

        vm.stopBroadcast();

        // Save deployment info
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Chain ID:", block.chainid);
        console.log("Validator:", address(validator));
        console.log("Username Registry:", address(usernameRegistry));
        console.log("Merchant Account:", address(merchantAccount));
        console.log("Cross Chain Attester:", address(attester));
        console.log("Layer Zero Endpoint:", layerZeroEndpoint);
    }
}