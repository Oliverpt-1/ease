// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/validators/faceRecognitionValidator.sol";
import "../contracts/factories/FRVMWalletFactory.sol";
import "../contracts/merchants/MerchantAccount.sol";
import "../contracts/ens/FRVMResolver.sol";
import "../contracts/ens/UsernameRegistry.sol";
import "../contracts/cross-chain/CrossChainAttester.sol";

contract DeployFRVM is Script {
    struct DeploymentConfig {
        address layerZeroEndpoint;
        address ensRegistry;
        address kernelFactory;
        address kernelImplementation;
    }

    struct DeployedContracts {
        address frvmValidator;
        address walletFactory;
        address merchantAccount;
        address frvmResolver;
        address usernameRegistry;
        address crossChainAttester;
    }

    mapping(uint256 => DeploymentConfig) public chainConfigs;

    function setUp() public {
        // Ethereum Sepolia
        chainConfigs[11155111] = DeploymentConfig({
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            ensRegistry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e,
            kernelFactory: address(0), // Will deploy without Kernel for now
            kernelImplementation: address(0)
        });

        // Base Sepolia
        chainConfigs[84532] = DeploymentConfig({
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0)
        });

        // Arbitrum Sepolia
        chainConfigs[421614] = DeploymentConfig({
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0)
        });

        // Optimism Sepolia
        chainConfigs[11155420] = DeploymentConfig({
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0)
        });
    }

    function run() external returns (DeployedContracts memory deployed) {
        uint256 chainId = block.chainid;
        DeploymentConfig memory config = chainConfigs[chainId];
        
        require(config.layerZeroEndpoint != address(0), "Chain not supported");

        vm.startBroadcast();

        // 1. Deploy Username Registry (chain-specific usernames)
        deployed.usernameRegistry = address(new UsernameRegistry());
        console.log("UsernameRegistry deployed:", deployed.usernameRegistry);

        // 2. Deploy FRVM Resolver (ENS integration on mainnet/sepolia only)
        if (config.ensRegistry != address(0)) {
            deployed.frvmResolver = address(new FRVMResolver(config.ensRegistry));
            console.log("FRVMResolver deployed:", deployed.frvmResolver);
        }

        // 3. Deploy Face Recognition Validator
        deployed.frvmValidator = address(new FacialRecognitionValidator(config.layerZeroEndpoint));
        console.log("FacialRecognitionValidator deployed:", deployed.frvmValidator);

        // 4. Deploy Wallet Factory (if Kernel addresses provided)
        if (config.kernelFactory != address(0)) {
            deployed.walletFactory = address(new FRVMWalletFactory(
                config.kernelFactory,
                deployed.frvmValidator,
                config.kernelImplementation
            ));
            console.log("FRVMWalletFactory deployed:", deployed.walletFactory);
        }

        // 5. Deploy Merchant Account
        deployed.merchantAccount = address(new MerchantAccount(
            deployed.frvmValidator,
            deployed.usernameRegistry
        ));
        console.log("MerchantAccount deployed:", deployed.merchantAccount);

        // 6. Deploy Cross Chain Attester
        deployed.crossChainAttester = address(new CrossChainAttester(config.layerZeroEndpoint));
        console.log("CrossChainAttester deployed:", deployed.crossChainAttester);

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Chain ID:", chainId);
        console.log("FRVM Validator:", deployed.frvmValidator);
        console.log("Username Registry:", deployed.usernameRegistry);
        console.log("Merchant Account:", deployed.merchantAccount);
        console.log("Cross Chain Attester:", deployed.crossChainAttester);
        
        if (deployed.walletFactory != address(0)) {
            console.log("Wallet Factory:", deployed.walletFactory);
        }
        if (deployed.frvmResolver != address(0)) {
            console.log("FRVM Resolver:", deployed.frvmResolver);
        }

        return deployed;
    }

    function deployToMultipleChains(uint256[] memory chainIds) external {
        for (uint256 i = 0; i < chainIds.length; i++) {
            console.log("\n=== DEPLOYING TO CHAIN", chainIds[i], "===");
            // Note: This would require switching networks in practice
            // For hackathon, run script separately on each chain
        }
    }
}