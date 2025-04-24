// contracts/storage/AttributeStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AttributeStorage
 * @dev Abstract contract defining storage layout for attributes
 */
abstract contract AttributeStorage {
    /**
     * @dev Mapping of user address to attribute type to attribute value
     * address => attributeType => bool
     */
    mapping(address => mapping(bytes32 => bool)) internal _attributes;
    
    /**
     * @dev Mapping of user address to attribute type to expiry timestamp
     * address => attributeType => uint256 (timestamp)
     * 0 means no expiry or attribute not set
     */
    mapping(address => mapping(bytes32 => uint256)) internal _attributeExpiry;
    
    /**
     * @dev Reserved storage slots for future upgrades
     */
    uint256[50] private __gap;
}