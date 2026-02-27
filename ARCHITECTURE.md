# SwarmArbitrage — Architecture

## Overview
Multi-agent on-chain arbitrage system targeting DEX price discrepancies across Ethereum & L2s.

## Components
1. **Smart Contracts** (Solidity / Hardhat)
   - `FlashArbitrage.sol` — Core flash-loan arbitrage executor
   - `SwarmCoordinator.sol` — On-chain registry/coordinator for swarm agents
2. **Off-chain Bot (Python)**
   - Agent scanner — Monitors mempool + DEX prices via WebSocket
   - Opportunity ranker — Scores opportunities by net profit after gas
   - Executor — Submits transactions via eth_sendRawTransaction
3. **Dashboard (React/Next.js)**
   - Live P&L tracker
   - Active agent monitor
   - Gas analytics

## Supported Networks (mainnet + testnets)
- Ethereum Mainnet / Sepolia testnet
- Arbitrum One / Arbitrum Sepolia
- Base / Base Sepolia
- Polygon PoS

## DEXs Targeted
- Uniswap V2 / V3
- SushiSwap
- Balancer V2
- Curve Finance

## Flash Loan Providers
- Aave V3 (primary)
- Balancer (zero-fee flash loans)

## Arbitrage Strategies
1. Two-hop: buy on DEX A, sell on DEX B
2. Triangular: A→B→C→A cyclic
3. Cross-protocol: Curve stable pools ↔ Uniswap V3

## Key Design Decisions
- All arbitrage executes atomically in a single transaction
- No capital required (flash loans supply all funds)
- Gas-aware: profitable threshold = minProfit > gasEstimate * 1.5
- Slippage protection via minOut parameters on every swap
