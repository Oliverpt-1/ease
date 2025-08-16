// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../contracts/validators/faceRecognitionValidator.sol";
import "../contracts/cross-chain/CrossChainAttester.sol";

contract SetupCrossChain is Script {
    struct ChainConfig {
        uint16 lzChainId;
        address validatorAddress;
        address attesterAddress;
        bytes trustedRemotePath;
    }

    mapping(uint256 => ChainConfig) public chainConfigs;

    function setUp() public {
        // Ethereum Sepolia
        chainConfigs[11155111] = ChainConfig({
            lzChainId: 10161,
            validatorAddress: address(0), // Fill after deployment
            attesterAddress: address(0),
            trustedRemotePath: abi.encodePacked(address(0)) // Will be set after all deployments
        });

        // Polygon Mumbai
        chainConfigs[80001] = ChainConfig({
            lzChainId: 10109,
            validatorAddress: address(0),
            attesterAddress: address(0),
            trustedRemotePath: abi.encodePacked(address(0))
        });

        // Base Sepolia
        chainConfigs[84532] = ChainConfig({
            lzChainId: 10160,
            validatorAddress: address(0),
            attesterAddress: address(0),
            trustedRemotePath: abi.encodePacked(address(0))
        });
    }

    function run() external {
        uint256 currentChain = block.chainid;
        ChainConfig memory currentConfig = chainConfigs[currentChain];
        
        require(currentConfig.validatorAddress != address(0), "Validator not deployed");

        vm.startBroadcast();

        FacialRecognitionValidator validator = FacialRecognitionValidator(currentConfig.validatorAddress);
        CrossChainAttester attester = CrossChainAttester(currentConfig.attesterAddress);

        // Set up trusted remotes for other chains
        for (uint256 chainId = 11155111; chainId <= 84532; chainId++) {
            if (chainId == currentChain) continue;
            
            ChainConfig memory remoteConfig = chainConfigs[chainId];
            if (remoteConfig.validatorAddress == address(0)) continue;

            // Set trusted remote for validator
            bytes memory remotePath = abi.encodePacked(remoteConfig.validatorAddress);
            validator.setTrustedRemote(remoteConfig.lzChainId, remotePath);
            
            // Set trusted remote for attester
            bytes memory attesterPath = abi.encodePacked(remoteConfig.attesterAddress);
            attester.setTrustedRemote(remoteConfig.lzChainId, attesterPath);

            console.log("Set trusted remote for chain", chainId, ":", remoteConfig.lzChainId);
        }

        vm.stopBroadcast();

        console.log("Cross-chain setup completed for chain:", currentChain);
    }

    function setAddresses(
        uint256 chainId,
        address validator,
        address attester
    ) external {
        chainConfigs[chainId].validatorAddress = validator;
        chainConfigs[chainId].attesterAddress = attester;
    }
}