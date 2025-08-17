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

    mapping(bytes32 => address) public deployedWallets;
    mapping(address => bool) public isValidWallet;

    event WalletDeployed(
        address indexed wallet,
        address indexed owner,
        bytes32 salt,
        string username,
        bytes32 facialHash
    );

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
        uint256[] calldata facialEmbedding,
        uint256 index
    ) external returns (address wallet) {
        bytes32 facialHash = keccak256(abi.encode(facialEmbedding));
        bytes32 salt = frvmValidator.generateWalletSalt(facialHash, index);


        require(deployedWallets[salt] == address(0), "Wallet already exists");

        bytes memory initData = abi.encode(username, facialHash, facialEmbedding, index);
        
        wallet = kernelFactory.createAccount(
            kernelImplementation,
            initData,
            uint256(salt)
        );

        IKernelAccount(wallet).initialize(
            address(frvmValidator),
            initData
        );

        deployedWallets[salt] = wallet;
        isValidWallet[wallet] = true;

        emit WalletDeployed(wallet, msg.sender, salt, username, facialHash);
    }

    function predictWalletAddress(
        bytes32 facialHash,
        uint256 index
    ) external view returns (address) {
        bytes32 salt = frvmValidator.generateWalletSalt(facialHash, index);
        return _predictAddress(salt);
    }

    function _predictAddress(bytes32 salt) internal view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(kernelFactory),
                salt,
                keccak256(abi.encodePacked(kernelImplementation))
            )
        );
        return address(uint160(uint256(hash)));
    }

    function getWalletBySalt(bytes32 salt) external view returns (address) {
        return deployedWallets[salt];
    }

    function isWalletValid(address wallet) external view returns (bool) {
        return isValidWallet[wallet];
    }
}