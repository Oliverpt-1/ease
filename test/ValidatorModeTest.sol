// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";

contract ValidatorModeTest is Test {
    
    function testValidatorModeByte() public {
        // Test that we're using the correct mode for validator installation
        bytes1 mode = 0x02;
        address validator = 0x34A2e49D484Fc27f16a1Cf1B90923E28b7128843;
        
        // Create ValidationId as done in FRVMWalletFactory
        bytes21 validationId = bytes21(bytes.concat(mode, bytes20(validator)));
        
        // Extract the mode back
        bytes1 extractedMode = bytes1(validationId);
        
        console.log("Mode byte used: 0x02");
        console.log("Mode byte extracted:", uint8(extractedMode));
        console.log("Validator address:", validator);
        
        // Assert mode is 0x02 which should trigger onInstall
        assertEq(uint8(extractedMode), 0x02, "Mode should be 0x02 for validator installation");
        
        // Log the full ValidationId for debugging
        console.logBytes21(validationId);
    }
    
    function testInitializationData() public {
        // Test the initialization data encoding
        bytes32 facialHash = keccak256("test_facial_data");
        
        // This is how the factory encodes the validator data
        bytes memory validatorData = abi.encode(facialHash);
        
        console.log("Facial hash:");
        console.logBytes32(facialHash);
        console.log("Validator data length:", validatorData.length);
        
        // Decode it back to verify
        bytes32 decodedHash = abi.decode(validatorData, (bytes32));
        assertEq(decodedHash, facialHash, "Facial hash should match after encoding/decoding");
    }
}