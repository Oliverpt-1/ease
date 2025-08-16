// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IENS {
    function resolver(bytes32 node) external view returns (address);
    function setResolver(bytes32 node, address resolver) external;
}

interface IENSResolver {
    function addr(bytes32 node) external view returns (address);
    function setAddr(bytes32 node, address addr) external;
    function name(bytes32 node) external view returns (string memory);
    function setName(bytes32 node, string memory name) external;
}

contract FRVMResolver is IENSResolver {
    IENS public immutable ens;
    
    mapping(bytes32 => address) public addresses;
    mapping(bytes32 => string) public names;
    mapping(address => string) public usernames;
    mapping(string => address) public usernameToAddress;
    
    event AddressChanged(bytes32 indexed node, address addr);
    event NameChanged(bytes32 indexed node, string name);
    event UsernameRegistered(address indexed user, string username);

    modifier onlyOwner(bytes32 node) {
        require(msg.sender == ens.resolver(node), "Unauthorized");
        _;
    }

    constructor(address _ens) {
        ens = IENS(_ens);
    }

    function addr(bytes32 node) external view override returns (address) {
        return addresses[node];
    }

    function setAddr(bytes32 node, address newAddr) external override onlyOwner(node) {
        addresses[node] = newAddr;
        emit AddressChanged(node, newAddr);
    }

    function name(bytes32 node) external view override returns (string memory) {
        return names[node];
    }

    function setName(bytes32 node, string memory newName) external override onlyOwner(node) {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    function registerUsername(string calldata username, address user) external {
        require(usernameToAddress[username] == address(0), "Username taken");
        require(bytes(usernames[user]).length == 0, "User already has username");
        
        usernames[user] = username;
        usernameToAddress[username] = user;
        
        emit UsernameRegistered(user, username);
    }

    function resolveUsername(string calldata username) external view returns (address) {
        return usernameToAddress[username];
    }

    function getUserUsername(address user) external view returns (string memory) {
        return usernames[user];
    }

    function namehash(string memory domain) public pure returns (bytes32) {
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        
        if (bytes(domain).length == 0) {
            return node;
        }
        
        bytes memory domainBytes = bytes(domain);
        bytes memory label;
        uint256 start = 0;
        
        for (uint256 i = domainBytes.length; i > 0; i--) {
            if (domainBytes[i-1] == 0x2e) { // '.'
                label = new bytes(i - start - 1);
                for (uint256 j = 0; j < label.length; j++) {
                    label[j] = domainBytes[start + j];
                }
                node = keccak256(abi.encodePacked(node, keccak256(label)));
                start = i;
            }
        }
        
        if (start < domainBytes.length) {
            label = new bytes(domainBytes.length - start);
            for (uint256 j = 0; j < label.length; j++) {
                label[j] = domainBytes[start + j];
            }
            node = keccak256(abi.encodePacked(node, keccak256(label)));
        }
        
        return node;
    }
}