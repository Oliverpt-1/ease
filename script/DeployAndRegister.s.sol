// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {FacialRecognitionValidator} from "../contracts/validators/faceRecognitionValidator.sol";
import {FRVMWalletFactory} from "../contracts/factories/FRVMWalletFactory.sol";
import {MerchantAccount} from "../contracts/merchants/MerchantAccount.sol";
import {CheckoutProcessor} from "../contracts/merchants/CheckoutProcessor.sol";
import {Bootstrap} from "../lib/erc7579-implementation/src/utils/Bootstrap.sol";

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

contract DeployAndRegister is Script {
    // Kernel v3 addresses on Ethereum Sepolia
    address constant KERNEL_META_FACTORY = 0xd703aaE79538628d27099B8c4f621bE4CCd142d5;
    address constant KERNEL_IMPL = 0xd6CEDDe84be40893d153Be9d467CD6aD37875b28;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("\n=== Deploying FRVM System on Ethereum Sepolia ===");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy FRVM Validator
        address frvmValidator = address(new FaceRecognitionValidatorImpl());
        console.log("[OK] FRVMValidator:", frvmValidator);
        
        // Deploy Bootstrap contract
        address payable bootstrapContract = payable(address(new Bootstrap()));
        console.log("[OK] Bootstrap:", bootstrapContract);
        
        // 2. Deploy FRVM Wallet Factory
        address walletFactory = address(new FRVMWalletFactory(
            KERNEL_META_FACTORY,
            frvmValidator,
            KERNEL_IMPL
        ));
        console.log("[OK] WalletFactory:", walletFactory);
        
        // 3. Deploy Merchant Account
        address merchantAccount = address(new MerchantAccount(
            frvmValidator,
            walletFactory
        ));
        console.log("[OK] MerchantAccount:", merchantAccount);
        
        // 4. Deploy Checkout Processor
        address checkoutProcessor = address(new CheckoutProcessor(
            frvmValidator,
            walletFactory,
            merchantAccount
        ));
        console.log("[OK] CheckoutProcessor:", checkoutProcessor);
        
        // 5. Create test wallets with ENS names
        console.log("\n=== Creating Test Wallets ===");
        
        // Test wallet 1: alice.eaze.eth
        bytes32 aliceFacialHash = keccak256(abi.encodePacked("alice_face_data"));
        address aliceWallet = FRVMWalletFactory(walletFactory).createWallet("alice", aliceFacialHash);
        console.log("[OK] alice.eaze.eth =>", aliceWallet);
        
        // Test wallet 2: bob.eaze.eth
        bytes32 bobFacialHash = keccak256(abi.encodePacked("bob_face_data"));
        address bobWallet = FRVMWalletFactory(walletFactory).createWallet("bob", bobFacialHash);
        console.log("[OK] bob.eaze.eth =>", bobWallet);
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("\nContracts:");
        console.log("export FRVM_VALIDATOR=%s", frvmValidator);
        console.log("export WALLET_FACTORY=%s", walletFactory);
        console.log("export MERCHANT_ACCOUNT=%s", merchantAccount);
        console.log("export CHECKOUT_PROCESSOR=%s", checkoutProcessor);
        
        console.log("\nTest Wallets:");
        console.log("- alice.eaze.eth =>", aliceWallet);
        console.log("- bob.eaze.eth =>", bobWallet);
        
        console.log("\n[SUCCESS] ENS Resolution Ready!");
        console.log("The factory can now resolve username.eaze.eth to wallet addresses");
    }
}