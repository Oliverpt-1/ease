// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";

interface IKernelFactory {
    function createAccount(
        address implementation,
        bytes calldata data,
        uint256 salt
    ) external returns (address);
}

interface IKernelAccount {
    function initialize(address validator, bytes calldata data) external;
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
        bytes32 facialHash
    ) external returns (address wallet) {
        require(subdomainToWallet[username] == address(0), "Username already taken");
        require(facialHash != bytes32(0), "Invalid facial hash");
        
        uint256 index = nextWalletIndex[facialHash];
        bytes32 salt = keccak256(abi.encodePacked(facialHash, index));
        
        wallet = kernelFactory.createAccount(
            kernelImplementation,
            abi.encode(facialHash, index),
            uint256(salt)
        );

        IKernelAccount(wallet).initialize(
            address(frvmValidator),
            abi.encode(facialHash)
        );

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
               interfaceId == 0x3b3b57de;  // ENS addr
    }

    function resolve(string calldata subdomain) external view returns (address) {
        return subdomainToWallet[subdomain];
    }

    function getWalletSubdomain(address wallet) external view returns (string memory) {
        return walletToSubdomain[wallet];
    }

    // Internal namehash helper
    function _namehash(string memory name) internal pure returns (bytes32) {
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        uint256 len = bytes(name).length;
        uint256 i = len;
        while (i > 0) {
            uint256 j = i;
            while (j > 0 && bytes(name)[j - 1] != ".") j--;
            string memory label = _substring(name, j, i - j);
            node = keccak256(abi.encodePacked(node, keccak256(bytes(label))));
            i = j > 0 ? j - 1 : 0;
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