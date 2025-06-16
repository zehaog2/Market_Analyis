# 📊 Fear & Greed Tracker

Visualize market sentiment through Fear & Greed analysis. Track individual stocks, sectors, and industries with advanced technical indicators to identify optimal entry and exit points.

## 🌟 Features

- Enhanced Visualizations**: Beautiful dark-themed charts with trend analysis
- Smart Indicators**: Auto-detect support/resistance levels and inflection points
- Multi-Level Analysis**: Analyze individual stocks, sectors, and industries
- Portfolio Integration**: Track your entire portfolio's sentiment
- Real-Time Data**: Powered by Yahoo Finance for up-to-date market data

## 🚀 Quick Start

### Prerequisites

```bash
pip3 install yfinance pandas numpy matplotlib seaborn requests beautifulsoup4 feedparser textblob reportlab schedule scipy
```

### Installation

```bash
git clone https://github.com/yourusername/fear-greed-tracker.git
cd fear-greed-tracker
```

### Basic Usage

1. **Analyze Individual Stocks** (Interactive Mode):
```bash
python stock_fear_greed.py
```
Then enter tickers when prompted: `AAPL MSFT GOOGL NVDA`

2. **Manage Your Portfolio**:
```bash
python portfolio_manager.py
```

3. **Analyze Your Portfolio's Sectors/Industries**:
```bash
python fear_greed_enhanced.py --portfolio
```

## 📖 Detailed Usage

### Individual Stock Analysis

```bash
# Interactive mode (recommended)
python stock_fear_greed.py

# Command line mode
python stock_fear_greed.py AAPL TSLA GOOGL

# Custom time period (default: 180 days)
python stock_fear_greed.py AAPL --days 90

# From watchlist file
python stock_fear_greed.py --watchlist my_stocks.txt
```

### Portfolio Management

```bash
# Interactive portfolio manager
python portfolio_manager.py

# Command line
python portfolio_manager.py add AAPL MSFT
python portfolio_manager.py remove GME
python portfolio_manager.py list
```

### Sector & Industry Analysis

```bash
# Analyze all sectors and industries
python fear_greed_enhanced.py

# Analyze only your portfolio's sectors
python fear_greed_enhanced.py --portfolio

# Specific sectors
python fear_greed_enhanced.py --sectors Technology Financials

# Different time periods
python fear_greed_enhanced.py --days 90 --portfolio
```

## 📊 Understanding the Charts

### Visual Elements

- **📊 Faded Bars**: Daily sentiment (30% opacity for context)
- **📈 Colored Trend Line**: Smoothed sentiment trend
  - Green = Rising sentiment
  - Red = Falling sentiment
  - Darker color = Stronger momentum
- **🔴 Support Lines**: Red dashed lines where sentiment often bounces up
- **🟢 Resistance Lines**: Green dashed lines where sentiment often reverses down
- **🔺 Green Triangles**: Potential buying opportunities (sentiment bottoms)
- **🔻 Red Triangles**: Potential selling opportunities (sentiment tops)
- **🟡 Yellow Dots**: Neutral sentiment crossings
- **⬜ Gray Boxes**: Consolidation zones (markets deciding direction)

### Numbers on Support/Resistance Lines

The numbers show how many times sentiment bounced at that level:
- `3` = Minimum (3 bounces)
- `5` = Strong level (5 bounces)
- `7+` = Very strong level

Higher numbers = more reliable levels

### How to Trade with These Charts

**Buy Signals**:
- Sentiment in extreme fear (< 30) starting to rise
- Green triangle appears after extended red period
- Break above resistance line with high touch count
- Trend line turns from red to green

**Sell Signals**:
- Sentiment in extreme greed (> 70) starting to fall
- Red triangle appears after extended green period
- Break below support line with high touch count
- Trend line turns from green to red

## 📁 File Structure

```
fear-greed-tracker/
├── stock_fear_greed.py       # Individual stock analysis
├── portfolio_manager.py      # Portfolio management
├── fear_greed_enhanced.py    # Sector/industry analysis
├── fear_greed_timeseries.py  # Base analysis class
├── stock_info_manager.py     # Stock data management
├── config.json              # Your portfolio (auto-created)
└── README.md                # This file

Output folders:
├── stock_fear_greed/        # Individual stock charts
├── fear_greed_enhanced/     # Sector/industry charts
└── stock_info_cache.json    # Cached stock data
```

## 🎯 Example Workflow

```bash
# 1. Set up your portfolio
python portfolio_manager.py
> Choose option 2 (Add ticker)
> Enter: AAPL MSFT NVDA TSLA

# 2. Analyze your portfolio sectors
python fear_greed_enhanced.py --portfolio

# 3. Deep dive into specific stocks
python stock_fear_greed.py
> Enter: AAPL NVDA

# 4. Check sector rotation opportunities
python fear_greed_enhanced.py --sectors Technology Financials Healthcare
```

## 🔧 Configuration

### Customizing Analysis Periods

Default is 180 days (6 months). You can adjust:
```bash
python stock_fear_greed.py AAPL --days 90    # 3 months
python stock_fear_greed.py AAPL --days 365   # 1 year
```

### Creating a Watchlist

Create a text file with one ticker per line:
```
# watchlist.txt
AAPL
MSFT
GOOGL
TSLA
SPY
```

Then analyze all at once:
```bash
python stock_fear_greed.py --watchlist watchlist.txt
```

## 📈 Technical Details

### Fear & Greed Calculation

The sentiment score (0-100) is calculated using:
- **Price Momentum** (40%): Recent price performance
- **RSI** (30%): Relative Strength Index
- **Volume Analysis** (20%): Volume vs average
- **Volatility** (10%): Market volatility (inverse relationship)

### Data Sources

- **Market Data**: Yahoo Finance API (yfinance)
- **Sector ETFs**: SPDR Sector ETFs (XLK, XLF, XLV, etc.)
- **Updates**: Real-time during market hours

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Areas for improvement:
- Integration of EMA and order blocks
- automized sector/industry mappings & dicionary updates
- Alternative data sources (X, meta API)
- Reduce clutter on support / resistance

## ⚠️ Disclaimer

This tool is for educational and informational purposes only. It is not financial advice. Do your own research...


---
