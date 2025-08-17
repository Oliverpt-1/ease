// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";

interface IKernelFactory {
    // Regular Kernel Factory signature (not Meta Factory)
    function createAccount(
        bytes calldata data,
        bytes32 salt
    ) external payable returns (address);
}

interface IKernel {
    function initialize(
        bytes21 _rootValidator,
        address hook,
        bytes calldata validatorData,
        bytes calldata hookData
    ) external;
    
    function installModule(
        uint256 moduleType,
        address module,
        bytes calldata data
    ) external;
}

contract FRVMWalletFactory {
    IKernelFactory public immutable kernelFactory;
    IFaceRecognitionValidator public immutable frvmValidator;
    address public immutable kernelImplementation;

    mapping(string => address) public subdomainToWallet;
    mapping(address => string) public walletToSubdomain;
    mapping(bytes32 => uint256) public nextWalletIndex;
    mapping(bytes32 => address) public nameToWallet; // ENS node to wallet address

    event WalletDeployed(
        address indexed wallet,
        string username,
        bytes32 facialHash,
        uint256 index
    );
    
    event WalletCreated(address indexed wallet, string username);

    constructor(
        address _kernelFactory,
        address _frvmValidator,
        address _kernelImplementation
    ) {
        kernelFactory = IKernelFactory(_kernelFactory);
        frvmValidator = IFaceRecognitionValidator(_frvmValidator);
        kernelImplementation = _kernelImplementation;
    }

    function createWallet(
        string calldata username,
        bytes32 facialHash,
        uint256[] calldata facialEmbedding
    ) external returns (address wallet) {
        require(subdomainToWallet[username] == address(0), "Username already taken");
        require(facialHash != bytes32(0), "Invalid facial hash");
        
        uint256 index = nextWalletIndex[facialHash];
        bytes32 salt = keccak256(abi.encodePacked(facialHash, index));
        
        // Create ValidationId for our validator (mode 0x01 + validator address)
        bytes21 validationId = bytes21(bytes.concat(bytes1(0x01), bytes20(address(frvmValidator))));
        
        // Prepare initialization calldata for Kernel
        bytes memory initData = abi.encodeWithSelector(
            IKernel.initialize.selector,
            validationId,                    // _rootValidator as ValidationId
            address(0),                       // hook (none)
            abi.encode(facialHash, facialEmbedding), // validatorData with facial hash and embedding
            ""                               // hookData (empty)
        );
        
        // Create account through Kernel Factory (v3 direct call)
        wallet = kernelFactory.createAccount(
            initData,
            salt
        );
        
        // Note: Module installation must be done separately after wallet creation
        // The validator's onInstall will be called when the module is installed
        // This can be done through a separate transaction by the wallet owner
        
        //not encoding the node correctly
        // Compute ENS node for subdomain
        bytes32 rootNode = _namehash("eaze.eth");
        bytes32 labelHash = keccak256(bytes(username));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelHash));

        // Store mappings
        nameToWallet[node] = wallet;
        subdomainToWallet[username] = wallet;
        walletToSubdomain[wallet] = username;
        nextWalletIndex[facialHash] = index + 1;

        emit WalletDeployed(wallet, username, facialHash, index);
        emit WalletCreated(wallet, username);

        return wallet;
    }

    // ENS Resolver: addr
    function addr(bytes32 node) external view returns (address) {
        return nameToWallet[node];
    }

    // supportsInterface: For ERC-165 and ENS addr interface
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC-165
               interfaceId == 0x3b3b57de || // ENS addr
               interfaceId == 0x9061b923;   // ENS wildcard resolution
    }

    // ENSIP-10 Wildcard Resolution
    // https://docs.ens.domains/ensip/10
    function resolve(bytes calldata, bytes calldata data) external view returns(bytes memory) {
        (, bytes memory result) = address(this).staticcall(data);
        return result;
    }

    function getWalletSubdomain(address wallet) external view returns (string memory) {
        return walletToSubdomain[wallet];
    }

    // Helper function for merchant contracts to resolve usernames
    function resolveUsername(string calldata username) external view returns (address) {
        // Compute ENS node for username.eaze.eth
        bytes32 rootNode = _namehash("eaze.eth");
        bytes32 labelHash = keccak256(bytes(username));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelHash));
        
        // Return the wallet address for this ENS node
        return nameToWallet[node];
    }

    // Internal namehash helper - ENS compliant
    function _namehash(string memory name) internal pure returns (bytes32) {
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        
        // Handle empty string
        if (bytes(name).length == 0) {
            return node;
        }
        
        // Split into labels and process from right to left (TLD first)
        bytes memory nameBytes = bytes(name);
        uint256 labelStart = nameBytes.length;
        
        // Process from end to beginning
        for (int256 i = int256(nameBytes.length) - 1; i >= -1; i--) {
            if (i == -1 || nameBytes[uint256(i)] == ".") {
                // Found a separator or reached the beginning
                uint256 labelEnd = uint256(i + 1);
                uint256 labelLength = labelStart - labelEnd;
                
                if (labelLength > 0) {
                    // Extract label
                    bytes memory label = new bytes(labelLength);
                    for (uint256 j = 0; j < labelLength; j++) {
                        label[j] = nameBytes[labelEnd + j];
                    }
                    
                    // Update node: node = keccak256(node || keccak256(label))
                    node = keccak256(abi.encodePacked(node, keccak256(label)));
                }
                
                labelStart = uint256(i);
            }
        }
        
        return node;
    }

    // Internal substring helper
    function _substring(string memory str, uint256 start, uint256 len) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(len);
        for (uint256 k = 0; k < len; k++) {
            result[k] = strBytes[start + k];
        }
        return string(result);
    }
}