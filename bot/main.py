"""
SwarmArbitrage — Main Bot Entry Point
Multi-agent DEX arbitrage scanner and executor.

Agents:
  1. PriceScanner    — polls DEX prices via JSON-RPC
  2. OpportunityRanker — filters & ranks by net profit
  3. Executor        — submits transactions to chain

Usage:
    python bot/main.py --network arbitrum --dry-run
    python bot/main.py --network ethereum
    python bot/main.py --network base --min-profit 5
"""

import asyncio
import logging
import argparse
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from bot.agents.scanner import PriceScannerAgent
from bot.agents.ranker import OpportunityRankerAgent
from bot.agents.executor import ExecutorAgent
from bot.agents.monitor import MonitorAgent
from bot.config import BotConfig

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)-20s] %(levelname)-8s %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("logs/bot.log"),
    ]
)
log = logging.getLogger("SwarmMain")


async def main(config: BotConfig):
    log.info("═" * 60)
    log.info("  🐝 SwarmArbitrage Bot Starting")
    log.info(f"  Network:     {config.network}")
    log.info(f"  Contract:    {config.contract_address}")
    log.info(f"  Min Profit:  ${config.min_profit_usd}")
    log.info(f"  Dry Run:     {config.dry_run}")
    log.info("═" * 60)

    if not config.contract_address:
        log.error("ARBITRAGE_CONTRACT not set in .env — deploy first!")
        sys.exit(1)

    # Shared queue between agents
    opportunity_queue: asyncio.Queue = asyncio.Queue(maxsize=100)
    execution_queue: asyncio.Queue = asyncio.Queue(maxsize=50)

    # Initialize agents
    scanner  = PriceScannerAgent(config, opportunity_queue)
    ranker   = OpportunityRankerAgent(config, opportunity_queue, execution_queue)
    executor = ExecutorAgent(config, execution_queue)
    monitor  = MonitorAgent(config)

    log.info("🚀 Launching agent swarm...")

    # Run all agents concurrently
    await asyncio.gather(
        scanner.run(),
        ranker.run(),
        executor.run(),
        monitor.run(),
        return_exceptions=False
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SwarmArbitrage Bot")
    parser.add_argument("--network", default="arbitrum",
                        choices=["ethereum", "arbitrum", "base", "polygon",
                                 "sepolia", "arbSepolia", "baseSepolia"],
                        help="Target blockchain network")
    parser.add_argument("--dry-run", action="store_true",
                        help="Simulate without sending transactions")
    parser.add_argument("--min-profit", type=float, default=None,
                        help="Minimum profit in USD to execute")
    parser.add_argument("--max-gas-gwei", type=float, default=None,
                        help="Maximum gas price in Gwei")
    args = parser.parse_args()

    config = BotConfig(
        network=args.network,
        dry_run=args.dry_run,
        min_profit_usd=args.min_profit or float(os.getenv("BOT_MIN_PROFIT_USD", "10")),
        max_gas_gwei=args.max_gas_gwei or float(os.getenv("BOT_MAX_GAS_GWEI", "50")),
    )

    # Create log directory
    Path("logs").mkdir(exist_ok=True)

    try:
        asyncio.run(main(config))
    except KeyboardInterrupt:
        log.info("Bot stopped by user.")
