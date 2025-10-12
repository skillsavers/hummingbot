"""
Simple Price Monitor Bot
Author: Hummingbot MCP Demo
Version: 1.0.0

Description:
A minimal example bot that monitors price movements and logs alerts when
price changes exceed a threshold. Perfect for learning Hummingbot basics.

Features:
- Monitors BTC-USDT and ETH-USDT prices
- Logs price changes every 60 seconds
- Alerts when price moves more than configured threshold
- No trading - read-only monitoring

This bot demonstrates:
- How to access market data
- How to implement periodic tasks
- How to work with the Hummingbot framework
"""

from decimal import Decimal
from typing import Dict
from hummingbot.strategy.script_strategy_base import ScriptStrategyBase


class SimplePriceMonitor(ScriptStrategyBase):
    """
    A simple bot that monitors cryptocurrency prices and alerts on significant moves.
    """

    # Configuration
    markets = {"binance_perpetual_testnet": {"BTC-USDT", "ETH-USDT"}}

    # Monitor settings
    update_interval = 60  # Check prices every 60 seconds
    price_change_threshold = Decimal("1.0")  # Alert on 1% price change

    def __init__(self, connectors: Dict):
        super().__init__(connectors)
        self.last_prices: Dict[str, Decimal] = {}

    def on_tick(self):
        """
        Called every tick (every second by default).
        We only execute our logic every update_interval seconds.
        """
        if self.current_timestamp % self.update_interval != 0:
            return

        self.monitor_prices()

    def monitor_prices(self):
        """
        Check current prices and log significant changes.
        """
        connector_name = "binance_perpetual_testnet"
        connector = self.connectors[connector_name]

        self.logger().info("=" * 60)
        self.logger().info("📊 Price Monitor Update")
        self.logger().info("=" * 60)

        for trading_pair in self.markets[connector_name]:
            try:
                # Get current mid price
                mid_price = connector.get_mid_price(trading_pair)

                if mid_price:
                    self.logger().info(f"{trading_pair}: ${mid_price:,.2f}")

                    # Check for significant price changes
                    if trading_pair in self.last_prices:
                        last_price = self.last_prices[trading_pair]
                        price_change_pct = ((mid_price - last_price) / last_price) * Decimal("100")

                        if abs(price_change_pct) >= self.price_change_threshold:
                            direction = "🔺 UP" if price_change_pct > 0 else "🔻 DOWN"
                            self.logger().info(
                                f"  {direction} {abs(price_change_pct):.2f}% "
                                f"(${last_price:,.2f} → ${mid_price:,.2f})"
                            )

                    # Update last price
                    self.last_prices[trading_pair] = mid_price
                else:
                    self.logger().warning(f"{trading_pair}: Price not available")

            except Exception as e:
                self.logger().error(f"Error monitoring {trading_pair}: {e}")

        self.logger().info("=" * 60)

    def on_stop(self):
        """
        Called when the bot is stopped.
        """
        self.logger().info("Price Monitor stopped. Final prices:")
        for trading_pair, price in self.last_prices.items():
            self.logger().info(f"  {trading_pair}: ${price:,.2f}")
