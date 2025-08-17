// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IfaceRecognitionValidator.sol";
import "../factories/FRVMWalletFactory.sol";
import "./MerchantAccount.sol";

contract CheckoutProcessor {
    struct CheckoutSession {
        bytes32 sessionId;
        address merchant;
        string customerUsername;
        uint256 amount;
        address token;
        bool isCompleted;
        bool isCancelled;
        uint256 timestamp;
        uint256 expiryTimestamp;
        bytes metadata;
    }

    mapping(bytes32 => CheckoutSession) public checkoutSessions;
    mapping(address => bytes32[]) public merchantSessions;
    mapping(address => bytes32[]) public customerSessions;

    IFaceRecognitionValidator public immutable frvmValidator;
    FRVMWalletFactory public immutable walletFactory;
    MerchantAccount public immutable merchantAccount;

    event CheckoutSessionCreated(
        bytes32 indexed sessionId,
        address indexed merchant,
        string customerUsername,
        uint256 amount
    );
    event CheckoutCompleted(bytes32 indexed sessionId, address indexed customer);
    event CheckoutCancelled(bytes32 indexed sessionId);

    error SessionNotFound();
    error SessionExpired();
    error SessionAlreadyCompleted();
    error InvalidCustomer();
    error InvalidMerchant();

    constructor(
        address _frvmValidator,
        address _walletFactory,
        address _merchantAccount
    ) {
        frvmValidator = IFaceRecognitionValidator(_frvmValidator);
        walletFactory = FRVMWalletFactory(_walletFactory);
        merchantAccount = MerchantAccount(_merchantAccount);
    }

    function initializeCheckout(
        string calldata customerUsername,
        uint256 amount,
        address token,
        uint256 expiryDuration,
        bytes calldata metadata
    ) external returns (bytes32 sessionId) {
        address customer = walletFactory.resolveUsername(customerUsername);
        require(customer != address(0), "Customer not found");

        sessionId = keccak256(abi.encodePacked(
            msg.sender,
            customerUsername,
            amount,
            token,
            block.timestamp,
            metadata
        ));

        checkoutSessions[sessionId] = CheckoutSession({
            sessionId: sessionId,
            merchant: msg.sender,
            customerUsername: customerUsername,
            amount: amount,
            token: token,
            isCompleted: false,
            isCancelled: false,
            timestamp: block.timestamp,
            expiryTimestamp: block.timestamp + expiryDuration,
            metadata: metadata
        });

        merchantSessions[msg.sender].push(sessionId);
        customerSessions[customer].push(sessionId);

        emit CheckoutSessionCreated(sessionId, msg.sender, customerUsername, amount);
    }

    function completeCheckout(
        bytes32 sessionId,
        IFaceRecognitionValidator.FacialSignature calldata facialSig
    ) external payable {
        CheckoutSession storage session = checkoutSessions[sessionId];
        
        if (session.merchant == address(0)) revert SessionNotFound();
        if (session.isCompleted) revert SessionAlreadyCompleted();
        if (block.timestamp > session.expiryTimestamp) revert SessionExpired();

        address customer = walletFactory.resolveUsername(session.customerUsername);
        if (customer != msg.sender) revert InvalidCustomer();

        bytes32 checkoutHash = keccak256(abi.encodePacked(
            sessionId,
            session.amount,
            session.token,
            session.metadata
        ));

        bool isValidSignature = frvmValidator.validateFacialSignature(
            customer,
            checkoutHash,
            facialSig
        );

        require(isValidSignature, "Invalid facial signature");

        bytes32 paymentRequestId = merchantAccount.createPaymentRequest(
            session.customerUsername,
            session.amount,
            session.token,
            3600 // 1 hour expiry for payment
        );

        merchantAccount.processPayment{value: msg.value}(paymentRequestId, facialSig);

        session.isCompleted = true;

        emit CheckoutCompleted(sessionId, customer);
    }

    function cancelCheckout(bytes32 sessionId) external {
        CheckoutSession storage session = checkoutSessions[sessionId];
        
        if (session.merchant == address(0)) revert SessionNotFound();
        if (session.isCompleted) revert SessionAlreadyCompleted();

        address customer = walletFactory.resolveUsername(session.customerUsername);
        
        require(
            msg.sender == session.merchant || 
            msg.sender == customer || 
            block.timestamp > session.expiryTimestamp,
            "Unauthorized to cancel"
        );

        session.isCancelled = true;

        emit CheckoutCancelled(sessionId);
    }

    function getCheckoutSession(bytes32 sessionId) external view returns (CheckoutSession memory) {
        return checkoutSessions[sessionId];
    }

    function getMerchantSessions(address merchant) external view returns (bytes32[] memory) {
        return merchantSessions[merchant];
    }

    function getCustomerSessions(address customer) external view returns (bytes32[] memory) {
        return customerSessions[customer];
    }

    function isSessionValid(bytes32 sessionId) external view returns (bool) {
        CheckoutSession storage session = checkoutSessions[sessionId];
        return session.merchant != address(0) && 
               !session.isCompleted && 
               !session.isCancelled && 
               block.timestamp <= session.expiryTimestamp;
    }
}