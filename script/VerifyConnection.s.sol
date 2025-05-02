// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AttributeRegistry.sol";
import "../src/mixins/Verifier.sol";

/**
 * @title VerifyConnection
 * @dev Script to verify the connection between Verifier and AttributeRegistry
 * @notice Run with: source .env && forge script script/VerifyConnection.s.sol:VerifyConnection --rpc-url $RPC_URL
 */
contract VerifyConnection is Script {
    function run() external {
        // Get addresses from environment
        address verifierContractAddress = vm.envAddress("VERIFIER_CONTRACT_ADDRESS");
        address registryAddress = vm.envAddress("ATTRIBUTE_REGISTRY_ADDRESS");
        
        // Get contract instances
        Verifier verifier = Verifier(verifierContractAddress);
        AttributeRegistry registry = AttributeRegistry(registryAddress);
        
        // Log basic information
        console.log("Verifying connection between contracts");
        console.log("-------------------------------------");
        console.log("Verifier contract:", verifierContractAddress);
        console.log("AttributeRegistry contract:", registryAddress);
        
        // Check Verifier -> Registry connection
        address configuredRegistry;
        try verifier.getAttributeRegistry() returns (address addr) {
            configuredRegistry = addr;
            console.log("\nRegistry configured in Verifier:", configuredRegistry);
            
            if (configuredRegistry == address(0)) {
                console.log("ERROR: Verifier has no registry configured!");
                console.log("This means verification events won't update the registry's storage.");
            } else if (configuredRegistry != registryAddress) {
                console.log("ERROR: Verifier is pointing to a different registry than expected!");
                console.log("Expected:", registryAddress);
                console.log("Actual:", configuredRegistry);
            } else {
                console.log("SUCCESS: Verifier correctly points to the expected registry");
            }
        } catch {
            console.log("\nERROR: Could not determine the registry configured in Verifier");
        }
        
        // Check Registry -> Verifier connection
        address configuredVerifier;
        try registry.getVerifier() returns (address addr) {
            configuredVerifier = addr;
            console.log("\nVerifier configured in Registry:", configuredVerifier);
            
            if (configuredVerifier == address(0)) {
                console.log("ERROR: Registry has no verifier configured!");
            } else if (configuredVerifier != verifierContractAddress) {
                console.log("WARNING: Registry is pointing to a different verifier than expected!");
                console.log("Expected:", verifierContractAddress);
                console.log("Actual:", configuredVerifier);
            } else {
                console.log("SUCCESS: Registry correctly points to the expected verifier");
            }
        } catch {
            console.log("\nERROR: Could not determine the verifier configured in Registry");
        }
        
        // Check bidirectional connection
        console.log("\nBidirectional connection check:");
        if (configuredRegistry == registryAddress && configuredVerifier == verifierContractAddress) {
            console.log("SUCCESS: Bidirectional connection is correctly configured");
            console.log("✅ Verifier -> Registry connection is valid");
            console.log("✅ Registry -> Verifier connection is valid");
        } else {
            console.log("WARNING: Bidirectional connection is NOT correctly configured");
            
            if (configuredRegistry != registryAddress) {
                console.log("❌ Verifier -> Registry connection is invalid");
            } else {
                console.log("✅ Verifier -> Registry connection is valid");
            }
            
            if (configuredVerifier != verifierContractAddress) {
                console.log("❌ Registry -> Verifier connection is invalid");
            } else {
                console.log("✅ Registry -> Verifier connection is valid");
            }
        }
        
        // Summary
        console.log("\nSummary:");
        console.log("--------");
        if (configuredRegistry == address(0)) {
            console.log("The verifier has no registry configured. This means verification events");
            console.log("emitted by the verifier will not update the registry's storage.");
            console.log("\nTo fix this issue, run:");
            console.log("source .env && forge script script/ConnectContracts.s.sol:ConnectContracts --rpc-url $RPC_URL --broadcast");
        } else if (configuredRegistry != registryAddress) {
            console.log("The verifier is pointing to a different registry than expected.");
            console.log("This means verification events emitted by the verifier will update");
            console.log("a different registry's storage than the one you're checking.");
            console.log("\nTo fix this issue, run:");
            console.log("source .env && forge script script/ConnectContracts.s.sol:ConnectContracts --rpc-url $RPC_URL --broadcast");
        } else {
            console.log("The verifier is correctly configured to update the specified registry.");
            console.log("When verification events are emitted, they should update the registry's storage.");
            
            if (configuredVerifier != verifierContractAddress) {
                console.log("\nHowever, the registry is pointing to a different verifier.");
                console.log("This means only that verifier can directly call setAttribute methods.");
            } else {
                console.log("\nThe registry is also pointing to the correct verifier.");
                console.log("This bidirectional configuration is the expected setup.");
            }
        }
    }
}