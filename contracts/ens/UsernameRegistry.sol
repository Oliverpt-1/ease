// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract UsernameRegistry {
    struct UserProfile {
        string username;
        address wallet;
        bytes32 facialHash;
        uint256 registrationTimestamp;
        bool isActive;
    }

    mapping(string => address) public usernameToWallet;
    mapping(address => string) public walletToUsername;
    mapping(address => UserProfile) public userProfiles;
    mapping(bytes32 => address) public facialHashToWallet;

    string[] public allUsernames;
    
    event UsernameRegistered(string indexed username, address indexed wallet, bytes32 facialHash);
    event UsernameUpdated(string oldUsername, string newUsername, address indexed wallet);
    event ProfileDeactivated(string indexed username, address indexed wallet);

    error UsernameAlreadyTaken();
    error UserAlreadyRegistered();
    error UserNotFound();
    error InvalidUsername();
    error FacialHashAlreadyUsed();

    modifier validUsername(string calldata username) {
        if (bytes(username).length == 0 || bytes(username).length > 32) {
            revert InvalidUsername();
        }
        _;
    }

    modifier onlyWalletOwner(address wallet) {
        require(msg.sender == wallet, "Unauthorized");
        _;
    }

    function registerUsername(
        string calldata username,
        bytes32 facialHash
    ) external validUsername(username) {
        if (usernameToWallet[username] != address(0)) {
            revert UsernameAlreadyTaken();
        }
        
        if (bytes(walletToUsername[msg.sender]).length != 0) {
            revert UserAlreadyRegistered();
        }

        if (facialHashToWallet[facialHash] != address(0)) {
            revert FacialHashAlreadyUsed();
        }

        usernameToWallet[username] = msg.sender;
        walletToUsername[msg.sender] = username;
        facialHashToWallet[facialHash] = msg.sender;
        
        userProfiles[msg.sender] = UserProfile({
            username: username,
            wallet: msg.sender,
            facialHash: facialHash,
            registrationTimestamp: block.timestamp,
            isActive: true
        });

        allUsernames.push(username);

        emit UsernameRegistered(username, msg.sender, facialHash);
    }

    function updateUsername(
        string calldata newUsername
    ) external validUsername(newUsername) {
        if (bytes(walletToUsername[msg.sender]).length == 0) {
            revert UserNotFound();
        }

        if (usernameToWallet[newUsername] != address(0)) {
            revert UsernameAlreadyTaken();
        }

        string memory oldUsername = walletToUsername[msg.sender];
        
        delete usernameToWallet[oldUsername];
        usernameToWallet[newUsername] = msg.sender;
        walletToUsername[msg.sender] = newUsername;
        
        userProfiles[msg.sender].username = newUsername;

        emit UsernameUpdated(oldUsername, newUsername, msg.sender);
    }

    function deactivateProfile() external {
        if (bytes(walletToUsername[msg.sender]).length == 0) {
            revert UserNotFound();
        }

        string memory username = walletToUsername[msg.sender];
        bytes32 facialHash = userProfiles[msg.sender].facialHash;
        
        delete usernameToWallet[username];
        delete walletToUsername[msg.sender];
        delete facialHashToWallet[facialHash];
        
        userProfiles[msg.sender].isActive = false;

        emit ProfileDeactivated(username, msg.sender);
    }

    function resolveUsername(string calldata username) external view returns (address) {
        return usernameToWallet[username];
    }

    function resolveWallet(address wallet) external view returns (string memory) {
        return walletToUsername[wallet];
    }

    function getUserProfile(address wallet) external view returns (UserProfile memory) {
        return userProfiles[wallet];
    }

    function isUsernameAvailable(string calldata username) external view returns (bool) {
        return usernameToWallet[username] == address(0);
    }

    function isFacialHashUsed(bytes32 facialHash) external view returns (bool) {
        return facialHashToWallet[facialHash] != address(0);
    }

    function getTotalUsers() external view returns (uint256) {
        return allUsernames.length;
    }

    function getUsernameByIndex(uint256 index) external view returns (string memory) {
        require(index < allUsernames.length, "Index out of bounds");
        return allUsernames[index];
    }
}