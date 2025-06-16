import yfinance as yf
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.patches import Rectangle
from datetime import datetime, timedelta
import argparse
import json
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')
from scipy.signal import find_peaks
from collections import Counter

from fear_greed_timeseries import FearGreedTimeSeries
from market_mapping import SECTOR_ETF_MAP, INDUSTRY_PEERS


class FearGreedEnhanced(FearGreedTimeSeries):
    """Enhanced visualization focusing on trends and inflection points"""
    
    def __init__(self, period_days=180):
        super().__init__(period_days)
        self.smoothing_window = 10  # 10-day smoothing
        self.support_resistance_tolerance = 2  # ±2 points for level detection
        self.min_touches = 3  # Minimum touches for support/resistance
        
        # Ensure we have sector and industry data
        if not hasattr(self, 'sector_etfs'):
            self.sector_etfs = SECTOR_ETF_MAP
        if not hasattr(self, 'industry_stocks'):
            self.industry_stocks = INDUSTRY_PEERS
        
        # Override output directory
        self.output_dir = Path('fear_greed_enhanced')
        self.output_dir.mkdir(exist_ok=True)
    
    def find_support_resistance_levels(self, scores, tolerance=2):
        """Find support and resistance levels with 3+ touches"""
        levels = []
        level_counts = Counter()
        
        # Round scores to nearest integer for grouping
        rounded_scores = np.round(scores)
        
        # Find peaks (resistance) and troughs (support)
        peaks, _ = find_peaks(scores, distance=5)
        troughs, _ = find_peaks(-scores, distance=5)
        
        # Count touches at each level
        for idx in peaks:
            level = rounded_scores[idx]
            for l in range(int(level - tolerance), int(level + tolerance + 1)):
                level_counts[l] += 1
        
        for idx in troughs:
            level = rounded_scores[idx]
            for l in range(int(level - tolerance), int(level + tolerance + 1)):
                level_counts[l] += 1
        
        # Find levels with minimum touches
        for level, count in level_counts.items():
            if count >= self.min_touches:
                levels.append({
                    'level': level,
                    'count': count,
                    'type': 'resistance' if level > 50 else 'support'
                })
        
        return sorted(levels, key=lambda x: x['level'])
    
    def calculate_trend_strength(self, smoothed_series):
        """Calculate trend strength based on slope changes"""
        # Calculate daily changes
        changes = smoothed_series.diff()
        
        # Calculate rolling slope (rate of change)
        window = 5
        slopes = changes.rolling(window=window).mean()
        
        return slopes
    
    def find_inflection_points(self, smoothed_series):
        """Find significant inflection points in the smoothed series"""
        inflections = []
        slopes = self.calculate_trend_strength(smoothed_series)
        
        # Find where slope changes sign
        sign_changes = np.diff(np.sign(slopes.fillna(0)))
        
        for i in range(1, len(sign_changes)):
            if abs(sign_changes[i]) > 0:  # Sign change detected
                date = smoothed_series.index[i]
                value = smoothed_series.iloc[i]
                prev_slope = slopes.iloc[i-1] if i > 0 else 0
                next_slope = slopes.iloc[i+1] if i < len(slopes)-1 else 0
                
                # Classify inflection type
                if prev_slope < 0 and next_slope > 0:
                    inflection_type = 'bottom'  # Fear to greed transition
                elif prev_slope > 0 and next_slope < 0:
                    inflection_type = 'top'  # Greed to fear transition
                else:
                    inflection_type = 'neutral'
                
                inflections.append({
                    'date': date,
                    'value': value,
                    'type': inflection_type,
                    'strength': abs(next_slope - prev_slope)
                })
        
        return inflections
    
    def find_consolidation_zones(self, smoothed_series, threshold=5):
        """Find periods where sentiment stays in tight range"""
        zones = []
        window = 10
        
        # Calculate rolling range
        rolling_max = smoothed_series.rolling(window=window).max()
        rolling_min = smoothed_series.rolling(window=window).min()
        rolling_range = rolling_max - rolling_min
        
        # Find periods with small range
        in_consolidation = rolling_range < threshold
        
        # Group consecutive consolidation periods
        start_idx = None
        for i in range(len(in_consolidation)):
            if in_consolidation.iloc[i] and start_idx is None:
                start_idx = i
            elif not in_consolidation.iloc[i] and start_idx is not None:
                if i - start_idx >= 5:  # Minimum 5 days
                    zones.append({
                        'start': smoothed_series.index[start_idx],
                        'end': smoothed_series.index[i-1],
                        'level': smoothed_series.iloc[start_idx:i].mean()
                    })
                start_idx = None
        
        return zones
    
    def create_enhanced_chart(self, title, fear_greed_series, filename):
        """Create enhanced chart with trend focus"""
        # Create figure with dark background
        fig, ax = plt.subplots(figsize=(16, 10), facecolor='#1a1a1a')
        ax.set_facecolor('#0f0f0f')
        
        # Prepare data
        dates = fear_greed_series.index
        scores = fear_greed_series.values
        
        # Calculate smoothed trend line
        smoothed = pd.Series(scores, index=dates).rolling(
            window=self.smoothing_window, center=True).mean()
        
        # Fill NaN values at edges
        smoothed = smoothed.bfill().ffill()
        
        # Calculate trend strength for coloring
        slopes = self.calculate_trend_strength(smoothed)
        
        # 1. Plot faded daily bars
        relative_scores = scores - 50
        colors = []
        for score in relative_scores:
            if score >= 0:
                intensity = abs(score) / 50
                brightness = 0.4 + (0.6 * intensity)
                green_val = int(255 * brightness)
                red_val = int(50 * (1 - intensity))
                colors.append(f'#{red_val:02x}{green_val:02x}00')
            else:
                intensity = abs(score) / 50
                brightness = 0.4 + (0.6 * intensity)
                red_val = int(255 * brightness)
                green_val = int(50 * (1 - intensity))
                colors.append(f'#{red_val:02x}{green_val:02x}00')
        
        # Faded bars (30% opacity)
        bars = ax.bar(dates, relative_scores, color=colors, width=1.0, 
                      bottom=50, alpha=0.3, edgecolor='none', zorder=1)
        
        # 2. Find and plot support/resistance levels
        levels = self.find_support_resistance_levels(scores)
        for level_info in levels:
            level = level_info['level']
            count = level_info['count']
            level_type = level_info['type']
            
            # Line thickness based on touch count
            linewidth = min(0.5 + (count - 3) * 0.3, 2.5)
            
            # Color based on type
            if level_type == 'resistance':
                color = '#00ff00'
                linestyle = '--'
            else:
                color = '#ff0000'
                linestyle = '--'
            
            ax.axhline(y=level, color=color, linestyle=linestyle, 
                      linewidth=linewidth, alpha=0.4, zorder=2)
            
            # Add touch count label
            ax.text(dates[-1], level, f' {count}', fontsize=8, 
                   color=color, alpha=0.7, ha='left', va='center')
        
        # 3. Find consolidation zones
        consolidation_zones = self.find_consolidation_zones(smoothed)
        for zone in consolidation_zones:
            rect = Rectangle((mdates.date2num(zone['start']), zone['level'] - 2.5),
                           mdates.date2num(zone['end']) - mdates.date2num(zone['start']),
                           5, facecolor='gray', alpha=0.2, zorder=1)
            ax.add_patch(rect)
        
        # 4. Plot smoothed trend line with gradient colors
        # Create segments for color gradient based on slope
        for i in range(1, len(smoothed)):
            if pd.notna(slopes.iloc[i]):
                slope_val = slopes.iloc[i]
                
                # Color based on slope
                if slope_val > 0:
                    # Green shades for rising
                    intensity = min(abs(slope_val) * 20, 1.0)
                    color = plt.cm.Greens(0.5 + intensity * 0.5)
                elif slope_val < 0:
                    # Red shades for falling
                    intensity = min(abs(slope_val) * 20, 1.0)
                    color = plt.cm.Reds(0.5 + intensity * 0.5)
                else:
                    color = 'gray'
                
                ax.plot(dates[i-1:i+1], smoothed.iloc[i-1:i+1], 
                       color=color, linewidth=3, solid_capstyle='round', zorder=5)
        
        # 5. Mark inflection points
        inflections = self.find_inflection_points(smoothed)
        for inflection in inflections:
            if inflection['strength'] > 0.5:  # Only significant inflections
                if inflection['type'] == 'bottom':
                    marker = '^'
                    color = '#00ff00'
                    size = 100
                elif inflection['type'] == 'top':
                    marker = 'v'
                    color = '#ff0000'
                    size = 100
                else:
                    continue
                
                ax.scatter(inflection['date'], inflection['value'], 
                          marker=marker, color=color, s=size, 
                          edgecolor='white', linewidth=1, zorder=6)
        
        # 6. Mark neutral crossings
        for i in range(1, len(smoothed)):
            if (smoothed.iloc[i-1] < 50 and smoothed.iloc[i] > 50) or \
               (smoothed.iloc[i-1] > 50 and smoothed.iloc[i] < 50):
                ax.scatter(dates[i], 50, marker='o', color='yellow', 
                          s=50, edgecolor='white', linewidth=1, zorder=6)
        
        # Add neutral line
        ax.axhline(y=50, color='white', linestyle='-', linewidth=2, alpha=0.9, zorder=3)
        
        # Add extreme zones shading
        ax.axhspan(0, 20, alpha=0.1, color='red', zorder=0)
        ax.axhspan(80, 100, alpha=0.1, color='green', zorder=0)
        
        # Customize chart
        ax.set_ylim(0, 100)
        ax.set_xlabel('Date', fontsize=12, color='white')
        ax.set_ylabel('Fear & Greed Score', fontsize=12, color='white')
        ax.set_title(title, fontsize=16, fontweight='bold', pad=20, color='white')
        
        # Format axes
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %d'))
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=30))
        ax.xaxis.set_minor_locator(mdates.DayLocator(interval=7))
        plt.xticks(rotation=45, color='white')
        plt.yticks(color='white')
        
        # Grid
        ax.grid(True, alpha=0.1, linestyle=':', axis='x', color='gray')
        ax.set_axisbelow(True)
        
        # Style spines
        ax.spines['bottom'].set_color('white')
        ax.spines['left'].set_color('white')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        # Add legend
        from matplotlib.lines import Line2D
        legend_elements = [
            Line2D([0], [0], color='gray', lw=3, label='Smoothed Trend'),
            Line2D([0], [0], color='#00ff00', lw=1.5, linestyle='--', label='Resistance'),
            Line2D([0], [0], color='#ff0000', lw=1.5, linestyle='--', label='Support'),
            Line2D([0], [0], marker='^', color='w', markerfacecolor='#00ff00', 
                   markersize=8, label='Bottom (Buy Zone)', linestyle='None'),
            Line2D([0], [0], marker='v', color='w', markerfacecolor='#ff0000', 
                   markersize=8, label='Top (Sell Zone)', linestyle='None'),
            Line2D([0], [0], marker='o', color='w', markerfacecolor='yellow', 
                   markersize=6, label='Neutral Cross', linestyle='None')
        ]
        
        legend = ax.legend(handles=legend_elements, loc='upper left', 
                          facecolor='#1a1a1a', edgecolor='gray', framealpha=0.9)
        for text in legend.get_texts():
            text.set_color('white')
        
        # Add current value annotation
        current_score = scores[-1]
        current_smoothed = smoothed.iloc[-1]
        current_slope = slopes.iloc[-1] if pd.notna(slopes.iloc[-1]) else 0
        
        trend_text = 'RISING' if current_slope > 0 else 'FALLING' if current_slope < 0 else 'FLAT'
        trend_color = '#00ff00' if current_slope > 0 else '#ff0000' if current_slope < 0 else 'gray'
        
        info_text = f'Current: {current_score:.1f}\nTrend: {current_smoothed:.1f} ({trend_text})'
        ax.text(0.02, 0.98, info_text, transform=ax.transAxes, fontsize=12, 
               fontweight='bold', verticalalignment='top', color=trend_color,
               bbox=dict(boxstyle='round', facecolor='#1a1a1a', 
                        edgecolor=trend_color, alpha=0.9))
        
        plt.tight_layout()
        
        # Save chart
        plt.savefig(filename, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        
        print(f"  ✅ Saved: {filename}")
        return filename
    
    def create_sector_chart(self, sector, etf):
        """Create enhanced sector chart"""
        print(f"📊 Generating enhanced chart for {sector} sector...")
        
        # Get historical data
        fear_greed_series = self.get_historical_fear_greed(etf)
        
        # Create title
        title = f'{sector} Sector - Enhanced Fear & Greed Analysis ({self.period_days} Days)'
        
        # Generate filename
        filename = self.output_dir / f'sector_{sector.replace(" ", "_").lower()}_enhanced.png'
        
        return self.create_enhanced_chart(title, fear_greed_series, filename)
    
    def create_industry_chart(self, industry, stocks):
        """Create enhanced industry chart"""
        print(f"📊 Generating enhanced chart for {industry} industry...")
        
        # Calculate average fear/greed across industry stocks
        all_series = []
        for stock in stocks[:3]:
            series = self.get_historical_fear_greed(stock)
            all_series.append(series)
        
        # Average the scores
        fear_greed_series = pd.concat(all_series, axis=1).mean(axis=1)
        
        # Create title
        title = f'{industry} Industry - Enhanced Fear & Greed Analysis ({self.period_days} Days)'
        
        # Generate filename
        filename = self.output_dir / f'industry_{industry.replace(" ", "_").lower()}_enhanced.png'
        
        return self.create_enhanced_chart(title, fear_greed_series, filename)


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Enhanced Fear & Greed Analysis')
    parser.add_argument('--days', type=int, default=180,
                       help='Number of days to analyze (default: 180)')
    parser.add_argument('--portfolio', action='store_true',
                       help='Analyze only portfolio sectors/industries')
    parser.add_argument('--show-portfolio', action='store_true',
                       help='Show portfolio composition without generating charts')
    parser.add_argument('--sectors', nargs='+',
                       help='Specific sectors to analyze')
    parser.add_argument('--industries', nargs='+',
                       help='Specific industries to analyze')
    
    args = parser.parse_args()
    
    # Initialize analyzer
    analyzer = FearGreedEnhanced(period_days=args.days)
    
    if args.show_portfolio:
        # Just show portfolio composition
        from stock_info_manager import StockInfoManager
        info_manager = StockInfoManager()
        
        try:
            with open('config.json', 'r') as f:
                config = json.load(f)
            portfolio_stocks = config['portfolio']['stocks']
            
            print("\n📊 Portfolio Composition:")
            print("=" * 80)
            for ticker in portfolio_stocks:
                info = info_manager.get_info(ticker)
                print(f"\n{ticker}:")
                print(f"  Company: {info.get('company', 'Unknown')}")
                print(f"  Sector: {info.get('sector', 'Unknown')}")
                print(f"  Industry: {info.get('industry', 'Unknown')}")
                print(f"  Peers: {', '.join(info.get('peers', []))}")
            
            # Show available mappings
            print("\n📈 Available Sector ETFs:")
            for sector in sorted(analyzer.sector_etfs.keys()):
                print(f"  - {sector}")
            
            print("\n📊 Available Industries (first 20):")
            for ind in sorted(list(analyzer.industry_stocks.keys())[:20]):
                print(f"  - {ind}")
                
        except Exception as e:
            print(f"Error: {e}")
        return
    
    if args.portfolio:
        # Load portfolio and analyze only those sectors/industries
        from stock_info_manager import StockInfoManager
        info_manager = StockInfoManager()
        
        try:
            with open('config.json', 'r') as f:
                config = json.load(f)
            portfolio_stocks = config['portfolio']['stocks']
            
            if not portfolio_stocks:
                print("❌ No stocks found in portfolio")
                return
            
            sectors = set()
            industries = set()
            
            print(f"\n📊 Analyzing portfolio: {', '.join(portfolio_stocks)}")
            print("-" * 60)
            
            # Collect all unique sectors and industries
            for ticker in portfolio_stocks:
                info = info_manager.get_info(ticker)
                sector = info.get('sector')
                industry = info.get('industry')
                
                if sector and sector != 'Unknown':
                    sectors.add(sector)
                    print(f"{ticker}: {sector} sector")
                
                if industry and industry != 'Unknown':
                    industries.add(industry)
                    print(f"{ticker}: {industry} industry")
            
            print(f"\n📈 Found {len(sectors)} unique sectors")
            print(f"📊 Found {len(industries)} unique industries")
            
            # Generate charts for portfolio sectors
            print("\n🔍 Generating Sector Charts:")
            for sector in sorted(sectors):
                # Check both exact match and common variations
                if sector in analyzer.sector_etfs:
                    analyzer.create_sector_chart(sector, analyzer.sector_etfs[sector])
                else:
                    print(f"  ⚠️  No ETF mapping found for sector: {sector}")
            
            # Generate charts for portfolio industries
            print("\n🔍 Generating Industry Charts:")
            for industry in sorted(industries):
                found = False
                # Try exact match first
                if industry in analyzer.industry_stocks:
                    analyzer.create_industry_chart(industry, analyzer.industry_stocks[industry])
                    found = True
                else:
                    # Try fuzzy matching
                    for ind, stocks in analyzer.industry_stocks.items():
                        # More flexible matching
                        if (industry.lower() == ind.lower() or
                            industry.lower() in ind.lower() or
                            ind.lower() in industry.lower() or
                            # Handle special characters
                            industry.replace('&', 'and').lower() in ind.replace('&', 'and').lower() or
                            ind.replace('&', 'and').lower() in industry.replace('&', 'and').lower() or
                            # Handle em dash vs regular dash
                            industry.replace('—', '-').lower() in ind.replace('—', '-').lower() or
                            ind.replace('—', '-').lower() in industry.replace('—', '-').lower()):
                            
                            analyzer.create_industry_chart(ind, stocks)
                            found = True
                            break
                
                if not found:
                    print(f"  ⚠️  No data found for industry: {industry}")
                    # Show similar industries
                    similar = [ind for ind in analyzer.industry_stocks.keys() 
                              if any(word in ind.lower() for word in industry.lower().split())]
                    if similar:
                        print(f"     Similar industries available: {', '.join(similar[:3])}")
        
        except Exception as e:
            print(f"Error loading portfolio: {e}")
            import traceback
            traceback.print_exc()
    
    elif args.sectors:
        # Analyze specific sectors
        for sector in args.sectors:
            if sector in analyzer.sector_etfs:
                analyzer.create_sector_chart(sector, analyzer.sector_etfs[sector])
    
    elif args.industries:
        # Analyze specific industries
        for industry in args.industries:
            for ind, stocks in analyzer.industry_stocks.items():
                if industry.lower() in ind.lower():
                    analyzer.create_industry_chart(ind, stocks)
                    break
    
    else:
        # Example: Generate a few sample charts
        print("Generating sample enhanced charts...")
        
        # Sample sectors
        sample_sectors = ['Technology', 'Financials']
        for sector in sample_sectors:
            if sector in analyzer.sector_etfs:
                analyzer.create_sector_chart(sector, analyzer.sector_etfs[sector])
        
        # Sample industries
        sample_industries = ['Semiconductors', 'Banks']
        for industry in sample_industries:
            if industry in analyzer.industry_stocks:
                analyzer.create_industry_chart(industry, analyzer.industry_stocks[industry])
    
    print(f"\n✅ Enhanced charts generated in: {analyzer.output_dir}/")
    
    # Open first chart for preview
    import webbrowser
    charts = list(analyzer.output_dir.glob('*.png'))
    if charts:
        webbrowser.open(f'file://{charts[0].absolute()}')


if __name__ == "__main__":
    main()