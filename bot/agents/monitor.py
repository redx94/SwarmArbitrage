import logging
import asyncio

log = logging.getLogger("Monitor")

class MonitorAgent:
    def __init__(self, config):
        self.config = config

    async def run(self):
        log.info("📊 Performance Monitor active.")
        while True:
            # Here we would track successful trades vs failed ones
            await asyncio.sleep(60)
