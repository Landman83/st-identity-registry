// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AttributeRegistry.sol";
import "../src/mixins/Verifier.sol";

/**
 * @title DeployIdentityRegistry
 * @dev Script to deploy the Verifier and AttributeRegistry contracts
 */
contract DeployIdentityRegistry is Script {
    function run() external {
        // First default Anvil private key
        uint256 privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        // First default Anvil address: derived from the private key
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        
        // Explicitly verify these match
        require(vm.addr(privateKey) == deployer, "Private key doesn't match expected address");
        
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);
        
        // Log deployment information
        console.log("Deploying contracts to chain ID:", block.chainid);
        console.log("Deployer address:", deployer);
        
        // Deploy the Verifier contract
        Verifier verifier = new Verifier();
        console.log("Verifier deployed at:", address(verifier));
        
        // Deploy the AttributeRegistry contract with the Verifier as the initial verifier
        AttributeRegistry registry = new AttributeRegistry(address(verifier));
        console.log("AttributeRegistry deployed at:", address(registry));
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Output deployment summary
        console.log("\nDeployment Summary:");
        console.log("------------------");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Verifier:", address(verifier));
        console.log("AttributeRegistry:", address(registry));
    }
}

/**
 * @title DeployPolygonMainnet
 * @dev Script specifically configured for Polygon mainnet deployment
 */
contract DeployPolygonMainnet is Script {
    function run() external {
        // Get the private key from the environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Log deployment information
        console.log("Deploying contracts to Polygon mainnet (Chain ID:", block.chainid, ")");
        console.log("Deployer address:", deployer);
        
        // Deploy the Verifier contract
        Verifier verifier = new Verifier();
        console.log("Verifier deployed at:", address(verifier));
        
        // Deploy the AttributeRegistry contract with the Verifier as the initial verifier
        AttributeRegistry registry = new AttributeRegistry(address(verifier));
        console.log("AttributeRegistry deployed at:", address(registry));
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
        
        // Output deployment summary
        console.log("\nDeployment Summary:");
        console.log("------------------");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Verifier:", address(verifier));
        console.log("AttributeRegistry:", address(registry));
    }
}