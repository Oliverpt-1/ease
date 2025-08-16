// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../validators/faceRecognitionValidator.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

contract ModuleFactory {
    struct ModuleDeployment {
        address moduleAddress;
        address deployer;
        uint256 deploymentTimestamp;
        uint256 chainId;
        string version;
    }

    mapping(address => bool) public isDeployedModule;
    mapping(address => ModuleDeployment) public moduleDeployments;
    mapping(uint256 => address[]) public chainModules;
    address[] public allModules;
    
    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    
    event ModuleDeployed(address indexed module, address indexed deployer, uint256 chainId, string version);
    event CrossChainModuleRegistered(address indexed module, uint16 srcChainId);

    constructor(address _lzEndpoint) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function registerExistingModule(address module, string memory version) external {
        require(module != address(0), "Invalid module address");
        require(!isDeployedModule[module], "Module already registered");
        
        _registerModule(module, version);
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
        address _lzEndpoint,
        uint256 salt
    ) external returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(FacialRecognitionValidator).creationCode,
            abi.encode(_lzEndpoint)
        );

        address validator;
        assembly {
            validator := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        require(validator != address(0), "Deployment failed");
        
        _registerModule(validator, "1.0.0");
        
        return validator;
    }

    function _registerModule(address module, string memory version) internal {
        isDeployedModule[module] = true;
        
        moduleDeployments[module] = ModuleDeployment({
            moduleAddress: module,
            deployer: msg.sender,
            deploymentTimestamp: block.timestamp,
            chainId: block.chainid,
            version: version
        });
        
        chainModules[block.chainid].push(module);
        allModules.push(module);
        
        emit ModuleDeployed(module, msg.sender, block.chainid, version);
    }

    function propagateModuleToChain(
        address module,
        uint16 targetChainId
    ) external payable {
        require(isDeployedModule[module], "Module not deployed");
        
        ModuleDeployment memory deployment = moduleDeployments[module];
        
        bytes memory payload = abi.encode(
            module,
            deployment.deployer,
            deployment.version,
            block.chainid
        );
        
        lzEndpoint.send{value: msg.value}(
            targetChainId,
            trustedRemoteLookup[targetChainId],
            payload,
            payable(msg.sender),
            address(0),
            bytes("")
        );
    }

    function getChainModules(uint256 chainId) external view returns (address[] memory) {
        return chainModules[chainId];
    }

    function getAllModules() external view returns (address[] memory) {
        return allModules;
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _path) external {
        trustedRemoteLookup[_chainId] = _path;
    }
}