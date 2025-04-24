// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/AttributeEvents.sol";

/**
 * @title Interface for Attribute Registry
 * @dev Defines functions for storing and querying attributes of addresses
 */
interface IAttributeRegistry {
    
    /**
     * @dev Returns whether an address has a specific attribute
     * @param user The address to check
     * @param attributeType The attribute type to check for
     * @return bool True if the address has the attribute and it has not expired
     */
    function hasAttribute(address user, bytes32 attributeType) external view returns (bool);
    
    /**
     * @dev Gets the expiry timestamp for an address's attribute
     * @param user The address to check
     * @param attributeType The attribute type to check
     * @return uint256 The unix timestamp when the attribute expires (0 if not set or already expired)
     */
    function getAttributeExpiry(address user, bytes32 attributeType) external view returns (uint256);
    
    /**
     * @dev Sets an attribute for an address with the standard expiry period
     * @param user The address to set the attribute for
     * @param attributeType The attribute type to set
     * @param value The boolean value to set
     */
    function setAttribute(address user, bytes32 attributeType, bool value) external;
    
    /**
     * @dev Sets an attribute for an address with a custom expiry timestamp
     * @param user The address to set the attribute for
     * @param attributeType The attribute type to set
     * @param value The boolean value to set
     * @param expiryTimestamp The unix timestamp when the attribute will expire
     */
    function setAttributeWithExpiry(address user, bytes32 attributeType, bool value, uint256 expiryTimestamp) external;
    
    /**
     * @dev Revokes an attribute for an address
     * @param user The address to revoke the attribute for
     * @param attributeType The attribute type to revoke
     */
    function revokeAttribute(address user, bytes32 attributeType) external;
}