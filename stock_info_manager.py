import json
import os
from datetime import datetime
import requests
from typing import Dict, List, Optional
import yfinance as yf
from market_mapping import SECTOR_ETF_MAP, INDUSTRY_PEERS, SECTOR_LEADERS

class StockInfoManager:
    """Manages stock information including company details, peers, and sector ETFs"""
    
    def __init__(self, cache_file='stock_info_cache.json'):
        self.cache_file = cache_file
        self.stock_info = self.load_cache()
        
        # Import from market_mappings.py
        self.sector_etf_map = SECTOR_ETF_MAP
        self.industry_peers = INDUSTRY_PEERS
        self.sector_leaders = SECTOR_LEADERS
    
    def load_cache(self) -> Dict:
        """Load cached stock information"""
        if os.path.exists(self.cache_file):
            try:
                with open(self.cache_file, 'r') as f:
                    return json.load(f)
            except:
                return {}
        return {}
    
    def save_cache(self):
        """Save stock information to cache"""
        with open(self.cache_file, 'w') as f:
            json.dump(self.stock_info, f, indent=2)
    
    def get_stock_details(self, ticker: str) -> Dict:
        """Fetch stock details from yfinance"""
        try:
            stock = yf.Ticker(ticker)
            info = stock.info
            
            return {
                'company': info.get('longName', info.get('shortName', ticker)),
                'industry': info.get('industry', 'Unknown'),
                'sector': info.get('sector', 'Unknown'),
                'market_cap': info.get('marketCap', 0),
                'exchange': info.get('exchange', 'Unknown')
            }
        except Exception as e:
            print(f"Error fetching {ticker} details: {e}")
            return {
                'company': ticker,
                'industry': 'Unknown',
                'sector': 'Unknown',
                'market_cap': 0,
                'exchange': 'Unknown'
            }
    
    def find_peers(self, ticker: str, industry: str, sector: str, min_peers: int = 5) -> List[str]:
        """Find peer companies based on industry and sector"""
        peers = []
        
        # Use the imported industry peers from market_mappings.py
        # Get peers from industry mapping
        for ind, peer_list in self.industry_peers.items():
            if ind.lower() in industry.lower() or industry.lower() in ind.lower():
                peers.extend([p for p in peer_list if p != ticker])
                break
        
        # If not enough peers, add some based on sector leaders
        if len(peers) < min_peers and sector in self.sector_leaders:
            additional_peers = [p for p in self.sector_leaders[sector] if p != ticker and p not in peers]
            peers.extend(additional_peers)
        
        # Remove duplicates and limit to requested number
        peers = list(dict.fromkeys(peers))[:min_peers * 2]  # Get extra in case some are invalid
        
        # Validate peers (check if they exist)
        valid_peers = []
        for peer in peers:
            try:
                yf.Ticker(peer).info
                valid_peers.append(peer)
                if len(valid_peers) >= min_peers:
                    break
            except:
                continue
        
        return valid_peers[:min_peers]
    
    def get_sector_etf(self, sector: str) -> str:
        """Get the appropriate sector ETF"""
        return self.sector_etf_map.get(sector, 'SPY')  # Default to SPY if sector not found
    
    def update_ticker(self, ticker: str, force_update: bool = False) -> Dict:
        """Update or add a ticker's information"""
        ticker = ticker.upper()
        
        # Check if we have recent data
        if not force_update and ticker in self.stock_info:
            cached_data = self.stock_info[ticker]
            if 'last_updated' in cached_data:
                last_update = datetime.fromisoformat(cached_data['last_updated'])
                if (datetime.now() - last_update).days < 7:  # Cache for 7 days
                    print(f"Using cached data for {ticker}")
                    return cached_data
        
        print(f"Fetching fresh data for {ticker}...")
        
        # Get stock details
        details = self.get_stock_details(ticker)
        
        # Find peers
        peers = self.find_peers(ticker, details['industry'], details['sector'])
        
        # Get sector ETF
        sector_etf = self.get_sector_etf(details['sector'])
        
        # Compile all information
        stock_data = {
            'company': details['company'],
            'industry': details['industry'],
            'sector': details['sector'],
            'peers': peers,
            'sector_etf': sector_etf,
            'market_cap': details['market_cap'],
            'exchange': details['exchange'],
            'last_updated': datetime.now().isoformat()
        }
        
        # Update cache
        self.stock_info[ticker] = stock_data
        self.save_cache()
        
        print(f"✅ Updated {ticker}: {details['company']} - {details['industry']}")
        return stock_data
    
    def update_portfolio(self, tickers: List[str], force_update: bool = False):
        """Update information for a list of tickers"""
        for ticker in tickers:
            self.update_ticker(ticker, force_update)
    
    def get_info(self, ticker: str) -> Dict:
        """Get information for a ticker (from cache or fetch if needed)"""
        ticker = ticker.upper()
        if ticker not in self.stock_info:
            return self.update_ticker(ticker)
        return self.stock_info[ticker]
    
    def export_readable(self, filename: str = 'stock_info_readable.json'):
        """Export stock info in a human-readable format"""
        readable_data = {}
        for ticker, info in self.stock_info.items():
            readable_data[ticker] = {
                'Company': info['company'],
                'Industry': info['industry'],
                'Sector': info['sector'],
                'Peers': ', '.join(info['peers']),
                'Sector ETF': info['sector_etf'],
                'Market Cap': f"${info['market_cap']:,.0f}" if info['market_cap'] > 0 else 'N/A',
                'Exchange': info['exchange'],
                'Last Updated': info.get('last_updated', 'Unknown')
            }
        
        with open(filename, 'w') as f:
            json.dump(readable_data, f, indent=2)
        print(f"📄 Exported readable format to {filename}")