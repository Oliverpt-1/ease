// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "lib/erc7579-implementation/src/interfaces/IERC7579Module.sol";
import "lib/erc7579-implementation/src/interfaces/IERC7579Account.sol";
import "lib/erc7579-implementation/node_modules/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

// Re-export the interfaces for our contracts
contract ERC7579Imports {
    // This contract is just to ensure imports work
}