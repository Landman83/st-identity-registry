// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/AttributeRegistry.sol";
import "../src/mixins/Verifier.sol";
import "../src/libraries/Attributes.sol";

/**
 * @title Mock Token
 * @dev A simple mock token contract to test attribute checking integration
 */
contract MockToken {
    AttributeRegistry public registry;
    bytes32 public attributeType;

    constructor(address _registry, bytes32 _attributeType) {
        registry = AttributeRegistry(_registry);
        attributeType = _attributeType;
    }

    function checkAttribute(address user) external view returns (bool) {
        return registry.hasAttribute(user, attributeType);
    }

    function getAttributeExpiry(address user) external view returns (uint256) {
        return registry.getAttributeExpiry(user, attributeType);
    }
}

/**
 * @title AttributeRegistryTest
 * @dev Tests for the attribute registry system
 */
contract AttributeRegistryTest is Test {
    // Contracts
    AttributeRegistry public registry;
    Verifier public verifier;
    MockToken public token;

    // Test accounts
    address public deployer = address(this);
    address public verifier1 = address(0x1);
    address public verifier2 = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public nonVerifier = address(0x5);

    // Test attribute types
    bytes32 public constant KYC_ATTRIBUTE = Attributes.KYC_VERIFIED;
    bytes32 public constant ACCREDITED_ATTRIBUTE = Attributes.ACCREDITED_INVESTOR;
    
    function setUp() public {
        // Deploy the verifier contract
        verifier = new Verifier();
        
        // Deploy the registry contract
        registry = new AttributeRegistry(address(verifier));
        
        // Deploy the mock token
        token = new MockToken(address(registry), KYC_ATTRIBUTE);
        
        // Setup verifiers
        vm.startPrank(deployer);
        verifier.setThirdPartyVerifier(verifier1, true);
        verifier.setThirdPartyVerifier(verifier2, true);
        
        // Setup permissions for verifiers
        verifier.setVerifierPermission(verifier1, KYC_ATTRIBUTE, true);
        verifier.setVerifierPermission(verifier2, ACCREDITED_ATTRIBUTE, true);
        vm.stopPrank();
    }

    // ============== VERIFIER MANAGEMENT TESTS ==============

    function testDeployerCanChangeVerifier() public {
        // Deployer can change the main verifier
        vm.prank(deployer);
        registry.setVerifier(address(0x99));
        assertEq(registry.getVerifier(), address(0x99));

        // Change it back
        vm.prank(deployer);
        registry.setVerifier(address(verifier));
    }

    function testNonDeployerCannotChangeVerifier() public {
        // Non-deployer cannot change the verifier
        vm.prank(nonVerifier);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonVerifier));
        registry.setVerifier(address(0x99));
    }

    function testManageThirdPartyVerifiers() public {
        // Test adding a new verifier
        vm.prank(deployer);
        verifier.setThirdPartyVerifier(nonVerifier, true);
        assertTrue(verifier.isThirdPartyVerifier(nonVerifier));

        // Test removing a verifier
        vm.prank(deployer);
        verifier.setThirdPartyVerifier(nonVerifier, false);
        assertFalse(verifier.isThirdPartyVerifier(nonVerifier));

        // Test non-deployer cannot add verifiers
        vm.prank(nonVerifier);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonVerifier));
        verifier.setThirdPartyVerifier(nonVerifier, true);
    }

    function testVerifierPermissions() public {
        // Test granting attribute permissions
        vm.startPrank(deployer);
        verifier.setVerifierPermission(verifier1, ACCREDITED_ATTRIBUTE, true);
        assertTrue(verifier.canVerifyAttribute(verifier1, ACCREDITED_ATTRIBUTE));

        // Test revoking attribute permissions
        verifier.setVerifierPermission(verifier1, ACCREDITED_ATTRIBUTE, false);
        assertFalse(verifier.canVerifyAttribute(verifier1, ACCREDITED_ATTRIBUTE));
        vm.stopPrank();

        // Test non-deployer cannot manage permissions
        vm.prank(nonVerifier);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonVerifier));
        verifier.setVerifierPermission(verifier1, KYC_ATTRIBUTE, false);
    }

    // ============== ATTRIBUTE SETTING TESTS ==============

    function testMainVerifierCanSetAttributes() public {
        // Main verifier can set attributes
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
    }

    function testNonVerifierCannotSetAttributes() public {
        // Non-verifier cannot set attributes
        vm.prank(nonVerifier);
        vm.expectRevert("AttributeRegistry: caller is not the authorized verifier");
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
    }

    function testAttributeWithCustomExpiry() public {
        // Set attribute with custom expiry
        uint256 expiryTime = block.timestamp + 30 days;
        
        vm.prank(address(verifier));
        registry.setAttributeWithExpiry(user1, KYC_ATTRIBUTE, true, expiryTime);
        
        // Check if attribute is set
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // Check expiry time
        assertEq(registry.getAttributeExpiry(user1, KYC_ATTRIBUTE), expiryTime);
    }

    function testCannotSetPastExpiry() public {
        // Set the block timestamp to a non-zero value to ensure we have room to create a past timestamp
        vm.warp(10000);
        
        // Create a past timestamp that's non-zero (timestamp 5000 is before current 10000)
        uint256 pastTime = 5000;
        
        // Ensure our test conditions are correct
        assertGt(block.timestamp, pastTime); // Current time should be > past time
        assertGt(pastTime, 0);               // Past time should be > 0 to avoid the special case
        
        // Print values to help debug
        console.log("Current timestamp:", block.timestamp);
        console.log("Past timestamp:", pastTime);
        
        vm.prank(address(verifier));
        vm.expectRevert("AttributeRegistry: expiry must be in the future");
        registry.setAttributeWithExpiry(user1, KYC_ATTRIBUTE, true, pastTime);
    }

    // ============== ATTRIBUTE EXPIRY TESTS ==============

    function testAttributeStandardExpiry() public {
        // Set attribute with standard expiry (365 days)
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        
        // Check if it's valid now
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // Check if expires correctly after 365 days
        uint256 expiryTime = registry.getAttributeExpiry(user1, KYC_ATTRIBUTE);
        assertEq(expiryTime, block.timestamp + 365 days);
        
        // Warp to just before expiry
        vm.warp(expiryTime - 1);
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // Warp to after expiry
        vm.warp(expiryTime + 1);
        assertFalse(registry.hasAttribute(user1, KYC_ATTRIBUTE));
    }

    function testAttributeWithNoExpiry() public {
        // Set attribute with no expiry (0)
        vm.prank(address(verifier));
        registry.setAttributeWithExpiry(user1, KYC_ATTRIBUTE, true, 0);
        
        // Check if it's valid now
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // Warp to far in the future (1000 years in seconds)
        vm.warp(block.timestamp + 1000 * 365 days);
        
        // Should still be valid
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
    }

    // ============== ATTRIBUTE REVOCATION TESTS ==============

    function testAttributeRevocation() public {
        // Set attribute
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // Revoke attribute
        vm.prank(address(verifier));
        registry.revokeAttribute(user1, KYC_ATTRIBUTE);
        
        // Check that it's revoked
        assertFalse(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // The expiry should be 0
        assertEq(registry.getAttributeExpiry(user1, KYC_ATTRIBUTE), 0);
    }

    function testOnlyVerifierCanRevoke() public {
        // Set attribute
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        
        // Non-verifier cannot revoke
        vm.prank(nonVerifier);
        vm.expectRevert("AttributeRegistry: caller is not the authorized verifier");
        registry.revokeAttribute(user1, KYC_ATTRIBUTE);
    }

    // ============== EXTERNAL CONTRACT INTEGRATION TESTS ==============

    function testExternalContractCanCheckAttributes() public {
        // Set attribute for user1
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        
        // External contract can check attribute
        assertTrue(token.checkAttribute(user1));
        assertFalse(token.checkAttribute(user2));

        // External contract can check expiry
        uint256 expectedExpiry = block.timestamp + 365 days;
        assertEq(token.getAttributeExpiry(user1), expectedExpiry);
    }

    function testAttributeExpiryVisibleToExternalContract() public {
        // Set attribute with custom expiry
        uint256 customExpiry = block.timestamp + 30 days;
        
        vm.prank(address(verifier));
        registry.setAttributeWithExpiry(user1, KYC_ATTRIBUTE, true, customExpiry);
        
        // External contract sees correct expiry
        assertEq(token.getAttributeExpiry(user1), customExpiry);
        
        // Warp to after expiry
        vm.warp(customExpiry + 1);
        
        // External contract correctly sees expired attribute
        assertFalse(token.checkAttribute(user1));
    }

    // ============== COMPLEX SCENARIO TESTS ==============

    function testCompleteUserJourney() public {
        // 1. User gets KYC verified
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // 2. User gets accredited investor status with custom expiry
        uint256 accreditedExpiry = block.timestamp + 180 days; // 6 months
        vm.prank(address(verifier));
        registry.setAttributeWithExpiry(user1, ACCREDITED_ATTRIBUTE, true, accreditedExpiry);
        assertTrue(registry.hasAttribute(user1, ACCREDITED_ATTRIBUTE));
        
        // 3. After 4 months, accredited is still valid but approaching expiry
        vm.warp(block.timestamp + 120 days);
        assertTrue(registry.hasAttribute(user1, ACCREDITED_ATTRIBUTE));
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // 4. After 7 months, accredited has expired but KYC is still valid
        vm.warp(block.timestamp + 90 days);
        assertFalse(registry.hasAttribute(user1, ACCREDITED_ATTRIBUTE));
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // 5. KYC gets revoked
        vm.prank(address(verifier));
        registry.revokeAttribute(user1, KYC_ATTRIBUTE);
        assertFalse(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // 6. User gets KYC re-verified
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // 7. After 13 months from re-verification, KYC expires
        vm.warp(block.timestamp + 396 days);
        assertFalse(registry.hasAttribute(user1, KYC_ATTRIBUTE));
    }

    function testChangingMainVerifier() public {
        // 1. Set attribute using current verifier
        vm.prank(address(verifier));
        registry.setAttribute(user1, KYC_ATTRIBUTE, true);
        assertTrue(registry.hasAttribute(user1, KYC_ATTRIBUTE));
        
        // 2. Change main verifier
        address newVerifierAddr = address(0x99);
        vm.prank(deployer);
        registry.setVerifier(newVerifierAddr);
        assertEq(registry.getVerifier(), newVerifierAddr);
        
        // 3. Old verifier can no longer set attributes
        vm.prank(address(verifier));
        vm.expectRevert("AttributeRegistry: caller is not the authorized verifier");
        registry.setAttribute(user2, KYC_ATTRIBUTE, true);
        
        // 4. New verifier can set attributes
        vm.prank(newVerifierAddr);
        registry.setAttribute(user2, KYC_ATTRIBUTE, true);
        assertTrue(registry.hasAttribute(user2, KYC_ATTRIBUTE));
        
        // 5. Change back to old verifier
        vm.prank(deployer);
        registry.setVerifier(address(verifier));
    }
}