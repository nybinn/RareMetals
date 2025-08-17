# RareMetals 🏗️

RareMetals is a synthetic assets smart contract built on the Stacks blockchain that creates synthetic exposure to rare earth elements and strategic materials. Users can mint synthetic tokens backed by STX collateral, providing exposure to precious metals price movements without holding physical assets.

## 🚀 Features

- **Synthetic Asset Creation**: Mint tokens representing exposure to rare earth metals
- **Collateralized System**: 150% minimum collateral ratio ensures system stability
- **Multi-Metal Support**: Currently supports Lithium, Cobalt, Neodymium, Platinum, and Palladium
- **Oracle Price Feeds**: Real-time price updates from authorized oracles
- **Price History Tracking**: Maintains historical price data for each metal
- **Position Management**: Track user collateral and synthetic token balances
- **Emergency Controls**: Contract pause functionality for security
- **Decentralized Oracles**: Multiple authorized price feed operators

## 📋 Technical Specifications

- **Blockchain**: Stacks (STX)
- **Language**: Clarity v2.5
- **Token Standard**: SIP-010 Fungible Token
- **Minimum Collateral Ratio**: 150%
- **Supported Metals**: 5 rare earth elements and precious metals
- **Price History**: Last 10 price updates per metal

### Supported Metals

| Metal | Symbol | Default Price (μSTX/gram) |
|-------|--------|---------------------------|
| Lithium | Li | 50,000 |
| Cobalt | Co | 30,000 |
| Neodymium | Nd | 80,000 |
| Platinum | Pt | 32,000,000 |
| Palladium | Pd | 72,000,000 |

