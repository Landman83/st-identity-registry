// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AttributeEvents.sol";

/**
 * @title Interface for Verifier Management
 * @dev Defines functions for managing the verifier address
 */
interface IVerifierManagement {
    
    /**
     * @dev Gets the current verifier address
     * @return The address of the current verifier
     */
    function getVerifier() external view returns (address);
    
    /**
     * @dev Sets a new verifier address
     * @param newVerifier The address of the new verifier
     */
    function setVerifier(address newVerifier) external;
}