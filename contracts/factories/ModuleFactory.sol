// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../validators/faceRecognitionValidator.sol";

contract ModuleFactory {
    mapping(address => bool) public isDeployedModule;
    
    event ModuleDeployed(address indexed module, address indexed deployer, uint256 chainId);

    function deployFRVMValidator(address lzEndpoint) external returns (address) {
        FacialRecognitionValidator validator = new FacialRecognitionValidator(lzEndpoint);
        
        isDeployedModule[address(validator)] = true;
        
        emit ModuleDeployed(address(validator), msg.sender, block.chainid);
        
        return address(validator);
    }

    function predictValidatorAddress(
        address lzEndpoint,
        uint256 salt
    ) external view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(
                    type(FacialRecognitionValidator).creationCode,
                    abi.encode(lzEndpoint)
                ))
            )
        );
        return address(uint160(uint256(hash)));
    }

    function deployValidatorWithSalt(
        address lzEndpoint,
        uint256 salt
    ) external returns (address) {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(
            type(FacialRecognitionValidator).creationCode,
            abi.encode(lzEndpoint)
        ));

        address validator;
        assembly {
            validator := create2(0, add(bytecodeHash, 0x20), mload(bytecodeHash), salt)
        }
        
        require(validator != address(0), "Deployment failed");
        
        isDeployedModule[validator] = true;
        
        emit ModuleDeployed(validator, msg.sender, block.chainid);
        
        return validator;
    }
}