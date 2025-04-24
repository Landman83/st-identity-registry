// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VerifierStorage
 * @dev Abstract contract defining storage layout for verifier data
 */
abstract contract VerifierStorage {
    /**
     * @dev The address of the authorized verifier
     */
    address internal _verifier;
    
    /**
     * @dev Reserved storage slots for future upgrades
     */
    uint256[50] private __gap;
}