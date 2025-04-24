// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/AttributeStorage.sol";
import "../libraries/AttributeEvents.sol";

/**
 * @title AttributeExpiry
 * @dev Mixin for handling attribute expiration functionality
 */
abstract contract AttributeExpiry is AttributeStorage {
    // Standard 12-month (365 days) expiry period
    uint256 public constant STANDARD_EXPIRY_PERIOD = 365 days;
    
    /**
     * @dev Checks if an attribute is valid and not expired
     * @param user The user address
     * @param attributeType The attribute type to check
     * @return bool True if the attribute is set and not expired
     */
    function _isAttributeValid(address user, bytes32 attributeType) internal view returns (bool) {
        bool hasAttr = _attributes[user][attributeType];
        if (!hasAttr) return false;
        
        uint256 expiryTimestamp = _attributeExpiry[user][attributeType];
        // If expiry is 0, it never expires
        if (expiryTimestamp == 0) return true;
        
        return block.timestamp <= expiryTimestamp;
    }
    
    /**
     * @dev Sets an attribute with standard 12-month expiry period
     * @param user The user address
     * @param attributeType The attribute type
     * @param value The attribute value
     * @param verifier The address performing the verification
     */
    function _setAttributeWithStandardExpiry(
        address user,
        bytes32 attributeType,
        bool value,
        address verifier
    ) internal {
        uint256 expiryTimestamp = block.timestamp + STANDARD_EXPIRY_PERIOD;
        _setAttributeWithExpiry(user, attributeType, value, expiryTimestamp, verifier);
    }
    
    /**
     * @dev Sets an attribute with a custom expiry timestamp
     * @param user The user address
     * @param attributeType The attribute type
     * @param value The attribute value
     * @param expiryTimestamp The timestamp when the attribute will expire
     * @param verifier The address performing the verification
     */
    function _setAttributeWithExpiry(
        address user,
        bytes32 attributeType,
        bool value,
        uint256 expiryTimestamp,
        address verifier
    ) internal {
        _attributes[user][attributeType] = value;
        _attributeExpiry[user][attributeType] = expiryTimestamp;
        
        emit AttributeEvents.AttributeSet(user, attributeType, value, verifier, expiryTimestamp);
    }
    
    /**
     * @dev Gets the expiry timestamp for an attribute
     * @param user The user address
     * @param attributeType The attribute type
     * @return uint256 The expiry timestamp (0 if not set or permanent)
     */
    function _getAttributeExpiry(
        address user,
        bytes32 attributeType
    ) internal view returns (uint256) {
        return _attributeExpiry[user][attributeType];
    }
}