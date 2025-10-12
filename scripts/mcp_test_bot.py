"""
MCP Test Bot - Simple Price Logger for Testing MCP Integration

This bot is designed for testing Hummingbot API with MCP integration.
It uses paper trading to avoid any real trading risks while demonstrating
the full functionality of bot monitoring and control via API.

Features:
- Paper trading only (no real funds at risk)
- Logs price data from multiple exchanges
- Simple strategy suitable for monitoring via MCP
- No actual trading execution
"""

from hummingbot.strategy.script_strategy_base import ScriptStrategyBase


class MCPTestBot(ScriptStrategyBase):
    """
    A simple bot for testing MCP integration with Hummingbot API.

    This bot monitors prices across multiple paper trading exchanges
    and logs them periodically. It's perfect for:
    - Testing API connectivity
    - Demonstrating bot status monitoring
    - Validating MCP integration
    - Learning the Hummingbot framework
    """

    # Configure testnet exchange for real API testing
    markets = {
        "binance_perpetual_testnet": {"BTC-USDT", "ETH-USDT"},
    }

    def on_tick(self):
        """
        Called every tick (typically once per second).
        Logs current prices from all configured markets.
        """
        for connector_name, connector in self.connectors.items():
            self.logger().info(f"=== {connector_name.upper()} ===")

            for trading_pair in self.markets[connector_name]:
                try:
                    mid_price = connector.get_mid_price(trading_pair)
                    best_bid = connector.get_price(trading_pair, False)
                    best_ask = connector.get_price(trading_pair, True)

                    self.logger().info(
                        f"{trading_pair}: "
                        f"Bid: ${best_bid:.2f} | "
                        f"Mid: ${mid_price:.2f} | "
                        f"Ask: ${best_ask:.2f}"
                    )
                except Exception as e:
                    self.logger().error(f"Error fetching {trading_pair} from {connector_name}: {e}")

    def on_stop(self):
        """
        Called when the bot is stopped.
        """
        self.logger().info("MCP Test Bot stopped successfully")
