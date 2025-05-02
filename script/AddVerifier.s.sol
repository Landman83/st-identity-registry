// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/mixins/Verifier.sol";
import "../src/interfaces/IAttributeRegistry.sol";

/**
 * @title AddVerifier
 * @dev Script to add a verifier to the system and list all verifiers
 * @notice Run with: source .env && forge script script/AddVerifier.s.sol:AddVerifier --rpc-url $RPC_URL --broadcast
 */
contract AddVerifier is Script {
    // Standard attribute types (examples)
    bytes32 public constant KYC_ATTRIBUTE = keccak256("KYC");
    bytes32 public constant ACCREDITED_INVESTOR = keccak256("ACCREDITED_INVESTOR");
    bytes32 public constant AML_ATTRIBUTE = keccak256("AML");

    function run() external {
        // Get the private key from environment
        string memory pkString = vm.envString("DEPLOYER_PRIVATE_KEY");
        
        // Manually add 0x prefix if it's missing
        if (bytes(pkString).length > 0 && bytes(pkString)[0] != "0" && bytes(pkString)[1] != "x") {
            pkString = string(abi.encodePacked("0x", pkString));
        }
        
        // Get verifier address from environment
        address verifierAddress = vm.envAddress("VERIFIER_ADDRESS");
        
        // Parse the private key
        uint256 deployerPrivateKey = vm.parseUint(pkString);
        address deployer = vm.addr(deployerPrivateKey);
        
        // Verify the address matches what we expect
        address expectedDeployer = vm.envAddress("DEPLOYER_ADDRESS");
        require(deployer == expectedDeployer, "Private key does not match expected address");
        
        // Get the Verifier contract address
        address verifierContractAddress = 0xc6272494C80aAeD6d601058f174eab4a30508864;
        
        // Get the AttributeRegistry contract address
        address attributeRegistryAddress = 0x0cEfF46e830c96B4949232f4b68547DaE63334D2;
        
        console.log("Script configuration:");
        console.log("---------------------");
        console.log("Deployer address:", deployer);
        console.log("Verifier contract address:", verifierContractAddress);
        console.log("AttributeRegistry contract address:", attributeRegistryAddress);
        console.log("Address to add as verifier:", verifierAddress);
        
        // Create contract instances
        Verifier verifier = Verifier(verifierContractAddress);
        // We won't need the registry in this script since we're focusing on the verifier
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Check if the verifier address is already a verifier
        bool isAlreadyVerifier;
        try verifier.isThirdPartyVerifier(verifierAddress) returns (bool result) {
            isAlreadyVerifier = result;
            console.log("\nIs", verifierAddress, "already a verifier?", isAlreadyVerifier ? "Yes" : "No");
        } catch {
            console.log("\nError checking if address is a verifier. Assuming it is not.");
            isAlreadyVerifier = false;
        }
        
        // Add verifier if not already added
        if (!isAlreadyVerifier) {
            console.log("\nAdding verifier to the system...");
            verifier.setThirdPartyVerifier(verifierAddress, true);
            console.log("Verifier added successfully");
            
            // Set permissions for common attribute types
            console.log("Setting permissions for attribute types...");
            verifier.setVerifierPermission(verifierAddress, KYC_ATTRIBUTE, true);
            verifier.setVerifierPermission(verifierAddress, ACCREDITED_INVESTOR, true);
            verifier.setVerifierPermission(verifierAddress, AML_ATTRIBUTE, true);
            console.log("Permissions set successfully");
        } else {
            console.log("\nVerifier is already authorized in the system");
            
            // Check existing permissions
            console.log("Current permissions for verifier:");
            console.log("- KYC:", verifier.canVerifyAttribute(verifierAddress, KYC_ATTRIBUTE) ? "Yes" : "No");
            console.log("- ACCREDITED_INVESTOR:", verifier.canVerifyAttribute(verifierAddress, ACCREDITED_INVESTOR) ? "Yes" : "No");
            console.log("- AML:", verifier.canVerifyAttribute(verifierAddress, AML_ATTRIBUTE) ? "Yes" : "No");
        }
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // This is a read-only operation outside of the broadcast
        console.log("\nVerifier Information Summary:");
        console.log("-----------------------------");
        console.log("Third-party verifiers:");
        console.log("- Address:", verifierAddress);
        
        // Use try-catch to handle potential errors
        try verifier.isThirdPartyVerifier(verifierAddress) returns (bool isAuthorized) {
            console.log("  Authorized:", isAuthorized ? "Yes" : "No");
            
            if (isAuthorized) {
                bool kycPermission;
                bool accreditedPermission;
                bool amlPermission;
                
                try verifier.canVerifyAttribute(verifierAddress, KYC_ATTRIBUTE) returns (bool result) {
                    kycPermission = result;
                } catch { kycPermission = false; }
                
                try verifier.canVerifyAttribute(verifierAddress, ACCREDITED_INVESTOR) returns (bool result) {
                    accreditedPermission = result;
                } catch { accreditedPermission = false; }
                
                try verifier.canVerifyAttribute(verifierAddress, AML_ATTRIBUTE) returns (bool result) {
                    amlPermission = result;
                } catch { amlPermission = false; }
                
                console.log("  KYC permission:", kycPermission ? "Yes" : "No");
                console.log("  Accredited Investor permission:", accreditedPermission ? "Yes" : "No");
                console.log("  AML permission:", amlPermission ? "Yes" : "No");
            }
        } catch {
            console.log("  Unable to verify authorization status");
        }
    }
}