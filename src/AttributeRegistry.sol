// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAttributeRegistry.sol";
import "./interfaces/IVerifierManagement.sol";
import "./mixins/AttributeExpiry.sol";
import "./mixins/VerifierManagement.sol";
import "./storage/AttributeStorage.sol";
import "./libraries/AttributeEvents.sol";

/**
 * @title AttributeRegistry
 * @dev The main attribute registry contract that stores and manages user attributes
 */
contract AttributeRegistry is 
    IAttributeRegistry, 
    Ownable, 
    AttributeExpiry, 
    VerifierManagement 
{
    // Use events from the library
    using AttributeEvents for *;
    /**
     * @dev Constructor
     * @param initialVerifier The initial verifier contract address
     */
    constructor(address initialVerifier) 
        Ownable(msg.sender) 
        VerifierManagement(initialVerifier) 
    {}
    
    /**
     * @dev Modifier to ensure only the authorized verifier can call certain functions
     */
    modifier onlyVerifier() {
        require(msg.sender == _verifier, "AttributeRegistry: caller is not the authorized verifier");
        _;
    }
    
    /**
     * @dev Returns whether an address has a specific attribute
     * @param user The address to check
     * @param attributeType The attribute type to check for
     * @return bool True if the address has the attribute and it has not expired
     */
    function hasAttribute(address user, bytes32 attributeType) 
        external 
        view 
        override 
        returns (bool) 
    {
        return _isAttributeValid(user, attributeType);
    }
    
    /**
     * @dev Gets the expiry timestamp for an address's attribute
     * @param user The address to check
     * @param attributeType The attribute type to check
     * @return uint256 The unix timestamp when the attribute expires (0 if not set or permanent)
     */
    function getAttributeExpiry(address user, bytes32 attributeType) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return _getAttributeExpiry(user, attributeType);
    }
    
    /**
     * @dev Sets an attribute for an address with the standard 12-month expiry period
     * @param user The address to set the attribute for
     * @param attributeType The attribute type to set
     * @param value The boolean value to set
     */
    function setAttribute(address user, bytes32 attributeType, bool value) 
        external 
        override 
        onlyVerifier 
    {
        _setAttributeWithStandardExpiry(user, attributeType, value, msg.sender);
    }
    
    /**
     * @dev Sets an attribute for an address with a custom expiry timestamp
     * @param user The address to set the attribute for
     * @param attributeType The attribute type to set
     * @param value The boolean value to set
     * @param expiryTimestamp The unix timestamp when the attribute will expire
     */
    function setAttributeWithExpiry(
        address user, 
        bytes32 attributeType, 
        bool value, 
        uint256 expiryTimestamp
    ) 
        external 
        override 
        onlyVerifier 
    {
        // Ensure expiry is in the future if set
        if (expiryTimestamp != 0) {
            require(expiryTimestamp > block.timestamp, "AttributeRegistry: expiry must be in the future");
        }
        
        _setAttributeWithExpiry(user, attributeType, value, expiryTimestamp, msg.sender);
    }
    
    /**
     * @dev Revokes an attribute for an address
     * @param user The address to revoke the attribute for
     * @param attributeType The attribute type to revoke
     */
    function revokeAttribute(address user, bytes32 attributeType)
        external
        override
        onlyVerifier
    {
        // Setting value to false effectively revokes the attribute
        _setAttributeWithExpiry(user, attributeType, false, 0, msg.sender);
        
        // Emit specific event for revocation
        emit AttributeEvents.AttributeExpired(user, attributeType);
    }
}