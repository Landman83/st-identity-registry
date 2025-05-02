// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AttributeRegistry.sol";
import "../src/interfaces/IAttributeRegistry.sol";

/**
 * @title ReadAttributeRegistry
 * @dev Script to read and display user attributes from the registry
 * @notice Run with: source .env && forge script script/ReadAttributeRegistry.s.sol:ReadAttributeRegistry --rpc-url $RPC_URL
 */
contract ReadAttributeRegistry is Script {
    // Define common attribute types
    bytes32 public constant KYC_VERIFIED = keccak256("KYC_VERIFIED");
    bytes32 public constant ACCREDITED_INVESTOR = keccak256("ACCREDITED_INVESTOR");
    bytes32 public constant COMPANY_INSIDER = keccak256("COMPANY_INSIDER");
    bytes32 public constant US_PERSON = keccak256("US_PERSON");

    // Contract address (will be read from environment)
    address private ATTRIBUTE_REGISTRY;

    // Array of addresses to check
    address[] private addressesToCheck;

    function run() external {
        // Get registry address from environment
        ATTRIBUTE_REGISTRY = vm.envAddress("ATTRIBUTE_REGISTRY_ADDRESS");
        
        // Set up addresses to check
        setupAddressesToCheck();

        // Create registry instance
        IAttributeRegistry registry = IAttributeRegistry(ATTRIBUTE_REGISTRY);

        // Header
        console.log("Attribute Registry Report");
        console.log("=========================");
        console.log("Registry Contract:", ATTRIBUTE_REGISTRY);
        
        // Report on each address
        for (uint i = 0; i < addressesToCheck.length; i++) {
            address userAddress = addressesToCheck[i];
            console.log("\nAddress:", userAddress);
            
            // Read attributes
            try registry.hasAttribute(userAddress, KYC_VERIFIED) returns (bool hasKYC) {
                console.log("- KYC_VERIFIED:", hasKYC ? "Yes" : "No");
                if (hasKYC) {
                    try registry.getAttributeExpiry(userAddress, KYC_VERIFIED) returns (uint256 expiry) {
                        if (expiry > 0) {
                            console.log("  Expires at:", expiry);
                            console.log("  Expires in:", expiry > block.timestamp ? 
                                formatTimeRemaining(expiry - block.timestamp) : "Expired");
                        } else {
                            console.log("  No expiration");
                        }
                    } catch {
                        console.log("  Unable to read expiration");
                    }
                }
            } catch {
                console.log("- KYC_VERIFIED: Unable to read");
            }
            
            try registry.hasAttribute(userAddress, ACCREDITED_INVESTOR) returns (bool hasAccredited) {
                console.log("- ACCREDITED_INVESTOR:", hasAccredited ? "Yes" : "No");
                if (hasAccredited) {
                    try registry.getAttributeExpiry(userAddress, ACCREDITED_INVESTOR) returns (uint256 expiry) {
                        if (expiry > 0) {
                            console.log("  Expires at:", expiry);
                            console.log("  Expires in:", expiry > block.timestamp ? 
                                formatTimeRemaining(expiry - block.timestamp) : "Expired");
                        } else {
                            console.log("  No expiration");
                        }
                    } catch {
                        console.log("  Unable to read expiration");
                    }
                }
            } catch {
                console.log("- ACCREDITED_INVESTOR: Unable to read");
            }
            
            try registry.hasAttribute(userAddress, COMPANY_INSIDER) returns (bool hasInsider) {
                console.log("- COMPANY_INSIDER:", hasInsider ? "Yes" : "No");
                if (hasInsider) {
                    try registry.getAttributeExpiry(userAddress, COMPANY_INSIDER) returns (uint256 expiry) {
                        if (expiry > 0) {
                            console.log("  Expires at:", expiry);
                            console.log("  Expires in:", expiry > block.timestamp ? 
                                formatTimeRemaining(expiry - block.timestamp) : "Expired");
                        } else {
                            console.log("  No expiration");
                        }
                    } catch {
                        console.log("  Unable to read expiration");
                    }
                }
            } catch {
                console.log("- COMPANY_INSIDER: Unable to read");
            }
            
            try registry.hasAttribute(userAddress, US_PERSON) returns (bool hasUSPerson) {
                console.log("- US_PERSON:", hasUSPerson ? "Yes" : "No");
                if (hasUSPerson) {
                    try registry.getAttributeExpiry(userAddress, US_PERSON) returns (uint256 expiry) {
                        if (expiry > 0) {
                            console.log("  Expires at:", expiry);
                            console.log("  Expires in:", expiry > block.timestamp ? 
                                formatTimeRemaining(expiry - block.timestamp) : "Expired");
                        } else {
                            console.log("  No expiration");
                        }
                    } catch {
                        console.log("  Unable to read expiration");
                    }
                }
            } catch {
                console.log("- US_PERSON: Unable to read");
            }
        }
        
        console.log("\nReport complete");
    }
    
    /**
     * @dev Set up the list of addresses to check
     */
    function setupAddressesToCheck() private {
        // Add USER_ADDRESS from environment
        address userAddress = vm.envAddress("USER_ADDRESS");
        addressesToCheck.push(userAddress);
        
        // Add VERIFIER_ADDRESS from environment
        address verifierAddress = vm.envAddress("VERIFIER_ADDRESS");
        if (verifierAddress != userAddress) {
            addressesToCheck.push(verifierAddress);
        }
        
        // Add DEPLOYER_ADDRESS from environment
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployerAddress != userAddress && deployerAddress != verifierAddress) {
            addressesToCheck.push(deployerAddress);
        }
        
        // You can add more addresses to check here if needed
    }
    
    /**
     * @dev Format time remaining in a human-readable format
     * @param timeRemaining Time remaining in seconds
     * @return string Formatted time
     */
    function formatTimeRemaining(uint256 timeRemaining) private pure returns (string memory) {
        if (timeRemaining < 60) {
            return string(abi.encodePacked(vm.toString(timeRemaining), " seconds"));
        } else if (timeRemaining < 3600) {
            return string(abi.encodePacked(vm.toString(timeRemaining / 60), " minutes"));
        } else if (timeRemaining < 86400) {
            return string(abi.encodePacked(vm.toString(timeRemaining / 3600), " hours"));
        } else {
            return string(abi.encodePacked(vm.toString(timeRemaining / 86400), " days"));
        }
    }
}