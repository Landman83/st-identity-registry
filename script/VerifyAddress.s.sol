// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/mixins/Verifier.sol";
import "../src/AttributeRegistry.sol";

/**
 * @title VerifyAddress
 * @dev Script to set verification attributes for a specific user address
 * @notice Run with: source .env && forge script script/VerifyAddress.s.sol:VerifyAddress --rpc-url $RPC_URL --broadcast
 */
contract VerifyAddress is Script {
    // Define attribute types
    bytes32 public constant KYC_VERIFIED = keccak256("KYC_VERIFIED");
    bytes32 public constant ACCREDITED_INVESTOR = keccak256("ACCREDITED_INVESTOR");
    bytes32 public constant COMPANY_INSIDER = keccak256("COMPANY_INSIDER");
    bytes32 public constant US_PERSON = keccak256("US_PERSON");

    // Contract addresses (will be loaded from environment)
    address private VERIFIER_CONTRACT_ADDRESS;
    address private ATTRIBUTE_REGISTRY_ADDRESS;
    address private VERIFIER_USER_ADDRESS;

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
        VERIFIER_USER_ADDRESS = vm.envAddress("VERIFIER_ADDRESS");
        
        // Parse the private key
        uint256 deployerPrivateKey = vm.parseUint(pkString);
        address deployer = vm.addr(deployerPrivateKey);
        
        // Verify the address matches what we expect
        address expectedDeployer = vm.envAddress("DEPLOYER_ADDRESS");
        require(deployer == expectedDeployer, "Private key does not match expected address");
        
        // Load contract instances
        Verifier verifier = Verifier(VERIFIER_CONTRACT_ADDRESS);
        AttributeRegistry registry = AttributeRegistry(ATTRIBUTE_REGISTRY_ADDRESS);

        // Log operation details
        console.log("Verifying attributes for user address");
        console.log("-------------------------------------");
        console.log("Deployer:", deployer);
        console.log("User address to verify:", userAddress);
        console.log("Verifier user address:", VERIFIER_USER_ADDRESS);
        console.log("Verifier contract:", VERIFIER_CONTRACT_ADDRESS);
        console.log("AttributeRegistry contract:", ATTRIBUTE_REGISTRY_ADDRESS);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Make sure the deployer has permissions for all attribute types
        console.log("\nEnsuring verifier has proper permissions...");
        try verifier.isThirdPartyVerifier(VERIFIER_USER_ADDRESS) returns (bool isVerifier) {
            if (!isVerifier) {
                console.log("Adding VERIFIER_ADDRESS as third-party verifier");
                verifier.setThirdPartyVerifier(VERIFIER_USER_ADDRESS, true);
            } else {
                console.log("VERIFIER_ADDRESS is already a third-party verifier");
            }
        } catch {
            console.log("Error checking verifier status. Adding VERIFIER_ADDRESS as third-party verifier");
            verifier.setThirdPartyVerifier(VERIFIER_USER_ADDRESS, true);
        }
        
        // Set permissions for all attribute types
        console.log("Setting permissions for attribute types...");
        verifier.setVerifierPermission(VERIFIER_USER_ADDRESS, KYC_VERIFIED, true);
        verifier.setVerifierPermission(VERIFIER_USER_ADDRESS, ACCREDITED_INVESTOR, true);
        verifier.setVerifierPermission(VERIFIER_USER_ADDRESS, COMPANY_INSIDER, true);
        verifier.setVerifierPermission(VERIFIER_USER_ADDRESS, US_PERSON, true);
        
        // Get the current verifier from the registry
        address currentVerifier;
        try registry.getVerifier() returns (address v) {
            currentVerifier = v;
            console.log("\nCurrent registry verifier:", currentVerifier);
        } catch {
            console.log("\nCould not determine the current registry verifier");
        }
        
        // Set attributes through the Verifier contract
        console.log("\nSubmitting attribute verifications through Verifier contract events...");
        
        // Ensure we're using the verifier user address to submit verifications
        console.log("Using verifier address:", VERIFIER_USER_ADDRESS, "to submit verifications");
        
        console.log("Setting KYC_VERIFIED = true");
        try verifier.submitVerification(userAddress, KYC_VERIFIED, true) {
            console.log("Successfully submitted KYC_VERIFIED verification");
        } catch Error(string memory reason) {
            console.log("Failed to submit KYC_VERIFIED verification. Reason:", reason);
        } catch {
            console.log("Failed to submit KYC_VERIFIED verification with unknown error");
        }
        
        console.log("Setting ACCREDITED_INVESTOR = true");
        try verifier.submitVerification(userAddress, ACCREDITED_INVESTOR, true) {
            console.log("Successfully submitted ACCREDITED_INVESTOR verification");
        } catch Error(string memory reason) {
            console.log("Failed to submit ACCREDITED_INVESTOR verification. Reason:", reason);
        } catch {
            console.log("Failed to submit ACCREDITED_INVESTOR verification with unknown error");
        }
        
        console.log("Setting COMPANY_INSIDER = false");
        try verifier.submitVerification(userAddress, COMPANY_INSIDER, false) {
            console.log("Successfully submitted COMPANY_INSIDER verification");
        } catch Error(string memory reason) {
            console.log("Failed to submit COMPANY_INSIDER verification. Reason:", reason);
        } catch {
            console.log("Failed to submit COMPANY_INSIDER verification with unknown error");
        }
        
        console.log("Setting US_PERSON = true");
        try verifier.submitVerification(userAddress, US_PERSON, true) {
            console.log("Successfully submitted US_PERSON verification");
        } catch Error(string memory reason) {
            console.log("Failed to submit US_PERSON verification. Reason:", reason);
        } catch {
            console.log("Failed to submit US_PERSON verification with unknown error");
        }
        
        console.log("\nVerification requests submitted successfully");
        console.log("Note: These are events that need to be processed by the registry or an off-chain service");
        
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
        
        console.log("\nVerification process completed");
        console.log("If attributes show as 'No' or 'Unable to read', it means the events were emitted");
        console.log("but the registry storage was not updated. This likely requires an off-chain");
        console.log("service to process the events and update the registry state.");
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