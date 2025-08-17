// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";

interface IENSRegistry {
    function resolver(bytes32 node) external view returns (address);
    function owner(bytes32 node) external view returns (address);
}

interface IResolver {
    function addr(bytes32 node) external view returns (address);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract CheckENS is Script {
    IENSRegistry constant ENS = IENSRegistry(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    
    function run() external view {
        // Calculate namehash for eaze.eth
        bytes32 eazeNode = namehash("eaze.eth");
        
        console.log("\n=== ENS Configuration Check ===");
        console.log("ENS Registry:", address(ENS));
        console.log("eaze.eth namehash:", uint256(eazeNode));
        
        // Check owner
        address owner = ENS.owner(eazeNode);
        console.log("\neaze.eth owner:", owner);
        
        // Check resolver
        address resolver = ENS.resolver(eazeNode);
        console.log("eaze.eth resolver:", resolver);
        
        if (resolver != address(0)) {
            // Check if resolver supports required interfaces
            IResolver resolverContract = IResolver(resolver);
            
            console.log("\nResolver Interface Support:");
            console.log("- ERC165 (0x01ffc9a7):", resolverContract.supportsInterface(0x01ffc9a7));
            console.log("- addr (0x3b3b57de):", resolverContract.supportsInterface(0x3b3b57de));
            console.log("- ENSIP-10 (0x9061b923):", resolverContract.supportsInterface(0x9061b923));
            
            // Try to resolve a test subdomain
            bytes32 testNode = namehash("test48.eaze.eth");
            console.log("\nTest resolution for test48.eaze.eth:");
            console.log("Node:", uint256(testNode));
            
            try resolverContract.addr(testNode) returns (address wallet) {
                console.log("Resolved address:", wallet);
            } catch {
                console.log("Failed to resolve via addr(bytes32)");
            }
        }
    }
    
    function namehash(string memory name) internal pure returns (bytes32) {
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        
        if (bytes(name).length == 0) {
            return node;
        }
        
        // Split and process from right to left
        bytes memory nameBytes = bytes(name);
        uint256 labelStart = nameBytes.length;
        
        for (int256 i = int256(nameBytes.length) - 1; i >= -1; i--) {
            if (i == -1 || nameBytes[uint256(i)] == ".") {
                uint256 labelEnd = uint256(i + 1);
                uint256 labelLength = labelStart - labelEnd;
                
                if (labelLength > 0) {
                    bytes memory label = new bytes(labelLength);
                    for (uint256 j = 0; j < labelLength; j++) {
                        label[j] = nameBytes[labelEnd + j];
                    }
                    
                    node = keccak256(abi.encodePacked(node, keccak256(label)));
                }
                
                labelStart = uint256(i);
            }
        }
        
        return node;
    }
}