// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/validators/faceRecognitionValidator.sol";
import "../contracts/merchants/MerchantAccount.sol";
import "../contracts/ens/UsernameRegistry.sol";

contract FRVMIntegrationTest is Test {
    FacialRecognitionValidator public validator;
    MerchantAccount public merchantAccount;
    UsernameRegistry public usernameRegistry;

    address public mockLzEndpoint = address(0x123);
    address public alice = address(0xA11CE);
    address public merchant = address(0xB0B);

    bytes32 public aliceFacialHash = keccak256("alice_face_data");
    string public aliceUsername = "alice";

    function setUp() public {
        // Deploy contracts
        validator = new FacialRecognitionValidator(mockLzEndpoint);
        usernameRegistry = new UsernameRegistry();
        merchantAccount = new MerchantAccount(address(validator), address(usernameRegistry));

        // Setup test users
        vm.deal(alice, 10 ether);
        vm.deal(merchant, 1 ether);
    }

    function testCompleteCheckoutFlow() public {
        // 1. User registers with facial recognition
        vm.startPrank(alice);
        validator.registerUser(aliceUsername, aliceFacialHash, 0);
        
        // 2. Register username
        usernameRegistry.registerUsername(aliceUsername, aliceFacialHash);
        vm.stopPrank();

        // 3. Merchant registers
        vm.startPrank(merchant);
        merchantAccount.registerMerchant("Test Store");

        // 4. Create payment request
        bytes32 requestId = merchantAccount.createPaymentRequest(
            aliceUsername,
            1 ether,
            address(0), // ETH payment
            3600 // 1 hour expiry
        );
        vm.stopPrank();

        // 5. Customer processes payment with facial signature
        vm.startPrank(alice);
        
        // Create facial signature (simplified for test)
        bytes32 paymentHash = keccak256(abi.encodePacked(requestId, uint256(1 ether), address(0)));
        bytes memory facialProof = abi.encodePacked(paymentHash, aliceFacialHash, block.timestamp);
        
        IFaceRecognitionValidator.FacialSignature memory facialSig = IFaceRecognitionValidator.FacialSignature({
            facialHash: aliceFacialHash,
            timestamp: block.timestamp,
            signature: abi.encodePacked(aliceFacialHash, block.timestamp, facialProof)
        });

        // Process payment
        merchantAccount.processPayment{value: 1 ether}(requestId, facialSig);
        vm.stopPrank();

        // 6. Verify payment completed
        MerchantAccount.PaymentRequest memory request = merchantAccount.getPaymentRequest(requestId);
        assertTrue(request.isPaid);
        assertEq(merchantAccount.merchantBalances(merchant), 1 ether);
    }

    function testWalletSaltGeneration() public {
        bytes32 salt1 = validator.generateWalletSalt(aliceFacialHash, 0);
        bytes32 salt2 = validator.generateWalletSalt(aliceFacialHash, 1);
        
        // Different indices should generate different salts
        assertTrue(salt1 != salt2);
        
        // Same inputs should generate same salt
        bytes32 salt3 = validator.generateWalletSalt(aliceFacialHash, 0);
        assertEq(salt1, salt3);
    }

    function testFacialSignatureValidation() public {
        // Register user
        vm.prank(alice);
        validator.registerUser(aliceUsername, aliceFacialHash, 0);

        bytes32 messageHash = keccak256("test_message");
        uint256 timestamp = block.timestamp;
        
        // Create valid signature
        bytes memory facialProof = abi.encodePacked(messageHash, aliceFacialHash, timestamp);
        bytes memory signature = abi.encodePacked(aliceFacialHash, timestamp, facialProof);
        
        IFaceRecognitionValidator.FacialSignature memory facialSig = IFaceRecognitionValidator.FacialSignature({
            facialHash: aliceFacialHash,
            timestamp: timestamp,
            signature: signature
        });

        // Test validation
        bool isValid = validator.validateFacialSignature(alice, messageHash, facialSig);
        assertTrue(isValid);

        // Test with wrong facial hash
        bytes32 wrongHash = keccak256("wrong_face");
        facialSig.facialHash = wrongHash;
        
        isValid = validator.validateFacialSignature(alice, messageHash, facialSig);
        assertFalse(isValid);
    }

    function testUsernameResolution() public {
        // Register username
        vm.prank(alice);
        usernameRegistry.registerUsername(aliceUsername, aliceFacialHash);

        // Test resolution
        address resolved = usernameRegistry.resolveUsername(aliceUsername);
        assertEq(resolved, alice);

        // Test reverse lookup
        string memory username = usernameRegistry.resolveWallet(alice);
        assertEq(username, aliceUsername);
    }

    function testMerchantFundsManagement() public {
        // Register merchant
        vm.prank(merchant);
        merchantAccount.registerMerchant("Test Store");

        // Simulate payment by directly funding merchant account
        vm.deal(address(merchantAccount), 10 ether);
        
        // Use assembly to set the merchant balance mapping
        // merchantBalances is at storage slot 3 (counting from 0: merchants=0, paymentRequests=1, merchantRequests=2, merchantBalances=3)
        bytes32 balanceSlot = keccak256(abi.encode(merchant, uint256(3)));
        vm.store(address(merchantAccount), balanceSlot, bytes32(uint256(5 ether)));

        // Test withdrawal
        vm.prank(merchant);
        uint256 balanceBefore = merchant.balance;
        merchantAccount.withdrawFunds(2 ether);
        
        assertEq(merchant.balance, balanceBefore + 2 ether);
        assertEq(merchantAccount.merchantBalances(merchant), 3 ether);
    }
}