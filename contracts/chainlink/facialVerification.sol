// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {FunctionsClient} from "@chainlink/contracts@1.4.0/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.4.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@1.4.0/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/resources/link-token-contracts/
 */

/**
 * @title GettingStartedFunctionsConsumer
 * @notice This is an example contract to show how to make HTTP requests using Chainlink
 * @dev This contract uses hardcoded values and should not be used in production.
 */
contract GettingStartedFunctionsConsumer is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(
        bytes32 indexed requestId,
        string verificationResult,
        bytes response,
        bytes err
    );

    // Router address - Hardcoded for Sepolia
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    // JavaScript source code
    // Perform facial verification using CompreFace API
    // Expects args[0] = compreface_base_url, args[1] = source_embedding_json, args[2] = target_embeddings_json
    string source =
        "const sourceEmbedding = JSON.parse(args[0]);"
        "const targetEmbeddings = JSON.parse(args[1]);"
        "const apiResponse = await Functions.makeHttpRequest({"
        "url: `https://compreface-railway-production.up.railway.app/api/v1/verification/embeddings/verify`,"
        "method: 'POST',"
        "headers: {"
        "'Content-Type': 'application/json',"
        "'x-api-key': '52ac9db0-614e-4cc0-ad36-f0fffab8eba2'"
        "},"
        "data: {"
        "source: sourceEmbedding,"
        "targets: targetEmbeddings"
        "}"
        "});"
        "if (apiResponse.error) {"
        "throw Error('CompreFace API request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(JSON.stringify(data));";

    //Callback gas limit
    uint32 gasLimit = 300000;

    // donID - Hardcoded for Sepolia
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    bytes32 donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    // State variable to store the returned verification results
    string public verificationResult;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    /**
     * @notice Sends an HTTP request for facial verification
     * @param subscriptionId The ID for the Chainlink subscription
     * @param args The arguments to pass to the HTTP request (baseUrl, sourceEmbedding, targetEmbeddings)
     * @return requestId The ID of the request
     */
    function sendRequest(
        uint64 subscriptionId,
        string[] calldata args
    ) external onlyOwner returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        verificationResult = string(response);
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, verificationResult, s_lastResponse, s_lastError);
    }
}
