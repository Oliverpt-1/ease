// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {faceRecognitionValidator} from "../contracts/validators/faceRecognitionValidator.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";
import {MerchantAccount} from "../contracts/merchants/MerchantAccount.sol";
import {CheckoutProcessor} from "../contracts/merchants/CheckoutProcessor.sol";

// Concrete implementation of the abstract validator for deployment
contract FaceRecognitionValidatorImpl is faceRecognitionValidator {
    uint256 public constant MODULE_TYPE_VALIDATOR = 1;
    
    mapping(string => address) private usernameToUser;
    mapping(address => string) private userToUsername;
    
    function registerUser(
        string calldata username,
        bytes32 facialHash,
        uint256 // index parameter unused
    ) external {
        require(!isInitialized[msg.sender], "Already registered");
        require(bytes(username).length > 0, "Username required");
        require(usernameToUser[username] == address(0), "Username taken");
        
        userFacialHash[msg.sender] = facialHash;
        isInitialized[msg.sender] = true;
        usernameToUser[username] = msg.sender;
        userToUsername[msg.sender] = username;
        
        emit UserRegistered(msg.sender, username, facialHash);
    }
    
    function updateFacialHash(bytes32 newFacialHash) external {
        require(isInitialized[msg.sender], "Not registered");
        require(newFacialHash != bytes32(0), "Invalid facial hash");
        
        bytes32 oldHash = userFacialHash[msg.sender];
        userFacialHash[msg.sender] = newFacialHash;
        
        emit FacialHashUpdated(msg.sender, oldHash, newFacialHash);
    }
    
    function getUserByUsername(string calldata username) external view returns (address) {
        return usernameToUser[username];
    }
    
    function generateWalletSalt(bytes32 facialHash, uint256 index) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(facialHash, index));
    }
}

contract DeployOnly is Script {
    // Kernel v3 addresses on Ethereum Sepolia (ZeroDev)
    address constant KERNEL_FACTORY = 0x6723b44Abeec4E71eBE3232BD5B455805baDD22f;
    address constant KERNEL_IMPL = 0x94F097E1ebEB4ecA3AAE54cabb08905B239A7D27;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("\n=== Deploying FRVM System on Ethereum Sepolia ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy FRVM Validator
        address frvmValidator = address(new FaceRecognitionValidatorImpl());
        console.log("[DEPLOYED] FRVMValidator:", frvmValidator);
        
        // 2. Deploy FRVM Wallet Factory
        address walletFactory = address(new FRVMWalletFactory(
            KERNEL_FACTORY,
            frvmValidator,
            KERNEL_IMPL
        ));
        console.log("[DEPLOYED] WalletFactory:", walletFactory);
        
        // 3. Deploy Merchant Account
        address merchantAccount = address(new MerchantAccount(
            frvmValidator,
            walletFactory
        ));
        console.log("[DEPLOYED] MerchantAccount:", merchantAccount);
        
        // 4. Deploy Checkout Processor
        address checkoutProcessor = address(new CheckoutProcessor(
            frvmValidator,
            walletFactory,
            merchantAccount
        ));
        console.log("[DEPLOYED] CheckoutProcessor:", checkoutProcessor);
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT SUCCESSFUL ===");
        console.log("\nExport these for your environment:");
        console.log("export FRVM_VALIDATOR=%s", frvmValidator);
        console.log("export WALLET_FACTORY=%s", walletFactory);
        console.log("export MERCHANT_ACCOUNT=%s", merchantAccount);
        console.log("export CHECKOUT_PROCESSOR=%s", checkoutProcessor);
        
        console.log("\nNext steps:");
        console.log("1. Verify the contracts on Etherscan");
        console.log("2. Create wallets using the factory");
        console.log("3. Set up ENS resolver for eaze.eth domain");
    }
}