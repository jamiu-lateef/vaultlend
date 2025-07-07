# VaultLend Protocol

> **Advanced Bitcoin Collateral Lending Protocol**  
> Transform your Bitcoin into productive capital without selling your assets

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-5546ff)](https://stacks.co/)
[![Clarity](https://img.shields.io/badge/Smart%20Contract-Clarity-orange)](https://clarity-lang.org/)

## 🚀 Overview

VaultLend is a revolutionary DeFi protocol that enables Bitcoin holders to unlock liquidity without selling their assets. By depositing Bitcoin as collateral, users can mint synthetic stablecoins while maintaining exposure to Bitcoin's price appreciation. The protocol features sophisticated risk management, automated liquidations, and institutional-grade security.

### Key Features

- **🔒 Over-Collateralized Lending**: 150% minimum collateral ratio ensures system stability
- **📊 Real-Time Risk Management**: Dynamic price oracle integration with staleness protection
- **⚡ Automated Liquidations**: Efficient liquidation engine with 10% penalty incentives
- **💰 Compound Interest**: Per-block interest accrual for precise calculations
- **🛡️ Emergency Controls**: Protocol pause functionality for security
- **📈 Position Analytics**: Comprehensive collateralization ratio tracking

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VaultLend Protocol                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Price Oracle  │    │  Interest Rate  │    │ Liquidation │  │
│  │     System      │    │     Engine      │    │   Engine    │  │
│  │                 │    │                 │    │             │  │
│  │ • BTC/USD Feed  │    │ • Per-block     │    │ • Health    │  │
│  │ • Staleness     │    │   Calculation   │    │   Check     │  │
│  │   Protection    │    │ • Compound      │    │ • Auto      │  │
│  │ • 24hr Expiry   │    │   Interest      │    │   Execute   │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                       │     │
│           └───────────────────────┼───────────────────────┘     │
│                                   │                             │
│  ┌─────────────────────────────────┼─────────────────────────┐   │
│  │              Core Protocol Logic               │         │   │
│  │                                                │         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │   │
│  │  │  Position   │  │ Collateral  │  │    Debt     │    │   │
│  │  │ Management  │  │ Management  │  │ Management  │    │   │
│  │  │             │  │             │  │             │    │   │
│  │  │• Create     │  │• Add        │  │• Mint       │    │   │
│  │  │• Update     │  │• Withdraw   │  │• Repay      │    │   │
│  │  │• Liquidate  │  │• Validate   │  │• Burn       │    │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                   │                             │
│  ┌─────────────────────────────────┼─────────────────────────┐   │
│  │                    Data Layer                           │   │
│  │                                                         │   │
│  │ ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │   │
│  │ │  Positions  │  │ Global State│  │ Synthetic Token │   │   │
│  │ │     Map     │  │ Variables   │  │   (stable-usd)  │   │   │
│  │ │             │  │             │  │                 │   │   │
│  │ │• Collateral │  │• Total Debt │  │• ERC-20 Like    │   │   │
│  │ │• Debt       │  │• Total      │  │• Mint/Burn      │   │   │
│  │ │• Last Update│  │  Collateral │  │• Transfer       │   │   │
│  │ └─────────────┘  └─────────────┘  └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Contract Architecture

### Core Components

#### 1. **Position Management**

- **Data Structure**: `positions` map storing user collateral, debt, and update timestamps
- **Functions**: `create-position`, `add-collateral`, `withdraw-collateral`, `repay-debt`
- **Validation**: Collateral ratio checks, minimum loan requirements

#### 2. **Interest Rate Engine**

- **Global Accrual**: System-wide interest calculation per block
- **Position Accrual**: Individual position interest updates
- **Compound Interest**: Precise per-block compounding at ~10% APR

#### 3. **Liquidation System**

- **Health Monitoring**: Continuous collateralization ratio tracking
- **Automatic Execution**: Liquidators can execute underwater positions
- **Penalty Structure**: 10% liquidation penalty for risk compensation

#### 4. **Oracle Integration**

- **Price Feed**: BTC/USD price data with timestamp validation
- **Staleness Protection**: 24-hour expiry window for price data
- **Error Handling**: Robust error codes for price failures

### Data Flow

```
User Interaction → Position Validation → Interest Accrual → State Update → Token Operations

┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    User     │    │  Protocol   │    │  Interest   │    │   State     │
│ Transaction │───▶│ Validation  │───▶│  Accrual    │───▶│  Update     │
│             │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                            │                                      │
                            ▼                                      ▼
                   ┌─────────────┐                        ┌─────────────┐
                   │   Oracle    │                        │   Token     │
                   │ Price Check │                        │ Operations  │
                   │             │                        │             │
                   └─────────────┘                        └─────────────┘
```

## 📊 Protocol Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Minimum Collateral Ratio** | 150% | Required over-collateralization |
| **Liquidation Threshold** | 120% | Point at which liquidation occurs |
| **Liquidation Penalty** | 10% | Bonus for liquidators |
| **Minimum Loan** | 100 tokens | Smallest borrowable amount |
| **Interest Rate** | ~10% APR | Compound interest rate |
| **Price Expiry** | 24 hours | Oracle price validity period |

## 🛠️ Key Functions

### User Functions

- `create-position(btc-amount, stable-amount)` - Open new lending position
- `add-collateral(btc-amount)` - Increase position collateral
- `withdraw-collateral(btc-amount)` - Reduce position collateral
- `repay-debt(amount)` - Repay borrowed stablecoins
- `liquidate-position(user)` - Liquidate undercollateralized position

### Administrative Functions

- `set-protocol-owner(new-owner)` - Transfer protocol ownership
- `pause-protocol(paused)` - Emergency pause functionality
- `update-btc-price(price, timestamp)` - Update oracle price feed

### Read-Only Functions

- `get-position(user)` - Retrieve user position data
- `get-collateralization-ratio(user)` - Calculate current ratio
- `get-protocol-stats()` - Global protocol statistics
- `get-current-price()` - Current BTC price with validation

## 🔒 Security Features

### Risk Management

- **Over-Collateralization**: 150% minimum ratio prevents insolvency
- **Liquidation Buffer**: 30% buffer between minimum ratio and liquidation
- **Interest Accrual**: Compound interest prevents debt erosion
- **Price Staleness**: 24-hour expiry prevents stale price attacks

### Access Control

- **Owner Functions**: Administrative functions restricted to protocol owner
- **User Isolation**: Position isolation prevents cross-contamination
- **Emergency Pause**: Protocol-wide pause for security incidents

### Economic Security

- **Liquidation Incentives**: 10% penalty encourages timely liquidations
- **Stability Fees**: Protocol fees for sustainable operations
- **Minimum Loans**: Prevents dust positions and griefing

## 🚦 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u1000` | `ERR-NOT-AUTHORIZED` | Insufficient permissions |
| `u1001` | `ERR-INSUFFICIENT-COLLATERAL` | Below minimum collateral ratio |
| `u1002` | `ERR-POSITION-NOT-FOUND` | User has no active position |
| `u1003` | `ERR-UNDERCOLLATERALIZED` | Position health too low |
| `u1004` | `ERR-MINIMUM-LOAN-REQUIRED` | Loan amount too small |
| `u1005` | `ERR-INSUFFICIENT-DEBT` | Repayment exceeds debt |
| `u1006` | `ERR-PRICE-EXPIRED` | Oracle price too old |
| `u1007` | `ERR-PROTOCOL-PAUSED` | Protocol in emergency pause |
| `u1008` | `ERR-INVALID-AMOUNT` | Invalid input amount |
| `u1009` | `ERR-NO-PRICE-DATA` | No oracle price available |

## 📈 Usage Examples

### Creating a Position

```clarity
;; Deposit 1 BTC (100,000,000 satoshis) to borrow 30,000 stablecoins
(create-position u100000000 u3000000000000)
```

### Adding Collateral

```clarity
;; Add 0.5 BTC to existing position
(add-collateral u50000000)
```

### Repaying Debt

```clarity
;; Repay 10,000 stablecoins
(repay-debt u1000000000000)
```

## 🤝 Contributing

VaultLend is built for the Bitcoin and Stacks ecosystem. We welcome contributions from developers, security researchers, and DeFi enthusiasts.

### Development Setup

1. Install [Clarinet](https://github.com/hirosystems/clarinet)
2. Clone the repository
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet console`

### Security

If you discover a security vulnerability, please report it privately to our security team.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.
