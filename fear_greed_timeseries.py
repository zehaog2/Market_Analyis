import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import argparse
import json
from pathlib import Path
import warnings
from market_mapping import SECTOR_ETF_MAP, INDUSTRY_PEERS
warnings.filterwarnings('ignore')

class FearGreedTimeSeries:
    def __init__(self, period_days=180):
        self.period_days = period_days
        self.end_date = datetime.now()
        self.start_date = self.end_date - timedelta(days=period_days)
        self.sector_etfs = SECTOR_ETF_MAP
        self.industry_stocks = INDUSTRY_PEERS
        
        # Create output directory
        self.output_dir = Path('fear_greed_charts')
        self.output_dir.mkdir(exist_ok=True)
    
    def calculate_daily_fear_greed(self, ticker, date):
        """Calculate fear/greed score for a specific date"""
        try:
            stock = yf.Ticker(ticker)
            
            # Get 30 days of data before the target date for calculations
            hist_start = date - timedelta(days=30)
            hist = stock.history(start=hist_start, end=date)
            
            if len(hist) < 20:
                return 50  # Neutral if not enough data
            
            # Get the last 20 days for calculations
            hist = hist.tail(20)
            
            # Price momentum (40% weight)
            returns = hist['Close'].pct_change()
            avg_return = returns.mean()
            price_score = self._normalize_score(avg_return * 20, -1, 1) * 100
            
            # RSI (30% weight)
            rsi = self._calculate_rsi(hist['Close'])
            
            # Volume analysis (20% weight)
            avg_volume = hist['Volume'].mean()
            recent_volume = hist['Volume'].iloc[-5:].mean()
            volume_ratio = recent_volume / avg_volume if avg_volume > 0 else 1
            volume_score = self._normalize_score(volume_ratio - 1, -0.5, 0.5) * 100
            
            # Volatility (10% weight) - inverse
            volatility = returns.std()
            volatility_score = 100 - self._normalize_score(volatility, 0.01, 0.05) * 100
            
            # Weighted score
            fear_greed = (
                price_score * 0.40 +
                rsi * 0.30 +
                volume_score * 0.20 +
                volatility_score * 0.10
            )
            
            return max(0, min(100, fear_greed))
            
        except Exception as e:
            return 50  # Return neutral on error
    
    def _calculate_rsi(self, prices, period=14):
        """Calculate RSI"""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        
        if loss.iloc[-1] == 0:
            return 100 if gain.iloc[-1] > 0 else 50
            
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi.iloc[-1] if not pd.isna(rsi.iloc[-1]) else 50
    
    def _normalize_score(self, value, min_val, max_val):
        """Normalize value to 0-1 scale"""
        if value <= min_val:
            return 0
        elif value >= max_val:
            return 1
        else:
            return (value - min_val) / (max_val - min_val)
    
    def get_historical_fear_greed(self, ticker):
        """Get historical fear/greed scores for a ticker"""
        dates = pd.date_range(start=self.start_date, end=self.end_date, freq='D')
        scores = []
        
        # Calculate scores for each day
        for date in dates:
            score = self.calculate_daily_fear_greed(ticker, date)
            scores.append(score)
        
        return pd.Series(scores, index=dates)

if __name__ == "__main__":
    main()