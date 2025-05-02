// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AttributeRegistry.sol";
import "../src/mixins/Verifier.sol";

/**
 * @title SetAttributeDirect
 * @dev Script to test setting attributes directly via the AttributeRegistry contract
 * @notice Run with: source .env && forge script script/SetAttributeDirect.s.sol:SetAttributeDirect --rpc-url $RPC_URL --broadcast
 */
contract SetAttributeDirect is Script {
    // Define attribute types
    bytes32 public constant KYC_VERIFIED = keccak256("KYC_VERIFIED");
    bytes32 public constant ACCREDITED_INVESTOR = keccak256("ACCREDITED_INVESTOR");
    bytes32 public constant COMPANY_INSIDER = keccak256("COMPANY_INSIDER");
    bytes32 public constant US_PERSON = keccak256("US_PERSON");

    // Contract addresses (will be loaded from environment)
    address private VERIFIER_CONTRACT_ADDRESS;
    address private ATTRIBUTE_REGISTRY_ADDRESS;
    
    function run() external {
        // Get the private key from environment
        string memory pkString = vm.envString("DEPLOYER_PRIVATE_KEY");
        
        // Manually add 0x prefix if it's missing
        if (bytes(pkString).length > 0 && bytes(pkString)[0] != "0" && bytes(pkString)[1] != "x") {
            pkString = string(abi.encodePacked("0x", pkString));
        }
        
        // Get addresses from environment
        address userAddress = vm.envAddress("USER_ADDRESS");
        ATTRIBUTE_REGISTRY_ADDRESS = vm.envAddress("ATTRIBUTE_REGISTRY_ADDRESS");
        VERIFIER_CONTRACT_ADDRESS = vm.envAddress("VERIFIER_CONTRACT_ADDRESS");
        
        // Parse the private key
        uint256 deployerPrivateKey = vm.parseUint(pkString);
        address deployer = vm.addr(deployerPrivateKey);
        
        // Verify the address matches what we expect
        address expectedDeployer = vm.envAddress("DEPLOYER_ADDRESS");
        require(deployer == expectedDeployer, "Private key does not match expected address");
        
        // Load contract instances
        AttributeRegistry registry = AttributeRegistry(ATTRIBUTE_REGISTRY_ADDRESS);

        // Log operation details
        console.log("Setting attributes directly via AttributeRegistry");
        console.log("---------------------------------------------");
        console.log("Deployer:", deployer);
        console.log("User address to verify:", userAddress);
        console.log("AttributeRegistry contract:", ATTRIBUTE_REGISTRY_ADDRESS);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get the current verifier from the registry
        address currentVerifier;
        try registry.getVerifier() returns (address v) {
            currentVerifier = v;
            console.log("\nCurrent registry verifier:", currentVerifier);
        } catch {
            console.log("\nCould not determine the current registry verifier");
        }
        
        // Check if deployer is the authorized verifier
        console.log("\nChecking if deployer is authorized verifier...");
        if (currentVerifier == deployer) {
            console.log("Deployer is the authorized verifier - can set attributes directly");
        } else {
            console.log("WARNING: Deployer is NOT the authorized verifier!");
            console.log("Expected:", deployer);
            console.log("Actual:", currentVerifier);
            console.log("Direct attribute setting will likely fail.");
            
            // Optionally update the verifier to the deployer
            console.log("\nAttempting to update verifier to deployer address...");
            try registry.setVerifier(deployer) {
                console.log("Successfully updated verifier to deployer");
                currentVerifier = deployer;
            } catch Error(string memory reason) {
                console.log("Failed to update verifier. Reason:", reason);
            } catch {
                console.log("Failed to update verifier with unknown error");
            }
        }
        
        // Set attributes directly through the Registry
        console.log("\nSetting attributes directly through AttributeRegistry...");
        
        // KYC_VERIFIED
        console.log("Setting KYC_VERIFIED = true");
        try registry.setAttribute(userAddress, KYC_VERIFIED, true) {
            console.log("Successfully set KYC_VERIFIED attribute");
        } catch Error(string memory reason) {
            console.log("Failed to set KYC_VERIFIED. Reason:", reason);
        } catch {
            console.log("Failed to set KYC_VERIFIED with unknown error");
        }
        
        // ACCREDITED_INVESTOR
        console.log("Setting ACCREDITED_INVESTOR = true");
        try registry.setAttribute(userAddress, ACCREDITED_INVESTOR, true) {
            console.log("Successfully set ACCREDITED_INVESTOR attribute");
        } catch Error(string memory reason) {
            console.log("Failed to set ACCREDITED_INVESTOR. Reason:", reason);
        } catch {
            console.log("Failed to set ACCREDITED_INVESTOR with unknown error");
        }
        
        // COMPANY_INSIDER
        console.log("Setting COMPANY_INSIDER = false");
        try registry.setAttribute(userAddress, COMPANY_INSIDER, false) {
            console.log("Successfully set COMPANY_INSIDER attribute");
        } catch Error(string memory reason) {
            console.log("Failed to set COMPANY_INSIDER. Reason:", reason);
        } catch {
            console.log("Failed to set COMPANY_INSIDER with unknown error");
        }
        
        // US_PERSON
        console.log("Setting US_PERSON = true");
        try registry.setAttribute(userAddress, US_PERSON, true) {
            console.log("Successfully set US_PERSON attribute");
        } catch Error(string memory reason) {
            console.log("Failed to set US_PERSON. Reason:", reason);
        } catch {
            console.log("Failed to set US_PERSON with unknown error");
        }
        
        // Set an attribute with custom expiry
        console.log("\nSetting attribute with custom expiry...");
        uint256 expiryTimestamp = block.timestamp + 90 days;
        console.log("Setting KYC_VERIFIED with 90-day expiry");
        try registry.setAttributeWithExpiry(userAddress, KYC_VERIFIED, true, expiryTimestamp) {
            console.log("Successfully set KYC_VERIFIED with expiry:", expiryTimestamp);
        } catch Error(string memory reason) {
            console.log("Failed to set KYC_VERIFIED with expiry. Reason:", reason);
        } catch {
            console.log("Failed to set KYC_VERIFIED with expiry. Unknown error.");
        }
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Read directly from registry to verify storage state
        console.log("\nReading current attribute values from registry...");
        console.log("---------------------------------------------");
        console.log("User address:", userAddress);
        
        // KYC_VERIFIED
        try registry.hasAttribute(userAddress, KYC_VERIFIED) returns (bool hasKYC) {
            console.log("KYC_VERIFIED: ", hasKYC ? "Yes" : "No");
            if (hasKYC) {
                try registry.getAttributeExpiry(userAddress, KYC_VERIFIED) returns (uint256 expiry) {
                    if (expiry > 0) {
                        console.log("  Expires at:", expiry);
                        console.log("  Expires in:", expiry > block.timestamp ? formatTimeRemaining(expiry - block.timestamp) : "Expired");
                    } else {
                        console.log("  No expiration");
                    }
                } catch {
                    console.log("  Unable to read expiration");
                }
            }
        } catch {
            console.log("KYC_VERIFIED: Unable to read");
        }
        
        // ACCREDITED_INVESTOR
        try registry.hasAttribute(userAddress, ACCREDITED_INVESTOR) returns (bool hasAccredited) {
            console.log("ACCREDITED_INVESTOR: ", hasAccredited ? "Yes" : "No");
            if (hasAccredited) {
                try registry.getAttributeExpiry(userAddress, ACCREDITED_INVESTOR) returns (uint256 expiry) {
                    if (expiry > 0) {
                        console.log("  Expires at:", expiry);
                        console.log("  Expires in:", expiry > block.timestamp ? formatTimeRemaining(expiry - block.timestamp) : "Expired");
                    } else {
                        console.log("  No expiration");
                    }
                } catch {
                    console.log("  Unable to read expiration");
                }
            }
        } catch {
            console.log("ACCREDITED_INVESTOR: Unable to read");
        }
        
        // COMPANY_INSIDER
        try registry.hasAttribute(userAddress, COMPANY_INSIDER) returns (bool hasInsider) {
            console.log("COMPANY_INSIDER: ", hasInsider ? "Yes" : "No");
            if (hasInsider) {
                try registry.getAttributeExpiry(userAddress, COMPANY_INSIDER) returns (uint256 expiry) {
                    if (expiry > 0) {
                        console.log("  Expires at:", expiry);
                        console.log("  Expires in:", expiry > block.timestamp ? formatTimeRemaining(expiry - block.timestamp) : "Expired");
                    } else {
                        console.log("  No expiration");
                    }
                } catch {
                    console.log("  Unable to read expiration");
                }
            }
        } catch {
            console.log("COMPANY_INSIDER: Unable to read");
        }
        
        // US_PERSON
        try registry.hasAttribute(userAddress, US_PERSON) returns (bool hasUSPerson) {
            console.log("US_PERSON: ", hasUSPerson ? "Yes" : "No");
            if (hasUSPerson) {
                try registry.getAttributeExpiry(userAddress, US_PERSON) returns (uint256 expiry) {
                    if (expiry > 0) {
                        console.log("  Expires at:", expiry);
                        console.log("  Expires in:", expiry > block.timestamp ? formatTimeRemaining(expiry - block.timestamp) : "Expired");
                    } else {
                        console.log("  No expiration");
                    }
                } catch {
                    console.log("  Unable to read expiration");
                }
            }
        } catch {
            console.log("US_PERSON: Unable to read");
        }
        
        console.log("\nDirect attribute setting process completed");
        
        // Summary of results
        console.log("\n-----------------------------------");
        console.log("Summary of direct attribute setting:");
        console.log("-----------------------------------");
        if (currentVerifier != deployer) {
            console.log("WARNING: The deployer address is not the authorized verifier!");
            console.log("This explains why direct attribute setting failed if it did.");
            console.log("Options to fix:");
            console.log("1. Update the AttributeRegistry to use deployer as verifier");
            console.log("2. Use the authorized verifier address to set attributes");
        } else {
            console.log("Deployer is the authorized verifier");
            console.log("Attributes should have been set successfully if no errors were shown");
        }
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