// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";
import "../factories/FRVMWalletFactory.sol";

contract MerchantAccount {
    struct MerchantProfile {
        string name;
        address owner;
        bool isActive;
        uint256 registrationTimestamp;
    }

    struct PaymentRequest {
        bytes32 requestId;
        address merchant;
        string customerUsername;
        uint256 amount;
        address token;
        bool isPaid;
        bool isCancelled;
        uint256 timestamp;
        uint256 expiryTimestamp;
    }

    mapping(address => MerchantProfile) public merchants;
    mapping(bytes32 => PaymentRequest) public paymentRequests;
    mapping(address => bytes32[]) public merchantRequests;
    mapping(address => uint256) public merchantBalances;

    IFaceRecognitionValidator public immutable frvmValidator;
    FRVMWalletFactory public immutable walletFactory;

    event MerchantRegistered(address indexed merchant, string name);
    event PaymentRequestCreated(
    bytes32 indexed requestId, address indexed merchant, string customerUsername, uint256 amount);
    event PaymentCompleted(bytes32 indexed requestId, address indexed customer, uint256 amount);
    event PaymentCancelled(bytes32 indexed requestId, address indexed merchant);
    event FundsWithdrawn(address indexed merchant, uint256 amount);

    error MerchantNotRegistered();
    error PaymentRequestNotFound();
    error PaymentAlreadyCompleted();
    error PaymentExpired();
    error InvalidFacialSignature();
    error InsufficientBalance();
    error Unauthorized();

    modifier onlyMerchant() {
        if (!merchants[msg.sender].isActive) revert MerchantNotRegistered();
        _;
    }

    modifier onlyMerchantOwner(address merchant) {
        if (merchants[merchant].owner != msg.sender) revert Unauthorized();
        _;
    }

    constructor(address _frvmValidator, address _walletFactory) {
        frvmValidator = IFaceRecognitionValidator(_frvmValidator);
        walletFactory = FRVMWalletFactory(_walletFactory);
    }

    function registerMerchant(string calldata name) external {
        require(!merchants[msg.sender].isActive, "Already registered");
        
        merchants[msg.sender] = MerchantProfile({
            name: name,
            owner: msg.sender,
            isActive: true,
            registrationTimestamp: block.timestamp
        });

        emit MerchantRegistered(msg.sender, name);
    }

    function createPaymentRequest(
        string calldata customerUsername,
        uint256 amount,
        address token,
        uint256 expiryDuration
    ) external onlyMerchant returns (bytes32 requestId) {
        address customer = walletFactory.resolve(customerUsername);
        require(customer != address(0), "Customer not found");

        requestId = keccak256(abi.encodePacked(
            msg.sender,
            customerUsername,
            amount,
            token,
            block.timestamp
        ));

        paymentRequests[requestId] = PaymentRequest({
            requestId: requestId,
            merchant: msg.sender,
            customerUsername: customerUsername,
            amount: amount,
            token: token,
            isPaid: false,
            isCancelled: false,
            timestamp: block.timestamp,
            expiryTimestamp: block.timestamp + expiryDuration
        });

        merchantRequests[msg.sender].push(requestId);

        emit PaymentRequestCreated(requestId, msg.sender, customerUsername, amount);
    }

    function processPayment(
        bytes32 requestId,
        IFaceRecognitionValidator.FacialSignature calldata facialSig
    ) external payable {
        PaymentRequest storage request = paymentRequests[requestId];
        
        if (request.merchant == address(0)) revert PaymentRequestNotFound();
        if (request.isPaid) revert PaymentAlreadyCompleted();
        if (block.timestamp > request.expiryTimestamp) revert PaymentExpired();

        address customer = walletFactory.resolve(request.customerUsername);
        require(customer == msg.sender, "Unauthorized customer");

        bytes32 paymentHash = keccak256(abi.encodePacked(
            requestId,
            request.amount,
            request.token
        ));

        bool isValidSignature = frvmValidator.validateFacialSignature(
            customer,
            paymentHash,
            facialSig
        );

        if (!isValidSignature) revert InvalidFacialSignature();

        if (request.token == address(0)) {
            require(msg.value >= request.amount, "Insufficient payment");
            merchantBalances[request.merchant] += request.amount;
            
            if (msg.value > request.amount) {
                payable(msg.sender).transfer(msg.value - request.amount);
            }
        } else {
            IERC20(request.token).transferFrom(msg.sender, address(this), request.amount);
            merchantBalances[request.merchant] += request.amount;
        }

        request.isPaid = true;

        emit PaymentCompleted(requestId, customer, request.amount);
    }

    function cancelPaymentRequest(bytes32 requestId) external {
        PaymentRequest storage request = paymentRequests[requestId];
        
        if (request.merchant == address(0)) revert PaymentRequestNotFound();
        if (request.isPaid) revert PaymentAlreadyCompleted();
        
        require(
            msg.sender == request.merchant || block.timestamp > request.expiryTimestamp,
            "Cannot cancel"
        );

        request.isCancelled = true;

        emit PaymentCancelled(requestId, request.merchant);
    }

    function withdrawFunds(uint256 amount) external onlyMerchant {
        if (merchantBalances[msg.sender] < amount) revert InsufficientBalance();
        
        merchantBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(msg.sender, amount);
    }

    function getPaymentRequest(bytes32 requestId) external view returns (PaymentRequest memory) {
        return paymentRequests[requestId];
    }

    function getMerchantRequests(address merchant) external view returns (bytes32[] memory) {
        return merchantRequests[merchant];
    }

    function getMerchantProfile(address merchant) external view returns (MerchantProfile memory) {
        return merchants[merchant];
    }
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}