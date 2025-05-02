// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../storage/VerifierStorage.sol";
import "../libraries/AttributeEvents.sol";
import "../interfaces/IAttributeRegistry.sol";

/**
 * @title Verifier
 * @dev Implements the verification logic and manages third-party verifiers
 */
contract Verifier is Ownable, VerifierStorage {
    // Verifier mapping
    mapping(address => bool) private _thirdPartyVerifiers;
    
    // Verifier permissions
    mapping(address => mapping(bytes32 => bool)) private _verifierPermissions;
    
    // Reference to the attribute registry
    address private _attributeRegistry;
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Sets the attribute registry address
     * @param registry The address of the attribute registry
     */
    function setAttributeRegistry(address registry) external onlyOwner {
        require(registry != address(0), "Verifier: registry cannot be zero address");
        _attributeRegistry = registry;
    }
    
    /**
     * @dev Gets the current attribute registry address
     * @return The address of the attribute registry
     */
    function getAttributeRegistry() external view returns (address) {
        return _attributeRegistry;
    }
    
    /**
     * @dev Modifier to check if the caller is an authorized third-party verifier
     */
    modifier onlyVerifier() {
        require(_thirdPartyVerifiers[msg.sender], "Verifier: caller is not an authorized verifier");
        _;
    }
    
    /**
     * @dev Modifier to check if the verifier is authorized for a specific attribute type
     */
    modifier canVerify(bytes32 attributeType) {
        require(_verifierPermissions[msg.sender][attributeType], "Verifier: not authorized for this attribute type");
        _;
    }
    
    /**
     * @dev Sets or updates a third-party verifier's authorization
     * @param verifier Address of the third-party verifier
     * @param authorized Whether the verifier is authorized
     */
    function setThirdPartyVerifier(address verifier, bool authorized) external onlyOwner {
        _thirdPartyVerifiers[verifier] = authorized;
        emit AttributeEvents.ThirdPartyVerifierStatusChanged(verifier, authorized);
    }
    
    /**
     * @dev Sets permission for a third-party verifier to verify a specific attribute type
     * @param verifier Address of the third-party verifier
     * @param attributeType The attribute type
     * @param hasPermission Whether the verifier can verify this attribute type
     */
    function setVerifierPermission(address verifier, bytes32 attributeType, bool hasPermission) external onlyOwner {
        require(_thirdPartyVerifiers[verifier], "Verifier: address is not a verified third party");
        _verifierPermissions[verifier][attributeType] = hasPermission;
        emit AttributeEvents.ThirdPartyVerifierPermissionChanged(verifier, attributeType, hasPermission);
    }
    
    /**
     * @dev Event emitted when a verification request is submitted
     */
    event VerificationRequest(address indexed user, bytes32 indexed attributeType, bool value, uint256 expiryTimestamp, address indexed verifier);
    
    /**
     * @dev Event emitted when a revocation request is submitted
     */
    event RevocationRequest(address indexed user, bytes32 indexed attributeType, address indexed verifier);
    
    /**
     * @dev Submits a verification request with standard expiry
     * @param user Address of the user
     * @param attributeType The attribute type
     * @param value The attribute value
     */
    function submitVerification(address user, bytes32 attributeType, bool value)
        external
        onlyVerifier
        canVerify(attributeType)
    {
        // Emit the verification request event
        emit VerificationRequest(user, attributeType, value, 0, msg.sender);
        
        // Update the registry directly if it's set
        if (_attributeRegistry != address(0)) {
            try IAttributeRegistry(_attributeRegistry).setAttribute(user, attributeType, value) {
                // Success - registry updated
            } catch {
                // If registry update fails, the event is still emitted
                // This maintains backward compatibility
            }
        }
    }
    
    /**
     * @dev Submits a verification request with custom expiry
     * @param user Address of the user
     * @param attributeType The attribute type
     * @param value The attribute value
     * @param expiryTimestamp Custom expiry timestamp
     */
    function submitVerificationWithExpiry(address user, bytes32 attributeType, bool value, uint256 expiryTimestamp)
        external
        onlyVerifier
        canVerify(attributeType)
    {
        // Ensure expiry is in the future if set
        if (expiryTimestamp != 0) {
            require(expiryTimestamp > block.timestamp, "Verifier: expiry must be in the future");
        }
        
        // Emit the verification request event
        emit VerificationRequest(user, attributeType, value, expiryTimestamp, msg.sender);
        
        // Update the registry directly if it's set
        if (_attributeRegistry != address(0)) {
            try IAttributeRegistry(_attributeRegistry).setAttributeWithExpiry(user, attributeType, value, expiryTimestamp) {
                // Success - registry updated
            } catch {
                // If registry update fails, the event is still emitted
                // This maintains backward compatibility
            }
        }
    }
    
    /**
     * @dev Submits a revocation request for an attribute
     * @param user Address of the user
     * @param attributeType The attribute type to revoke
     */
    function submitRevocation(address user, bytes32 attributeType)
        external
        onlyVerifier
        canVerify(attributeType)
    {
        // Emit the revocation request event
        emit RevocationRequest(user, attributeType, msg.sender);
        
        // Update the registry directly if it's set
        if (_attributeRegistry != address(0)) {
            try IAttributeRegistry(_attributeRegistry).revokeAttribute(user, attributeType) {
                // Success - registry updated
            } catch {
                // If registry update fails, the event is still emitted
                // This maintains backward compatibility
            }
        }
    }
    
    /**
     * @dev Checks if an address is an authorized third-party verifier
     * @param verifier The address to check
     * @return bool True if the address is an authorized verifier
     */
    function isThirdPartyVerifier(address verifier) public view returns (bool) {
        return _thirdPartyVerifiers[verifier];
    }
    
    /**
     * @dev Checks if a verifier can verify a specific attribute
     * @param verifier The verifier address
     * @param attributeType The attribute type
     * @return bool True if the verifier can verify the attribute
     */
    function canVerifyAttribute(address verifier, bytes32 attributeType) public view returns (bool) {
        return _thirdPartyVerifiers[verifier] && _verifierPermissions[verifier][attributeType];
    }
    
    // Use events from the library instead of redefining
    using AttributeEvents for *;
}