// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../libraries/FacialHashLib.sol";
import "../interfaces/IERC7579Module.sol";

contract FacialRecognitionValidator is IFaceRecognitionValidator, ILayerZeroReceiver {
    
    mapping(address => UserData) public userData;
    mapping(string => address) public usernameToWallet;
    mapping(address => bool) public isInitialized;
    
    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    
    modifier onlyInitialized(address smartAccount) {
        if (!isInitialized[smartAccount]) revert NotInitialized(smartAccount);
        _;
    }
    
    modifier onlyUser(address user) {
        require(msg.sender == user, "Unauthorized");
        _;
    }

    constructor(address _lzEndpoint) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function onInstall(bytes calldata data) external override {
        if (isInitialized[msg.sender]) revert AlreadyInitialized(msg.sender);
        
        (string memory username, bytes32 facialHash, uint256 index) = abi.decode(
            data, 
            (string, bytes32, uint256)
        );
        
        _registerUser(msg.sender, username, facialHash, index);
        isInitialized[msg.sender] = true;
    }

    function onUninstall(bytes calldata) external override {
        if (!isInitialized[msg.sender]) revert NotInitialized(msg.sender);
        
        string memory username = userData[msg.sender].username;
        delete userData[msg.sender];
        delete usernameToWallet[username];
        delete isInitialized[msg.sender];
    }

    function isModuleType(uint256 typeID) external pure override returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    function registerUser(
        string calldata username,
        bytes32 facialHash,
        uint256 index
    ) external override {
        _registerUser(msg.sender, username, facialHash, index);
    }

    function _registerUser(
        address wallet,
        string memory username,
        bytes32 facialHash,
        uint256 index
    ) internal {
        if (facialHash == bytes32(0)) revert InvalidFacialHash();
        if (usernameToWallet[username] != address(0)) revert UsernameAlreadyTaken();
        
        userData[wallet] = UserData({
            facialHash: facialHash,
            username: username,
            index: index,
            isRegistered: true,
            registrationTimestamp: block.timestamp
        });
        
        usernameToWallet[username] = wallet;
        
        emit UserRegistered(wallet, username, facialHash);
    }

    function updateFacialHash(bytes32 newFacialHash) external override {
        if (!userData[msg.sender].isRegistered) revert UserNotRegistered();
        if (newFacialHash == bytes32(0)) revert InvalidFacialHash();
        
        bytes32 oldHash = userData[msg.sender].facialHash;
        userData[msg.sender].facialHash = newFacialHash;
        
        emit FacialHashUpdated(msg.sender, oldHash, newFacialHash);
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external view override returns (uint256 validationData) {
        FacialSignature memory facialSig = abi.decode(userOp.signature, (FacialSignature));
        
        bool isValid = _validateFacialSignature(userOp.sender, userOpHash, facialSig);
        
        return isValid ? 0 : 1;
    }

    function validateSignature(
        address sender,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4) {
        FacialSignature memory facialSig = abi.decode(signature, (FacialSignature));
        
        bool isValid = _validateFacialSignature(sender, hash, facialSig);
        
        return isValid ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata signature
    ) external view override returns (bytes4) {
        FacialSignature memory facialSig = abi.decode(signature, (FacialSignature));
        
        bool isValid = _validateFacialSignature(sender, hash, facialSig);
        
        return isValid ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }

    function validateFacialSignature(
        address user,
        bytes32 messageHash,
        FacialSignature calldata facialSig
    ) external view override returns (bool) {
        return _validateFacialSignature(user, messageHash, facialSig);
    }

    function _validateFacialSignature(
        address user,
        bytes32 messageHash,
        FacialSignature memory facialSig
    ) internal view returns (bool) {
        if (!userData[user].isRegistered) return false;
        if (facialSig.facialHash != userData[user].facialHash) return false;
        
        return _verifyFacialSignatureInternal(
            messageHash,
            facialSig.facialHash,
            facialSig.signature
        );
    }

    function getUserData(address user) external view override returns (UserData memory) {
        return userData[user];
    }

    function getUserByUsername(string calldata username) external view override returns (address) {
        return usernameToWallet[username];
    }

    function generateWalletSalt(bytes32 facialHash, uint256 index) external pure override returns (bytes32) {
        return keccak256(abi.encodePacked(facialHash, index));
    }

    function syncToChain(uint16 chainId, address user) external payable override {
        if (!userData[user].isRegistered) revert UserNotRegistered();
        
        bytes memory payload = abi.encode(
            userData[user].username,
            userData[user].facialHash,
            userData[user].index
        );
        
        lzEndpoint.send{value: msg.value}(
            chainId,
            trustedRemoteLookup[chainId],
            payload,
            payable(msg.sender),
            address(0),
            bytes("")
        );
        
        emit CrossChainSync(user, chainId, userData[user].facialHash);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64,
        bytes calldata _payload
    ) external override {
        require(msg.sender == address(lzEndpoint), "Invalid endpoint");
        require(
            keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]),
            "Invalid source"
        );
        
        (string memory username, bytes32 facialHash, uint256 index) = abi.decode(
            _payload,
            (string, bytes32, uint256)
        );
        
        address wallet = _computeWalletAddress(facialHash, index);
        _registerUser(wallet, username, facialHash, index);
    }

    function _computeWalletAddress(bytes32 facialHash, uint256 index) internal pure returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(facialHash, index));
        return address(uint160(uint256(salt)));
    }

    function _verifyFacialSignatureInternal(
        bytes32 messageHash,
        bytes32 expectedFacialHash,
        bytes memory signature
    ) internal view returns (bool) {
        if (signature.length < 96) {
            return false;
        }

        bytes32 recoveredHash;
        uint256 timestampValue;
        
        assembly {
            recoveredHash := mload(add(signature, 32))
            timestampValue := mload(add(signature, 64))
        }

        if (recoveredHash != expectedFacialHash) {
            return false;
        }

        if (timestampValue > block.timestamp + 300 || timestampValue + 300 < block.timestamp) { // 5 minute validity window
            return false;
        }

        bytes memory facialProof = new bytes(signature.length - 64);
        for (uint256 i = 64; i < signature.length; i++) {
            facialProof[i - 64] = signature[i];
        }

        bytes32 proofHash = keccak256(abi.encodePacked(
            messageHash,
            recoveredHash,
            timestampValue
        ));

        return keccak256(facialProof) == proofHash;
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _path) external {
        trustedRemoteLookup[_chainId] = _path;
    }
}