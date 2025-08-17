// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/validators/faceRecognitionValidator.sol";
import "../contracts/interfaces/IfaceRecognitionValidator.sol";

/**
 * @title Facial Validation Integration Test
 * @notice Integration tests that call the actual deployed contracts on Sepolia
 * @dev These tests interact with real deployed contracts and Chainlink services
 */
contract FacialValidationIntegrationTest is Test {
    // Deployed contract addresses on Sepolia
    address constant VALIDATOR_ADDRESS = 0x3356f1D40068bD3f05b81B0e83Fb0c58d9030574;
    address constant CHAINLINK_VALIDATOR = 0xb0E7ceeA189C96dBFf02aC7819699Dcf1F81b95b;
    address constant FACTORY_ADDRESS = 0x65887f28026218556CCDfc6012705f98DB1E5dbe;
    
    // Test addresses - using real ENS and wallet
    address public testUser1 = 0x861CFf1AebEEAd101e7D2629f0097bC3e4Ec3e81; // bro.eaze.eth
    address public testUser2 = address(0x2222);
    string public testENS = "bro.eaze.eth";
    
    // Test facial data - using the same format as your frontend
    uint256[] public testEmbedding1;
    uint256[] public testEmbedding2;
    bytes32 public testFacialHash1;
    bytes32 public testFacialHash2;
    
    IFaceRecognitionValidator public validator;
    
    function setUp() public {
        // Fork Sepolia for testing
        string memory sepoliaRpc = vm.envString("SEPOLIA_RPC_URL");
        vm.createFork(sepoliaRpc);
        
        // Initialize contract at deployed address
        validator = IFaceRecognitionValidator(VALIDATOR_ADDRESS);
        
        // Generate random test embedding (simulating "fake fetched" reference embedding)
        testEmbedding1 = new uint256[](512);
        for (uint i = 0; i < 512; i++) {
            testEmbedding1[i] = uint256(keccak256(abi.encode(i, "random"))) % 2000000; // Random values
        }
        
        // testEmbedding2 will be fetched from storage in the test
        
        testFacialHash1 = keccak256(abi.encodePacked(testEmbedding1));
        // testFacialHash2 will be set when we fetch stored embedding
        
        // Fund test addresses
        vm.deal(testUser1, 1 ether);
        vm.deal(testUser2, 1 ether);
    }
    
    function testValidatorAddressSetup() public view {
        // Verify we're testing against the right contract
        assertEq(address(validator), VALIDATOR_ADDRESS);
    }
    
    function testFacialSignatureValidationFlow() public {
        // Skip if we don't have RPC access
        if (block.chainid != 11155111) {
            vm.skip(true);
        }
        
        console.log("Testing facial signature validation with storage retrieval...");
        console.log("Testing with ENS:", testENS);
        console.log("Wallet address:", testUser1);
        
        // Step 1: Check if user is already registered and get stored embedding
        IFaceRecognitionValidator.UserData memory userData;
        uint256[] memory storedEmbedding;
        
        try validator.getUserData(testUser1) returns (IFaceRecognitionValidator.UserData memory data) {
            userData = data;
            console.log("User data found:");
            console.log("  Registered:", userData.isRegistered);
            console.log("  Username:", userData.username);
            
            if (userData.isRegistered && userData.encodedEmbedding.length > 0) {
                // Fetch the stored embedding from user's wallet storage
                storedEmbedding = abi.decode(userData.encodedEmbedding, (uint256[]));
                console.log("Retrieved stored embedding from user storage");
                console.log("  Stored embedding length:", storedEmbedding.length);
                console.log("  First 5 stored values:");
                for (uint i = 0; i < 5 && i < storedEmbedding.length; i++) {
                    console.log("    [", i, "]:", storedEmbedding[i]);
                }
            } else {
                console.log("User not registered or no embedding stored");
                return;
            }
        } catch {
            console.log("No user data found - user needs to be registered first");
            return;
        }
        
        // Step 2: Test facial signature validation with random reference embedding
        console.log("Testing storage vs random embedding comparison...");
        console.log("Random reference embedding (first 5 values):");
        for (uint i = 0; i < 5; i++) {
            console.log("    [", i, "]:", testEmbedding1[i]);
        }
        
        // Create facial signature with random reference embedding
        IFaceRecognitionValidator.FacialSignature memory facialSig;
        facialSig.facialHash = testFacialHash1;
        facialSig.timestamp = block.timestamp;
        facialSig.signature = abi.encode(testEmbedding1); // Random reference embedding
        
        console.log("Comparison summary:");
        console.log("  Stored embedding length:", storedEmbedding.length);
        console.log("  Reference embedding length:", testEmbedding1.length);
        console.log("  Storage test: Successfully retrieved user's stored embedding");
        console.log("  Ready for Chainlink comparison between stored vs reference");
    }
    
    function testChainlinkIntegrationDirect() public {
        // Skip if we don't have RPC access
        if (block.chainid != 11155111) {
            vm.skip(true);
        }
        
        console.log("Testing direct Chainlink facial validator integration...");
        
        // Test the Chainlink validator directly
        IChainlinkFacialValidator chainlinkValidator = IChainlinkFacialValidator(CHAINLINK_VALIDATOR);
        
        // Prepare args like the validator would
        string[] memory args = new string[](2);
        args[0] = _arrayToString(testEmbedding1); // Source embedding
        args[1] = _arrayToString(testEmbedding2); // Target embedding
        
        console.log("Calling Chainlink validator with subscription ID 5463...");
        console.log("Source embedding (first 5 values):");
        for (uint i = 0; i < 5 && i < testEmbedding1.length; i++) {
            console.log("  ", testEmbedding1[i]);
        }
        
        console.log("Target embedding (first 5 values):");
        for (uint i = 0; i < 5 && i < testEmbedding2.length; i++) {
            console.log("  ", testEmbedding2[i]);
        }
        
        // This will make the actual Chainlink request
        try chainlinkValidator.sendRequest(5463, args) {
            console.log("Chainlink request sent successfully");
            
            // Wait a bit and check for result
            vm.warp(block.timestamp + 60); // Advance time
            
            try chainlinkValidator.verificationResult() returns (string memory result) {
                console.log("Verification result:", result);
            } catch {
                console.log("Verification result not yet available (Chainlink callback pending)");
            }
            
        } catch Error(string memory reason) {
            console.log("Chainlink request failed:", reason);
        }
    }
    
    function testFacialValidationWithDifferentEmbeddings() public {
        if (block.chainid != 11155111) {
            vm.skip(true);
        }
        
        console.log("Testing facial validation with different embeddings (should fail)...");
        
        // Setup user with one embedding
        vm.prank(testUser1);
        try validator.registerUser("testuser1", testFacialHash1, 1) {
            console.log("User registered with embedding 1");
        } catch {
            console.log("User registration failed");
            return;
        }
        
        // Try to validate with a different embedding
        IFaceRecognitionValidator.FacialSignature memory facialSig;
        facialSig.facialHash = testFacialHash2; // Different hash
        facialSig.timestamp = block.timestamp;
        facialSig.signature = abi.encode(testEmbedding2); // Different embedding
        
        console.log("Testing validation with mismatched embedding...");
        // This should fail when properly implemented
    }
    
    function testEmbeddingToStringConversion() public {
        console.log("Testing embedding to string conversion...");
        
        // Test with small array first
        uint256[] memory smallEmbedding = new uint256[](3);
        smallEmbedding[0] = 1000000;
        smallEmbedding[1] = 2000000; 
        smallEmbedding[2] = 3000000;
        
        string memory result = _arrayToString(smallEmbedding);
        console.log("Small embedding as string:", result);
        
        // Should be "[1000000,2000000,3000000]"
        assertEq(result, "[1000000,2000000,3000000]");
        
        // Test with full embedding
        string memory fullResult = _arrayToString(testEmbedding1);
        console.log("Full embedding string length:", bytes(fullResult).length);
        
        // Log first 100 characters to verify format
        if (bytes(fullResult).length > 100) {
            console.log("First 100 chars:", _substring(fullResult, 0, 100));
        }
    }
    
    function testUserDataRetrieval() public view {
        if (block.chainid != 11155111) {
            return;
        }
        
        console.log("Testing user data retrieval for existing users...");
        
        // Try to get data for a test address
        try validator.getUserData(testUser1) returns (IFaceRecognitionValidator.UserData memory userData) {
            console.log("User data retrieved:");
            console.log("  Registered:", userData.isRegistered);
            console.log("  Username:", userData.username);
            console.log("  Registration timestamp:", userData.registrationTimestamp);
        } catch {
            console.log("No user data found (user not registered)");
        }
    }
    
    // Helper function to convert array to string (mirrors contract logic)
    function _arrayToString(uint256[] memory arr) internal pure returns (string memory) {
        if (arr.length == 0) return "[]";
        
        bytes memory result = abi.encodePacked("[");
        for (uint256 i = 0; i < arr.length; i++) {
            if (i > 0) {
                result = abi.encodePacked(result, ",");
            }
            result = abi.encodePacked(result, _toString(arr[i]));
        }
        result = abi.encodePacked(result, "]");
        return string(result);
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function _substring(string memory str, uint256 start, uint256 length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length && start + i < strBytes.length; i++) {
            result[i] = strBytes[start + i];
        }
        return string(result);
    }
}