#!/usr/bin/env python3
"""
Fear & Greed Time Series Analysis
Creates individual time series charts for each sector and industry
"""

import yfinance as yf
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import argparse
import json
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

class FearGreedTimeSeries:
    """Generate time series fear/greed charts for sectors and industries"""
    
    def __init__(self, period_days=180):
        self.period_days = period_days
        self.end_date = datetime.now()
        self.start_date = self.end_date - timedelta(days=period_days)
        
        # Sector ETFs
        self.sector_etfs = {
            'Technology': 'XLK',
            'Financials': 'XLF',
            'Healthcare': 'XLV',
            'Consumer Discretionary': 'XLY',
            'Industrials': 'XLI',
            'Consumer Staples': 'XLP',
            'Energy': 'XLE',
            'Utilities': 'XLU',
            'Real Estate': 'XLRE',
            'Materials': 'XLB',
            'Communications': 'XLC'
        }
        
        # Industry representatives
        self.industry_stocks = {
            # Technology
            'Semiconductors': ['NVDA', 'AMD', 'INTC', 'MU', 'QCOM'],
            'Software': ['MSFT', 'CRM', 'ADBE', 'NOW', 'ORCL'],
            'Internet': ['GOOGL', 'META', 'AMZN', 'NFLX', 'UBER'],
            'Hardware': ['AAPL', 'DELL', 'HPQ', 'CSCO', 'IBM'],
            'Cloud Computing': ['AMZN', 'MSFT', 'GOOGL', 'CRM', 'NOW'],
            'Cybersecurity': ['CRWD', 'PANW', 'ZS', 'OKTA', 'S'],
            
            # Financials
            'Banks': ['JPM', 'BAC', 'WFC', 'C', 'GS'],
            'Insurance': ['BRK.B', 'UNH', 'AIG', 'MET', 'PRU'],
            'Asset Management': ['BLK', 'MS', 'SCHW', 'CME', 'ICE'],
            'Fintech': ['V', 'MA', 'PYPL', 'SQ', 'COIN'],
            
            # Healthcare
            'Pharma': ['JNJ', 'PFE', 'MRK', 'ABBV', 'LLY'],
            'Biotech': ['AMGN', 'GILD', 'BIIB', 'VRTX', 'REGN'],
            'Medical Devices': ['ABT', 'MDT', 'TMO', 'DHR', 'SYK'],
            'Healthcare Services': ['UNH', 'CVS', 'HUM', 'CI', 'ELV'],
            
            # Consumer
            'Retail': ['WMT', 'AMZN', 'HD', 'COST', 'TGT'],
            'E-commerce': ['AMZN', 'SHOP', 'EBAY', 'ETSY', 'W'],
            'Auto': ['TSLA', 'F', 'GM', 'RIVN', 'NIO'],
            'Restaurants': ['MCD', 'SBUX', 'CMG', 'YUM', 'DPZ'],
            'Apparel': ['NKE', 'LULU', 'GPS', 'ROST', 'TJX'],
            
            # Industrials
            'Aerospace': ['BA', 'LMT', 'RTX', 'NOC', 'GD'],
            'Transport': ['UPS', 'FDX', 'UNP', 'CSX', 'DAL'],
            'Machinery': ['CAT', 'DE', 'MMM', 'HON', 'EMR'],
            'Defense': ['LMT', 'RTX', 'NOC', 'GD', 'LHX'],
            
            # Energy
            'Oil & Gas': ['XOM', 'CVX', 'COP', 'SLB', 'OXY'],
            'Renewable': ['NEE', 'ENPH', 'SEDG', 'RUN', 'PLUG'],
            'Energy Services': ['SLB', 'HAL', 'BKR', 'FTI', 'NOV']
        }
        
        # Create output directory
        self.output_dir = Path('fear_greed_charts')
        self.output_dir.mkdir(exist_ok=True)
    
    def calculate_daily_fear_greed(self, ticker, date):
        """Calculate fear/greed score for a specific date"""
        try:
            stock = yf.Ticker(ticker)
            
            # Get 30 days of data before the target date for calculations
            hist_end = date
            hist_start = date - timedelta(days=30)
            hist = stock.history(start=hist_start, end=hist_end)
            
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
    
    def create_sector_chart(self, sector, etf):
        """Create time series chart for a sector"""
        print(f"📊 Generating chart for {sector} sector...")
        
        # Get historical data
        fear_greed_series = self.get_historical_fear_greed(etf)
        
        # Create figure with dark background
        fig, ax = plt.subplots(figsize=(14, 8), facecolor='#1a1a1a')
        ax.set_facecolor('#0f0f0f')
        
        # Prepare data
        dates = fear_greed_series.index
        scores = fear_greed_series.values
        
        # Calculate values relative to neutral (50)
        relative_scores = scores - 50
        
        # Create colors based on intensity with better visibility
        colors = []
        for score in relative_scores:
            if score >= 0:  # Greed (above 50)
                # Green intensity: ensure minimum visibility
                intensity = abs(score) / 50  # 0 to 1
                # Map to color range: minimum 40% brightness to 100%
                brightness = 0.4 + (0.6 * intensity)
                green_val = int(255 * brightness)
                red_val = int(50 * (1 - intensity))  # Slight red tint for lighter greens
                colors.append(f'#{red_val:02x}{green_val:02x}00')
            else:  # Fear (below 50)
                # Red intensity: ensure minimum visibility
                intensity = abs(score) / 50  # 0 to 1
                # Map to color range: minimum 40% brightness to 100%
                brightness = 0.4 + (0.6 * intensity)
                red_val = int(255 * brightness)
                green_val = int(50 * (1 - intensity))  # Slight green tint for lighter reds
                colors.append(f'#{red_val:02x}{green_val:02x}00')
        
        # Create bar chart centered at 50
        bars = ax.bar(dates, relative_scores, color=colors, width=1.0, 
                      bottom=50, alpha=0.95, edgecolor='none')
        
        # Add neutral line at 50
        ax.axhline(y=50, color='white', linestyle='-', linewidth=2, label='Neutral (50)', alpha=0.9)
        
        # Add reference lines
        ax.axhline(y=80, color='#00ff00', linestyle='--', alpha=0.6, label='Extreme Greed (80)')
        ax.axhline(y=20, color='#ff0000', linestyle='--', alpha=0.6, label='Extreme Fear (20)')
        
        # Add subtle grid lines
        ax.axhline(y=70, color='gray', linestyle=':', alpha=0.2)
        ax.axhline(y=60, color='gray', linestyle=':', alpha=0.2)
        ax.axhline(y=40, color='gray', linestyle=':', alpha=0.2)
        ax.axhline(y=30, color='gray', linestyle=':', alpha=0.2)
        
        # Customize chart
        ax.set_ylim(0, 100)
        ax.set_xlabel('Date', fontsize=12, color='white')
        ax.set_ylabel('Fear & Greed Score', fontsize=12, color='white')
        ax.set_title(f'{sector} Sector - Fear & Greed Index ({self.period_days} Days)', 
                     fontsize=16, fontweight='bold', pad=20, color='white')
        
        # Format x-axis
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d'))
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=30))
        ax.xaxis.set_minor_locator(mdates.DayLocator(interval=7))
        plt.xticks(rotation=45, color='white')
        plt.yticks(color='white')
        
        # Add grid
        ax.grid(True, alpha=0.1, linestyle=':', axis='x', color='gray')
        ax.set_axisbelow(True)
        
        # Style spines
        ax.spines['bottom'].set_color('white')
        ax.spines['left'].set_color('white')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        # Add legend with dark background
        legend = ax.legend(loc='upper left', fontsize=10, facecolor='#1a1a1a', 
                          edgecolor='gray', framealpha=0.9)
        for text in legend.get_texts():
            text.set_color('white')
        
        # Add current score annotation with color
        current_score = scores[-1]
        current_color = '#00ff00' if current_score > 50 else '#ff0000'
        sentiment_text = 'GREED' if current_score > 50 else 'FEAR'
        
        ax.text(0.02, 0.98, f'Current: {current_score:.1f} ({sentiment_text})', 
                transform=ax.transAxes, fontsize=14, fontweight='bold',
                verticalalignment='top', color=current_color,
                bbox=dict(boxstyle='round', facecolor='#1a1a1a', 
                         edgecolor=current_color, alpha=0.9))
        
        # Add background shading for fear/greed zones
        ax.axhspan(0, 20, alpha=0.1, color='red', zorder=0)
        ax.axhspan(80, 100, alpha=0.1, color='green', zorder=0)
        
        plt.tight_layout()
        
        # Save chart
        filename = self.output_dir / f'sector_{sector.replace(" ", "_").lower()}_fear_greed.png'
        plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        
        print(f"  ✅ Saved: {filename}")
        return filename
    
    def create_industry_chart(self, industry, stocks):
        """Create time series chart for an industry"""
        print(f"📊 Generating chart for {industry} industry...")
        
        # Calculate average fear/greed across industry stocks
        all_series = []
        for stock in stocks[:3]:  # Use top 3 stocks for speed
            series = self.get_historical_fear_greed(stock)
            all_series.append(series)
        
        # Average the scores
        fear_greed_series = pd.concat(all_series, axis=1).mean(axis=1)
        
        # Create figure with dark background
        fig, ax = plt.subplots(figsize=(14, 8), facecolor='#1a1a1a')
        ax.set_facecolor('#0f0f0f')
        
        # Prepare data
        dates = fear_greed_series.index
        scores = fear_greed_series.values
        
        # Calculate values relative to neutral (50)
        relative_scores = scores - 50
        
        # Create colors based on intensity with better visibility
        colors = []
        for score in relative_scores:
            if score >= 0:  # Greed (above 50)
                # Green intensity: ensure minimum visibility
                intensity = abs(score) / 50  # 0 to 1
                # Map to color range: minimum 40% brightness to 100%
                brightness = 0.4 + (0.6 * intensity)
                green_val = int(255 * brightness)
                red_val = int(50 * (1 - intensity))  # Slight red tint for lighter greens
                colors.append(f'#{red_val:02x}{green_val:02x}00')
            else:  # Fear (below 50)
                # Red intensity: ensure minimum visibility
                intensity = abs(score) / 50  # 0 to 1
                # Map to color range: minimum 40% brightness to 100%
                brightness = 0.4 + (0.6 * intensity)
                red_val = int(255 * brightness)
                green_val = int(50 * (1 - intensity))  # Slight green tint for lighter reds
                colors.append(f'#{red_val:02x}{green_val:02x}00')
        
        # Create bar chart centered at 50
        bars = ax.bar(dates, relative_scores, color=colors, width=1.0, 
                      bottom=50, alpha=0.95, edgecolor='none')
        
        # Add neutral line at 50
        ax.axhline(y=50, color='white', linestyle='-', linewidth=2, label='Neutral (50)', alpha=0.9)
        
        # Add reference lines
        ax.axhline(y=80, color='#00ff00', linestyle='--', alpha=0.6, label='Extreme Greed (80)')
        ax.axhline(y=20, color='#ff0000', linestyle='--', alpha=0.6, label='Extreme Fear (20)')
        
        # Add subtle grid lines
        ax.axhline(y=70, color='gray', linestyle=':', alpha=0.2)
        ax.axhline(y=60, color='gray', linestyle=':', alpha=0.2)
        ax.axhline(y=40, color='gray', linestyle=':', alpha=0.2)
        ax.axhline(y=30, color='gray', linestyle=':', alpha=0.2)
        
        # Customize chart
        ax.set_ylim(0, 100)
        ax.set_xlabel('Date', fontsize=12, color='white')
        ax.set_ylabel('Fear & Greed Score', fontsize=12, color='white')
        ax.set_title(f'{industry} Industry - Fear & Greed Index ({self.period_days} Days)', 
                     fontsize=16, fontweight='bold', pad=20, color='white')
        
        # Add subtitle with stocks used
        ax.text(0.5, 0.97, f'Based on: {", ".join(stocks[:3])}', 
                transform=ax.transAxes, fontsize=10, alpha=0.7, color='gray',
                horizontalalignment='center', verticalalignment='top')
        
        # Format x-axis
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d'))
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=30))
        ax.xaxis.set_minor_locator(mdates.DayLocator(interval=7))
        plt.xticks(rotation=45, color='white')
        plt.yticks(color='white')
        
        # Add grid
        ax.grid(True, alpha=0.1, linestyle=':', axis='x', color='gray')
        ax.set_axisbelow(True)
        
        # Style spines
        ax.spines['bottom'].set_color('white')
        ax.spines['left'].set_color('white')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        # Add legend with dark background
        legend = ax.legend(loc='upper left', fontsize=10, facecolor='#1a1a1a', 
                          edgecolor='gray', framealpha=0.9)
        for text in legend.get_texts():
            text.set_color('white')
        
        # Add current score annotation with color
        current_score = scores[-1]
        current_color = '#00ff00' if current_score > 50 else '#ff0000'
        sentiment_text = 'GREED' if current_score > 50 else 'FEAR'
        
        ax.text(0.02, 0.92, f'Current: {current_score:.1f} ({sentiment_text})', 
                transform=ax.transAxes, fontsize=14, fontweight='bold',
                verticalalignment='top', color=current_color,
                bbox=dict(boxstyle='round', facecolor='#1a1a1a', 
                         edgecolor=current_color, alpha=0.9))
        
        # Add background shading for fear/greed zones
        ax.axhspan(0, 20, alpha=0.1, color='red', zorder=0)
        ax.axhspan(80, 100, alpha=0.1, color='green', zorder=0)
        
        plt.tight_layout()
        
        # Save chart
        filename = self.output_dir / f'industry_{industry.replace(" ", "_").lower()}_fear_greed.png'
        plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        
        print(f"  ✅ Saved: {filename}")
        return filename
    
    def generate_all_charts(self):
        """Generate all sector and industry charts"""
        print(f"\n🚀 Starting Fear & Greed Time Series Analysis")
        print(f"📅 Period: {self.start_date.strftime('%Y-%m-%d')} to {self.end_date.strftime('%Y-%m-%d')}")
        print(f"📁 Output directory: {self.output_dir}")
        print("="*60)
        
        # Generate sector charts
        print("\n📈 GENERATING SECTOR CHARTS")
        print("-"*40)
        sector_files = {}
        for sector, etf in self.sector_etfs.items():
            try:
                filename = self.create_sector_chart(sector, etf)
                sector_files[sector] = filename
            except Exception as e:
                print(f"  ❌ Error generating {sector}: {e}")
        
        # Generate industry charts
        print("\n📈 GENERATING INDUSTRY CHARTS")
        print("-"*40)
        industry_files = {}
        for industry, stocks in self.industry_stocks.items():
            try:
                filename = self.create_industry_chart(industry, stocks)
                industry_files[industry] = filename
            except Exception as e:
                print(f"  ❌ Error generating {industry}: {e}")
        
        # Save summary
        summary = {
            'generated_at': datetime.now().isoformat(),
            'period_days': self.period_days,
            'start_date': self.start_date.strftime('%Y-%m-%d'),
            'end_date': self.end_date.strftime('%Y-%m-%d'),
            'sectors': {k: str(v) for k, v in sector_files.items()},
            'industries': {k: str(v) for k, v in industry_files.items()}
        }
        
        with open(self.output_dir / 'analysis_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"\n✅ Analysis Complete!")
        print(f"📊 Generated {len(sector_files)} sector charts")
        print(f"📊 Generated {len(industry_files)} industry charts")
        print(f"📁 All charts saved in: {self.output_dir}/")
        
        return summary
    
    def generate_index_html(self):
        """Generate HTML index for all charts"""
        html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fear & Greed Time Series Analysis</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #0f0f0f;
            color: #ffffff;
        }
        h1, h2 {
            color: #ffffff;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .chart-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(600px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        .chart-item {
            background: #1a1a1a;
            padding: 10px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.3);
            border: 1px solid #333;
        }
        .chart-item img {
            width: 100%;
            height: auto;
            border-radius: 4px;
        }
        .timestamp {
            color: #888;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Fear & Greed Time Series Analysis</h1>
        <p class="timestamp">Generated: {timestamp}</p>
        
        <h2>Sector Charts</h2>
        <div class="chart-grid">
            {sector_charts}
        </div>
        
        <h2>Industry Charts</h2>
        <div class="chart-grid">
            {industry_charts}
        </div>
    </div>
</body>
</html>
        """
        
        # Generate chart HTML
        sector_html = ""
        for sector in self.sector_etfs.keys():
            filename = f"sector_{sector.replace(' ', '_').lower()}_fear_greed.png"
            sector_html += f"""
            <div class="chart-item">
                <img src="{filename}" alt="{sector} Fear & Greed">
            </div>
            """
        
        industry_html = ""
        for industry in self.industry_stocks.keys():
            filename = f"industry_{industry.replace(' ', '_').lower()}_fear_greed.png"
            industry_html += f"""
            <div class="chart-item">
                <img src="{filename}" alt="{industry} Fear & Greed">
            </div>
            """
        
        # Fill template
        html = html_content.format(
            timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            sector_charts=sector_html,
            industry_charts=industry_html
        )
        
        # Save HTML
        with open(self.output_dir / 'index.html', 'w') as f:
            f.write(html)
        
        print(f"📄 HTML index generated: {self.output_dir}/index.html")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Fear & Greed Time Series Analysis')
    parser.add_argument('--days', type=int, default=180,
                       help='Number of days to analyze (default: 180)')
    parser.add_argument('--sectors-only', action='store_true',
                       help='Generate only sector charts')
    parser.add_argument('--industries-only', action='store_true',
                       help='Generate only industry charts')
    
    args = parser.parse_args()
    
    # Initialize analyzer
    analyzer = FearGreedTimeSeries(period_days=args.days)
    
    # Generate charts based on arguments
    if args.sectors_only:
        print("Generating sector charts only...")
        for sector, etf in analyzer.sector_etfs.items():
            analyzer.create_sector_chart(sector, etf)
    elif args.industries_only:
        print("Generating industry charts only...")
        for industry, stocks in analyzer.industry_stocks.items():
            analyzer.create_industry_chart(industry, stocks)
    else:
        # Generate all charts
        analyzer.generate_all_charts()
        analyzer.generate_index_html()


if __name__ == "__main__":
    main()