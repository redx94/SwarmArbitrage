"""
SwarmArbitrage — Main Bot Entry Point
Parallel Multi-Agent Swarm Architect.

Structure:
1. PriceScanner    — Monitors DEXs for signals.
2. WorkerAgent     — (Dynamic) Spawned per-signal to handle $1M+ capital trades.
3. MonitorAgent    — Tracks P&L and health.
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

from bot.config import BotConfig
from bot.agents.scanner import PriceScannerAgent
from bot.agents.monitor import MonitorAgent

load_dotenv()

# Rich logging format
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)-15s] %(levelname)-8s %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("logs/bot.log"),
    ]
)
log = logging.getLogger("SwarmMain")


async def main(config: BotConfig):
    log.info("═" * 60)
    log.info("  🐝 SwarmArbitrage — Swarm Mode Active")
    log.info(f"  Network:      {config.network}")
    log.info(f"  Target Capital: ${config.min_trade_size_usd:,.2f} per trade")
    log.info(f"  Base Profit Threshold: ${config.min_profit_usd:,.2f}")
    log.info("═" * 60)

    if not config.contract_address:
        log.warning("⚠️  Contract address not found for this network. Run in Mock/Simulation mode.")

    # Shared telemetry / metadata could go here
    
    # Initialize Persistent Agents
    scanner  = PriceScannerAgent(config)
    monitor  = MonitorAgent(config)

    log.info("🚀 Launching swarm controllers...")

    # Run persistent controllers
    # Note: Workers are spawned dynamically by the Scanner
    await asyncio.gather(
        scanner.run(),
        monitor.run(),
        return_exceptions=False
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SwarmArbitrage Bot")
    parser.add_argument("--network", default="arbitrum",
                        choices=["ethereum", "arbitrum", "base", "polygon"],
                        help="Target blockchain network")
    parser.add_argument("--size", type=float, 
                        help="Minimum trade size in USD (e.g. 1000000)")
    
    args = parser.parse_args()

    # Load configuration
    config = BotConfig(
        network=args.network,
        min_trade_size_usd=args.size or float(os.getenv("MIN_TRADE_SIZE_USD", "1000000"))
    )

    # Create log directory
    Path("logs").mkdir(exist_ok=True)

    try:
        asyncio.run(main(config))
    except KeyboardInterrupt:
        log.info("Bot stopped by user.")
    except Exception as e:
        log.critical(f"Critical failure: {e}")
