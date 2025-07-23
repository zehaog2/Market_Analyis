# Portfolio enchancer
## Correlation Matrix
- (Jul 23, 2025) https://www.portfoliovisualizer.com/asset-correlations?s=y&sl=5Pc1Rn5TUqsb9Xl7tbDnLS
- Check for non-speculative assets
  
## USEFUL command lines
```
python3 portfolio_manager.py
# General charts based on portfolio (with different timeframe)

Run Script for all sectors:
python3 fear_greed_timeseries.py --sectors-only
python3 fear_greed_timeseries.py --industries-only

Run Web scrape script: python3 stock_scraper_upgraded.py


python3 sector_fear_greed_dashboard.py
python3 sector_fear_greed_dashboard.py --continue-on-error

python3 industry_lookup_tool.py
# Search Directly
python3 industry_lookup_tool.py --industry "Semiconductors"
# search indirectly
python industry_lookup_tool.py --search "software"
# custom
python industry_lookup_tool.py --industry "Banks" --days 90


# single stock analysis:
Rscript stock_corr_advanced.R 
# portfolio analysis:
Rscript stock_corr_advanced.R --batch config.json

Run this always!:
Rscript stock_corr_integrated.R --batch config.json 3 --advanced
```
## Risk Analysis
All files in R are dependent on each other. Check the function file for methodology, and my_strategy_analysis.pdf for a simple user guide.

## Fear & Greed Tracker
Track sector price momentum with buy/sell signals, work well with looking at sector ETF's momentum indicators side by side.

![sector_industrials_enhanced](https://github.com/user-attachments/assets/9757b99c-0903-481e-8f17-18b9b647ec77)
<img width="1851" alt="Screenshot 2025-06-17 at 11 42 12 AM" src="https://github.com/user-attachments/assets/c9c90459-302d-4376-9ef5-26c1a8b6be24" />


### 📈 Fear & Greed Details

#### Maths

The sentiment score (0-100) is calculated using: (adjust weight to your own liking please)
- **Price Momentum** (40%): Recent price performance
- **RSI** (30%): Relative Strength Index
- **Volume Analysis** (20%): Volume vs average
- **Volatility** (10%): Market volatility (inverse relationship)

#### Data Sources

- **Market Data**: Yahoo Finance API (yfinance)
- **Sector ETFs**: SPDR Sector ETFs (XLK, XLF, XLV, etc.)
- **Updates**: Real-time during market hours

## Improvements I might work on:
- Cleaning up comments
- Minor Optimizations
- checking file structure
- integrating custom database to stream queries

## Disclaimer
This tool is for educational and speculative purposes only. It is not financial advice. Do your own research... 

---
