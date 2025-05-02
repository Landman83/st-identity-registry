# Identity Registry

A decentralized identity verification and attribute registry system built on Polygon.

## Overview

The Identity Registry is a smart contract system for storing and verifying user attributes on the blockchain. It provides a secure, decentralized way to manage identity verification without relying on a central authority.

The system consists of two main components:

1. **Verifier Contract** - Manages third-party verifiers and verification requests
2. **Attribute Registry** - Stores verified user attributes with expiration timestamps

## Features

- On-chain storage of identity attributes
- Third-party verifier management
- Attribute verification with expiration dates
- Fine-grained permission control for verifiers

## Architecture

### Verifier Contract

The Verifier contract manages which addresses can verify attributes. It:
- Maintains a list of authorized third-party verifiers
- Controls which attribute types each verifier can validate
- Emits events when verification requests are submitted

### Attribute Registry

The Attribute Registry stores the verified attributes. It:
- Maps user addresses to their verified attributes
- Handles attribute expiration
- Only accepts attribute updates from authorized verifiers

## Deployment

The contracts are deployed on Polygon mainnet.


### Environment Setup

Create a `.env` file with the following variables:

```
DEPLOYER_ADDRESS=0xYourDeployerAddress
DEPLOYER_PRIVATE_KEY=0xYourPrivateKey
RPC_URL=https://polygon-rpc.com

VERIFIER_ADDRESS=0xVerifierUserAddress
USER_ADDRESS=0xUserToVerifyAddress

ATTRIBUTE_REGISTRY_ADDRESS=0x0cEfF46e830c96B4949232f4b68547DaE63334D2
VERIFIER_CONTRACT_ADDRESS=0xc6272494C80aAeD6d601058f174eab4a30508864
```

### Deployment Scripts

#### Deploy Contracts

To deploy new instances of the contracts:

```bash
source .env && forge script script/Deploy.s.sol:DeployPolygonMainnet --rpc-url $RPC_URL --broadcast
```

#### Add a Verifier

To add a verifier to the system:

```bash
source .env && forge script script/AddVerifier.s.sol:AddVerifier --rpc-url $RPC_URL --broadcast
```

#### Verify User Attributes

To verify attributes for a user:

```bash
source .env && forge script script/VerifyAddress.s.sol:VerifyAddress --rpc-url $RPC_URL --broadcast
```

#### Read Attribute Registry

To check attributes in the registry:

```bash
source .env && forge script script/ReadAttributeRegistry.s.sol:ReadAttributeRegistry --rpc-url $RPC_URL
```

## Attribute Types

The system supports various attribute types, including:

- `KYC_VERIFIED` - User has completed KYC verification
- `ACCREDITED_INVESTOR` - User is an accredited investor
- `COMPANY_INSIDER` - User is an insider of a company
- `US_PERSON` - User is a US person

Custom attribute types can be created as needed using `bytes32` values.

## Integration Notes

### Event Monitoring

The verification process emits events that can be monitored off-chain:

- `VerificationRequest(address indexed user, bytes32 indexed attributeType, bool value, uint256 expiryTimestamp, address indexed verifier)`
- `RevocationRequest(address indexed user, bytes32 indexed attributeType, address indexed verifier)`

### Direct Storage Updates

For immediate attribute storage updates, a separate process must:
1. Monitor for `VerificationRequest` events from the Verifier contract
2. Call `setAttribute` or `setAttributeWithExpiry` on the AttributeRegistry

## Development

### Requirements

- [Foundry](https://book.getfoundry.sh/)
- Polygon RPC URL
- Private key with MATIC for gas

### Commands

```bash
# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test

# Deploy contracts
forge script script/Deploy.s.sol:DeployPolygonMainnet --rpc-url $RPC_URL --broadcast
```

## License

MIT