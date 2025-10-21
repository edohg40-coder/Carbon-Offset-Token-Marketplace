# 🌱 Carbon Offset Token Marketplace

A decentralized marketplace for trading carbon offset tokens built on the Stacks blockchain using Clarity smart contracts.

## 📋 Overview

This smart contract enables the creation, trading, and retirement of carbon offset tokens. It provides a transparent and secure platform for carbon credit transactions with built-in verification mechanisms.

## ✨ Features

- 🏭 **Issue Carbon Offsets**: Create tokenized carbon offsets with project details and verification standards
- 🔍 **Issuer Verification**: Contract owner can verify legitimate carbon credit issuers
- 🛒 **Direct Purchase**: Buy carbon offsets directly from issuers
- 📈 **Marketplace Trading**: Create listings and trade carbon offsets with other users
- 🔥 **Offset Retirement**: Permanently retire carbon offsets to claim environmental benefits
- 💰 **Fee Management**: Configurable marketplace fees for sustainable operation

## 🚀 Getting Started

### Prerequisites

- Clarinet installed
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Run `clarinet check` to verify contract compilation
3. Use `clarinet test` to run unit tests

## 📖 Contract Functions

### Public Functions

#### Issue Carbon Offset
```clarity
(issue-carbon-offset project-name co2-amount verification-standard vintage-year price-per-token total-supply expiry-block)
```
Creates a new carbon offset with specified parameters.

#### Purchase Offset
```clarity
(purchase-offset offset-id quantity)
```
Purchase carbon offsets directly from the issuer.

#### Create Listing
```clarity
(create-listing offset-id quantity price-per-token expiry-block)
```
List your carbon offsets for sale in the marketplace.

#### Purchase from Listing
```clarity
(purchase-from-listing listing-id quantity)
```
Buy carbon offsets from marketplace listings.

#### Retire Offset
```clarity
(retire-offset offset-id quantity)
```
Permanently retire carbon offsets to prevent double counting.

#### Verify Issuer (Owner Only)
```clarity
(verify-issuer issuer)
```
Mark an issuer as verified (only contract owner).

### Read-Only Functions

- `get-offset`: Get carbon offset details
- `get-user-balance`: Check user's offset balance
- `get-listing`: Get marketplace listing details  
- `get-marketplace-fee-rate`: Current marketplace fee rate
- `is-verified-issuer`: Check if issuer is verified
- `get-token-balance`: Get fungible token balance
- `get-total-supply`: Total token supply

## 🔧 Usage Examples

### Issuing a Carbon Offset

```clarity
(contract-call? .carbon-offset-marketplace issue-carbon-offset 
  "Forest Conservation Project" 
  u1000 
  "VCS" 
  u2023 
  u10 
  u500 
  u1000000)
```

### Purchasing Offsets

```clarity
(contract-call? .carbon-offset-marketplace purchase-offset u1 u50)
```

### Creating a Marketplace Listing

```clarity
(contract-call? .carbon-offset-marketplace create-listing u1 u100 u12 u2000000)
```

## 💡 Key Concepts

- **Offset ID**: Unique identifier for each carbon offset project
- **Verification**: Issuers can be verified by the contract owner for credibility
- **Expiry**: All offsets and listings have expiry blocks to prevent stale data
- **Marketplace Fee**: Small fee collected on transactions (default 2.5%)
- **Token Supply**: Fungible tokens represent tradeable carbon credits

## 🔒 Security Features

- Owner-only functions for critical operations
- Input validation on all parameters
- Expiry checks to prevent stale transactions
- Balance verification before transfers
- Proper error handling with descriptive error codes

## 🌍 Environmental Impact

Each retired carbon offset token represents real environmental benefit. The contract ensures:
- No double counting through permanent token burning
- Transparent tracking of all transactions
- Immutable record of carbon offset retirement

## 🤝 Contributing

Contributions are welcome! Please ensure all changes pass `clarinet check` and maintain the contract's security standards.

## 📄 License

MIT License - feel free to use and modify for your carbon offset projects!
