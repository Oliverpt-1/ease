// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/validators/faceRecognitionValidator.sol";
import "../contracts/factories/FRVMWalletFactory.sol";
import "../contracts/factories/ModuleFactory.sol";
import "../contracts/merchants/MerchantAccount.sol";
import "../contracts/merchants/CheckoutProcessor.sol";
import "../contracts/ens/FRVMResolver.sol";
import "../contracts/ens/UsernameRegistry.sol";
import "../contracts/cross-chain/CrossChainAttester.sol";
import "../contracts/cross-chain/CrossChainAssigner.sol";

contract DeployMultiChain is Script {
    struct ChainConfig {
        uint256 chainId;
        string name;
        address layerZeroEndpoint;
        uint16 lzChainId;
        address ensRegistry;
        address kernelFactory;
        address kernelImplementation;
        address ccipGateway;
        string rpcUrl;
    }

    struct DeploymentAddresses {
        address moduleFactory;
        address frvmValidator;
        address walletFactory;
        address merchantAccount;
        address checkoutProcessor;
        address usernameRegistry;
        address frvmResolver;
        address crossChainAttester;
        address crossChainAssigner;
    }

    mapping(uint256 => ChainConfig) public chainConfigs;
    mapping(uint256 => DeploymentAddresses) public deployments;

    // Chain IDs for deployment
    uint256 constant ETHEREUM_SEPOLIA = 11155111;
    uint256 constant BASE_SEPOLIA = 84532;
    uint256 constant ARBITRUM_SEPOLIA = 421614;
    uint256 constant OPTIMISM_SEPOLIA = 11155420;
    uint256 constant POLYGON_AMOY = 80002;

    function setUp() public {
        // Ethereum Sepolia (L1 - ENS Registry)
        chainConfigs[ETHEREUM_SEPOLIA] = ChainConfig({
            chainId: ETHEREUM_SEPOLIA,
            name: "Ethereum Sepolia",
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            lzChainId: 40161,
            ensRegistry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e,
            kernelFactory: address(0),
            kernelImplementation: address(0),
            ccipGateway: address(0), // Will be deployed separately
            rpcUrl: vm.envString("SEPOLIA_RPC_URL")
        });

        // Base Sepolia
        chainConfigs[BASE_SEPOLIA] = ChainConfig({
            chainId: BASE_SEPOLIA,
            name: "Base Sepolia",
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            lzChainId: 40245,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0),
            ccipGateway: address(0),
            rpcUrl: vm.envString("BASE_SEPOLIA_RPC_URL")
        });

        // Arbitrum Sepolia
        chainConfigs[ARBITRUM_SEPOLIA] = ChainConfig({
            chainId: ARBITRUM_SEPOLIA,
            name: "Arbitrum Sepolia",
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            lzChainId: 40231,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0),
            ccipGateway: address(0),
            rpcUrl: vm.envString("ARBITRUM_SEPOLIA_RPC_URL")
        });

        // Optimism Sepolia
        chainConfigs[OPTIMISM_SEPOLIA] = ChainConfig({
            chainId: OPTIMISM_SEPOLIA,
            name: "Optimism Sepolia",
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            lzChainId: 40232,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0),
            ccipGateway: address(0),
            rpcUrl: vm.envString("OPTIMISM_SEPOLIA_RPC_URL")
        });

        // Polygon Amoy
        chainConfigs[POLYGON_AMOY] = ChainConfig({
            chainId: POLYGON_AMOY,
            name: "Polygon Amoy",
            layerZeroEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            lzChainId: 40267,
            ensRegistry: address(0),
            kernelFactory: address(0),
            kernelImplementation: address(0),
            ccipGateway: address(0),
            rpcUrl: vm.envString("POLYGON_AMOY_RPC_URL")
        });
    }

    function deployToChain(uint256 chainId) public returns (DeploymentAddresses memory) {
        ChainConfig memory config = chainConfigs[chainId];
        require(config.chainId != 0, "Chain not configured");

        console.log("\n========================================");
        console.log("Deploying to:", config.name);
        console.log("Chain ID:", config.chainId);
        console.log("========================================\n");

        vm.createSelectFork(config.rpcUrl);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        DeploymentAddresses memory addrs;

        // 1. Deploy Module Factory
        console.log("Deploying ModuleFactory...");
        ModuleFactory moduleFactory = new ModuleFactory(config.layerZeroEndpoint);
        addrs.moduleFactory = address(moduleFactory);
        console.log("ModuleFactory:", addrs.moduleFactory);

        // 2. Deploy Username Registry
        console.log("Deploying UsernameRegistry...");
        UsernameRegistry usernameRegistry = new UsernameRegistry();
        addrs.usernameRegistry = address(usernameRegistry);
        console.log("UsernameRegistry:", addrs.usernameRegistry);

        // 3. Deploy Face Recognition Validator via Module Factory
        console.log("Deploying FacialRecognitionValidator...");
        addrs.frvmValidator = moduleFactory.deployFRVMValidator(config.layerZeroEndpoint);
        console.log("FacialRecognitionValidator:", addrs.frvmValidator);

        // 4. Deploy ENS Resolver (L1 only)
        if (config.ensRegistry != address(0)) {
            console.log("Deploying FRVMResolver (L1 ENS)...");
            FRVMResolver resolver = new FRVMResolver(config.ensRegistry);
            addrs.frvmResolver = address(resolver);
            console.log("FRVMResolver:", addrs.frvmResolver);
        }

        // 5. Deploy Wallet Factory (if Kernel addresses provided)
        if (config.kernelFactory != address(0)) {
            console.log("Deploying FRVMWalletFactory...");
            FRVMWalletFactory walletFactory = new FRVMWalletFactory(
                config.kernelFactory,
                addrs.frvmValidator,
                config.kernelImplementation
            );
            addrs.walletFactory = address(walletFactory);
            console.log("FRVMWalletFactory:", addrs.walletFactory);
        }

        // 6. Deploy Merchant Account
        console.log("Deploying MerchantAccount...");
        MerchantAccount merchantAccount = new MerchantAccount(
            addrs.frvmValidator,
            addrs.usernameRegistry
        );
        addrs.merchantAccount = address(merchantAccount);
        console.log("MerchantAccount:", addrs.merchantAccount);

        // 7. Deploy Checkout Processor
        console.log("Deploying CheckoutProcessor...");
        CheckoutProcessor checkoutProcessor = new CheckoutProcessor(
            addrs.frvmValidator,
            addrs.usernameRegistry,
            addrs.merchantAccount
        );
        addrs.checkoutProcessor = address(checkoutProcessor);
        console.log("CheckoutProcessor:", addrs.checkoutProcessor);

        // 8. Deploy Cross Chain Attester
        console.log("Deploying CrossChainAttester...");
        CrossChainAttester attester = new CrossChainAttester(config.layerZeroEndpoint);
        addrs.crossChainAttester = address(attester);
        console.log("CrossChainAttester:", addrs.crossChainAttester);

        // 9. Deploy Cross Chain Assigner
        console.log("Deploying CrossChainAssigner...");
        CrossChainAssigner assigner = new CrossChainAssigner(config.layerZeroEndpoint);
        addrs.crossChainAssigner = address(assigner);
        console.log("CrossChainAssigner:", addrs.crossChainAssigner);

        // Set CCIP Gateway if available
        if (config.ccipGateway != address(0)) {
            attester.setCCIPGateway(config.ccipGateway);
            console.log("CCIP Gateway set:", config.ccipGateway);
        }

        vm.stopBroadcast();

        deployments[chainId] = addrs;
        
        console.log("\n[SUCCESS] Deployment Complete for", config.name);
        
        return addrs;
    }

    function deployAllChains() external {
        uint256[] memory chains = new uint256[](5);
        chains[0] = ETHEREUM_SEPOLIA;
        chains[1] = BASE_SEPOLIA;
        chains[2] = ARBITRUM_SEPOLIA;
        chains[3] = OPTIMISM_SEPOLIA;
        chains[4] = POLYGON_AMOY;

        for (uint256 i = 0; i < chains.length; i++) {
            deployToChain(chains[i]);
        }

        console.log("\n========================================");
        console.log("ALL DEPLOYMENTS COMPLETE");
        console.log("========================================\n");
        
        // After all deployments, configure cross-chain connections
        configureCrossChainConnections();
    }

    function configureCrossChainConnections() internal {
        console.log("\n========================================");
        console.log("CONFIGURING CROSS-CHAIN CONNECTIONS");
        console.log("========================================\n");

        uint256[] memory chains = new uint256[](5);
        chains[0] = ETHEREUM_SEPOLIA;
        chains[1] = BASE_SEPOLIA;
        chains[2] = ARBITRUM_SEPOLIA;
        chains[3] = OPTIMISM_SEPOLIA;
        chains[4] = POLYGON_AMOY;

        for (uint256 i = 0; i < chains.length; i++) {
            ChainConfig memory sourceConfig = chainConfigs[chains[i]];
            DeploymentAddresses memory sourceAddrs = deployments[chains[i]];
            
            vm.createSelectFork(sourceConfig.rpcUrl);
            vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

            console.log("\nConfiguring", sourceConfig.name, "...");

            // Configure trusted remotes for each other chain
            for (uint256 j = 0; j < chains.length; j++) {
                if (i != j) {
                    ChainConfig memory targetConfig = chainConfigs[chains[j]];
                    DeploymentAddresses memory targetAddrs = deployments[chains[j]];
                    
                    // Set trusted remote for validator
                    FacialRecognitionValidator(sourceAddrs.frvmValidator).setTrustedRemote(
                        targetConfig.lzChainId,
                        abi.encodePacked(targetAddrs.frvmValidator)
                    );
                    
                    // Set trusted remote for attester
                    CrossChainAttester(sourceAddrs.crossChainAttester).setTrustedRemote(
                        targetConfig.lzChainId,
                        abi.encodePacked(targetAddrs.crossChainAttester)
                    );
                    
                    // Set trusted remote for assigner
                    CrossChainAssigner(sourceAddrs.crossChainAssigner).setTrustedRemote(
                        targetConfig.lzChainId,
                        abi.encodePacked(targetAddrs.crossChainAssigner)
                    );

                    // Set chain validator in attester
                    CrossChainAttester(sourceAddrs.crossChainAttester).setChainValidator(
                        targetConfig.lzChainId,
                        targetAddrs.frvmValidator
                    );
                    
                    console.log("  - Connected to", targetConfig.name);
                }
            }

            vm.stopBroadcast();
        }

        console.log("\n[SUCCESS] Cross-chain connections configured");
    }

    function exportDeployments() external view {
        console.log("\n========================================");
        console.log("DEPLOYMENT ADDRESSES");
        console.log("========================================\n");

        uint256[] memory chains = new uint256[](5);
        chains[0] = ETHEREUM_SEPOLIA;
        chains[1] = BASE_SEPOLIA;
        chains[2] = ARBITRUM_SEPOLIA;
        chains[3] = OPTIMISM_SEPOLIA;
        chains[4] = POLYGON_AMOY;

        for (uint256 i = 0; i < chains.length; i++) {
            ChainConfig memory config = chainConfigs[chains[i]];
            DeploymentAddresses memory addrs = deployments[chains[i]];
            
            console.log(config.name, "(", config.chainId, "):");
            console.log("  ModuleFactory:", addrs.moduleFactory);
            console.log("  FRVMValidator:", addrs.frvmValidator);
            console.log("  UsernameRegistry:", addrs.usernameRegistry);
            console.log("  MerchantAccount:", addrs.merchantAccount);
            console.log("  CheckoutProcessor:", addrs.checkoutProcessor);
            console.log("  CrossChainAttester:", addrs.crossChainAttester);
            console.log("  CrossChainAssigner:", addrs.crossChainAssigner);
            
            if (addrs.walletFactory != address(0)) {
                console.log("  WalletFactory:", addrs.walletFactory);
            }
            if (addrs.frvmResolver != address(0)) {
                console.log("  FRVMResolver:", addrs.frvmResolver);
            }
            console.log("");
        }
    }
}