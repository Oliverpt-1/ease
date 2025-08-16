// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FacialRecognitionValidator} from "../contracts/validators/faceRecognitionValidator.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";
import {ModuleFactory} from "../contracts/factories/ModuleFactory.sol";
import {MerchantAccount} from "../contracts/merchants/MerchantAccount.sol";
import {UsernameRegistry} from "../contracts/ens/UsernameRegistry.sol";
import {CrossChainAttester} from "../contracts/cross-chain/CrossChainAttester.sol";

contract DeployKernelWithFRVM is Script {
    struct DeploymentResult {
        address frvmValidator;
        address walletFactory;
        address moduleFactory;
        address merchantAccount;
        address usernameRegistry;
        address crossChainAttester;
    }
    
    // Kernel addresses on Sepolia
    address public constant KERNEL_FACTORY = 0xd6CEDDe84be40893d153Be9d467CD6aD37875b28;
    address public constant KERNEL_IMPLEMENTATION = 0xd703aaE79538628d27099B8c4f621bE4CCd142d5;
    
    // LayerZero endpoint for Sepolia
    address public constant LAYERZERO_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    
    function run() external returns (DeploymentResult memory result) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Username Registry
        result.usernameRegistry = address(new UsernameRegistry());
        
        // 2. Deploy Module Factory
        result.moduleFactory = address(new ModuleFactory(LAYERZERO_ENDPOINT));
        
        // 3. Deploy FRVM Validator
        result.frvmValidator = address(new FacialRecognitionValidator(LAYERZERO_ENDPOINT));
        
        // 4. Deploy FRVM Wallet Factory (integrates with Kernel)
        result.walletFactory = address(new FRVMWalletFactory(
            KERNEL_FACTORY,
            result.frvmValidator,
            KERNEL_IMPLEMENTATION
        ));
        
        // 5. Deploy Merchant Account
        result.merchantAccount = address(new MerchantAccount(
            result.frvmValidator,
            result.usernameRegistry
        ));
        
        // 6. Deploy Cross Chain Attester
        result.crossChainAttester = address(new CrossChainAttester(LAYERZERO_ENDPOINT));
        
        vm.stopBroadcast();
        
        // Log deployment addresses
        console.log("\n=== DEPLOYMENT SUCCESSFUL ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("\nDeployed Contracts:");
        console.log("- FRVMValidator:", result.frvmValidator);
        console.log("- WalletFactory:", result.walletFactory);
        console.log("- ModuleFactory:", result.moduleFactory);
        console.log("- UsernameRegistry:", result.usernameRegistry);
        console.log("- MerchantAccount:", result.merchantAccount);
        console.log("- CrossChainAttester:", result.crossChainAttester);
        console.log("\nExternal Contracts:");
        console.log("- KernelFactory:", KERNEL_FACTORY);
        console.log("- KernelImplementation:", KERNEL_IMPLEMENTATION);
        console.log("- LayerZeroEndpoint:", LAYERZERO_ENDPOINT);
        
        return result;
    }
    
    function _saveDeployment(DeploymentResult memory result, address deployer) internal {
        string memory deploymentData = string(abi.encodePacked(
            "{",
            "\"chainId\":", vm.toString(block.chainid), ",",
            "\"deployer\":\"", vm.toString(deployer), "\",",
            "\"contracts\":{",
            "\"frvmValidator\":\"", vm.toString(result.frvmValidator), "\",",
            "\"walletFactory\":\"", vm.toString(result.walletFactory), "\",",
            "\"moduleFactory\":\"", vm.toString(result.moduleFactory), "\",",
            "\"usernameRegistry\":\"", vm.toString(result.usernameRegistry), "\",",
            "\"merchantAccount\":\"", vm.toString(result.merchantAccount), "\",",
            "\"crossChainAttester\":\"", vm.toString(result.crossChainAttester), "\"",
            "},",
            "\"external\":{",
            "\"kernelFactory\":\"", vm.toString(KERNEL_FACTORY), "\",",
            "\"kernelImplementation\":\"", vm.toString(KERNEL_IMPLEMENTATION), "\",",
            "\"layerZeroEndpoint\":\"", vm.toString(LAYERZERO_ENDPOINT), "\"",
            "}",
            "}"
        ));
        
        string memory fileName = string(abi.encodePacked(
            "deployments/",
            vm.toString(block.chainid),
            "-deployment.json"
        ));
        
        vm.writeFile(fileName, deploymentData);
    }
}