## 🛠️ Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v1.8.0+
- [Node.js](https://nodejs.org/) v18+
- [Stacks CLI](https://docs.stacks.co/docs/write-smart-contracts/cli-wallet-quickstart)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd RareMetals
   ```

2. **Install dependencies**
   ```bash
   cd RareMetals_contract
   npm install
   ```

3. **Initialize the project**
   ```bash
   clarinet check
   ```

4. **Run tests**
   ```bash
   npm test
   ```

## 🎯 Usage Examples

### Initialize Supported Metals

```clarity
;; Initialize the default metals (owner only)
(contract-call? .RareMetals initialize-metals)
```

### Mint Synthetic Tokens

```clarity
;; Mint 100 synthetic tokens for Lithium exposure with 10,000 μSTX collateral
(contract-call? .RareMetals mint-synthetic 
  0x4c49544849554d ;; "LITHIUM" as hex buffer
  u10000000        ;; 10 STX as collateral (in μSTX)
  u100)            ;; 100 synthetic tokens
```

### Burn Synthetic Tokens

```clarity
;; Burn 50 synthetic tokens to reclaim collateral
(contract-call? .RareMetals burn-synthetic u50)
```

### Update Metal Prices (Oracle Only)

```clarity
;; Update Lithium price to 55,000 μSTX per gram
(contract-call? .RareMetals update-price 
  0x4c49544849554d ;; "LITHIUM" as hex buffer
  u55000)          ;; New price per gram
```

### Query Functions

```clarity
;; Get metal information
(contract-call? .RareMetals get-metal-info 0x4c49544849554d)

;; Get user position
(contract-call? .RareMetals get-user-position 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Get collateral ratio
(contract-call? .RareMetals get-collateral-ratio 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)

;; Get contract status
(contract-call? .RareMetals get-contract-status)
```

## 📖 Contract Functions Documentation

### Public Functions

#### Administrative Functions

- **`initialize-metals()`** - Initialize default supported metals (owner only)
- **`add-metal(metal-id, name, symbol, price)`** - Add new supported metal (owner only)
- **`add-oracle(oracle-address)`** - Authorize price oracle (owner only)
- **`remove-oracle(oracle-address)`** - Remove price oracle (owner only)
- **`set-contract-paused(paused)`** - Pause/unpause contract (owner only)

#### User Functions

- **`mint-synthetic(metal-id, stx-amount, synthetic-amount)`** - Mint synthetic tokens with STX collateral
- **`burn-synthetic(synthetic-amount)`** - Burn synthetic tokens to reclaim collateral

#### Oracle Functions

- **`update-price(metal-id, new-price)`** - Update metal price (authorized oracles only)

### Read-Only Functions

- **`get-metal-info(metal-id)`** - Get metal details and current price
- **`get-user-position(user)`** - Get user's collateral and token balance
- **`get-price-history(metal-id)`** - Get last 10 price updates for metal
- **`calculate-required-collateral(metal-id, synthetic-amount)`** - Calculate minimum collateral needed
- **`get-collateral-ratio(user)`** - Get user's current collateral ratio
- **`is-authorized-oracle(oracle)`** - Check if address is authorized oracle
- **`get-contract-status()`** - Get contract pause status and totals
- **`get-balance(user)`** - Get user's synthetic token balance

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR_UNAUTHORIZED` | Caller not authorized |
| 101 | `ERR_INSUFFICIENT_BALANCE` | Insufficient token balance |
| 102 | `ERR_INVALID_AMOUNT` | Invalid amount provided |
| 103 | `ERR_METAL_NOT_FOUND` | Metal not supported |
| 104 | `ERR_PRICE_FEED_ERROR` | Price feed malfunction |
| 105 | `ERR_INVALID_COLLATERAL_RATIO` | Insufficient collateral |
| 106 | `ERR_PAUSED` | Contract is paused |

## 🚀 Deployment Guide

### Local Development

1. **Start Clarinet console**
   ```bash
   clarinet console
   ```

2. **Deploy contract**
   ```clarity
   ::deploy_contracts
   ```

3. **Initialize metals**
   ```clarity
   (contract-call? .RareMetals initialize-metals)
   ```

### Testnet Deployment

1. **Configure testnet settings**
   ```bash
   # Edit settings/Testnet.toml with your testnet configuration
   ```

2. **Deploy to testnet**
   ```bash
   clarinet publish --testnet
   ```

### Mainnet Deployment

1. **Configure mainnet settings**
   ```bash
   # Edit settings/Mainnet.toml with your mainnet configuration
   ```

2. **Deploy to mainnet**
   ```bash
   clarinet publish --mainnet
   ```

## 🔒 Security Notes

### Key Security Features

- **Minimum Collateral Ratio**: 150% overcollateralization prevents undercollateralized positions
- **Oracle Authorization**: Only authorized addresses can update prices
- **Owner Controls**: Critical functions restricted to contract owner
- **Emergency Pause**: Contract can be paused in case of emergencies
- **Input Validation**: All user inputs are validated for security

### Security Considerations

- **Oracle Risk**: Contract depends on external price feeds; oracle failure could affect pricing
- **Collateral Risk**: STX price volatility affects collateral value
- **Liquidation**: Currently no automatic liquidation mechanism for undercollateralized positions
- **Admin Keys**: Contract owner has significant control over metal management

### Recommended Security Practices

1. **Multi-signature**: Use multi-signature wallet for owner functions
2. **Oracle Diversity**: Deploy multiple independent price oracles
3. **Monitoring**: Continuously monitor collateral ratios and system health
4. **Upgrades**: Consider implementing upgrade mechanisms for future improvements
5. **Audits**: Conduct thorough security audits before mainnet deployment

## 🧪 Testing

### Run Test Suite

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:report

# Watch mode for development
npm run test:watch
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: Multi-function workflows
- **Edge Cases**: Boundary conditions and error scenarios
- **Security Tests**: Authorization and validation checks

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/docs/write-smart-contracts/clarity-language/)
- [Clarinet Documentation](https://docs.hiro.so/clarinet/)
- [SIP-010 Token Standard](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md)

---

**⚠️ Disclaimer**: This is experimental software. Use at your own risk. Always conduct thorough testing and audits before deploying to mainnet.