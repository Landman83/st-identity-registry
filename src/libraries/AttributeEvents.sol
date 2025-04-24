// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AttributeEvents
 * @dev Library for standardized events related to attribute operations
 */
library AttributeEvents {
    /**
     * @dev Emitted when an attribute is set for an address
     */
    event AttributeSet(address indexed user, bytes32 indexed attributeType, bool value, address indexed verifier, uint256 expiryTimestamp);
    
    /**
     * @dev Emitted when an attribute expires
     */
    event AttributeExpired(address indexed user, bytes32 indexed attributeType);
    
    /**
     * @dev Emitted when a verifier is set or changed
     */
    event VerifierChanged(address indexed oldVerifier, address indexed newVerifier);
    
    /**
     * @dev Emitted when a third-party verifier is added or removed
     */
    event ThirdPartyVerifierStatusChanged(address indexed verifier, bool authorized);
    
    /**
     * @dev Emitted when a third-party verifier's permission for an attribute type is updated
     */
    event ThirdPartyVerifierPermissionChanged(address indexed verifier, bytes32 indexed attributeType, bool canVerify);
}