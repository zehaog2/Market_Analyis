# 📊 Fear & Greed Tracker

I made this fear & greed tracker because tradingview's free plan doesn't have this. Also added some scripts for specific lookups.

## 🌟 Features

- Smart Indicators**: Auto-detect support/resistance levels and inflection points
- Multi-Level Analysis**: Analyze individual stocks, sectors, and industries

Sample outputs:
![sector_industrials_enhanced](https://github.com/user-attachments/assets/9757b99c-0903-481e-8f17-18b9b647ec77)
![sector_technology_enhanced](https://github.com/user-attachments/assets/403da781-ba91-4640-b81a-a21fb16370bf)
![industry_semiconductors_enhanced](https://github.com/user-attachments/assets/e2a7f429-95db-4f54-8705-e85edc439f6c)

### Usage

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
## 🔧 Configuration

### Customizing Analysis Periods

Default is 180 days (6 months). You can adjust:
```bash
python stock_fear_greed.py AAPL --days 90    # 3 months
python stock_fear_greed.py AAPL --days 365   # 1 year
```

### Watchlist Lookup

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

### Maths

The sentiment score (0-100) is calculated using: (adjust weight to your own liking please)
- **Price Momentum** (40%): Recent price performance
- **RSI** (30%): Relative Strength Index
- **Volume Analysis** (20%): Volume vs average
- **Volatility** (10%): Market volatility (inverse relationship)

### Data Sources

- **Market Data**: Yahoo Finance API (yfinance)
- **Sector ETFs**: SPDR Sector ETFs (XLK, XLF, XLV, etc.)
- **Updates**: Real-time during market hours

## Improvements I am working on

Contributions are welcome! Please feel free to submit a Pull Request. Areas for improvement:
- Integration of EMA and order blocks
- automized sector/industry mappings & dicionary updates
- Alternative data sources (X, meta API)
- Reduce clutter on support / resistance

## Disclaimer

This tool is for educational and informational purposes only. It is not financial advice. Do your own research... 

---
