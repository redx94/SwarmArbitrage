import os
from dataclasses import dataclass, field
from typing import Dict, List
from dotenv import load_dotenv

load_dotenv()

@dataclass
class BotConfig:
    network: str = os.getenv("BOT_NETWORK", "arbitrum")
    rpc_url: str = ""
    private_key: str = os.getenv("PRIVATE_KEY", "")
    contract_address: str = ""
    
    # Capital Strategy
    min_trade_size_usd: float = float(os.getenv("MIN_TRADE_SIZE_USD", "1000000")) # $1M Target
    min_profit_usd: float = float(os.getenv("MIN_PROFIT_USD", "100"))
    max_gas_gwei: float = float(os.getenv("MAX_GAS_GWEI", "50"))
    
    # Swarm Settings
    max_concurrent_agents: int = int(os.getenv("MAX_CONCURRENT_AGENTS", "20"))
    scan_interval_ms: int = int(os.getenv("SCAN_INTERVAL_MS", "500"))
    
    # Network Mapping
    networks: Dict[str, Dict] = field(default_factory=lambda: {
        "arbitrum": {
            "chain_id": 42161,
            "rpc_env": "ARBITRUM_RPC_URL",
            "contract_env": "ARBITRAGE_CONTRACT_ARB"
        },
        "base": {
            "chain_id": 8453,
            "rpc_env": "BASE_RPC_URL",
            "contract_env": "ARBITRAGE_CONTRACT_BASE"
        },
        "ethereum": {
            "chain_id": 1,
            "rpc_env": "ETHEREUM_RPC_URL",
            "contract_env": "ARBITRAGE_CONTRACT_ETH"
        },
        "polygon": {
            "chain_id": 137,
            "rpc_env": "POLYGON_RPC_URL",
            "contract_env": "ARBITRAGE_CONTRACT_POLYGON"
        }
    })

    def __post_init__(self):
        net_info = self.networks.get(self.network)
        if net_info:
            self.rpc_url = os.getenv(net_info["rpc_env"], "")
            self.contract_address = os.getenv(net_info["contract_env"], "")
