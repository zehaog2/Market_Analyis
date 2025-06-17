import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime, timedelta
import json
import csv
import time
from urllib.parse import quote
import feedparser
from textblob import TextBlob
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, landscape
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_CENTER
import yfinance as yf

from stock_info_manager import StockInfoManager

class StockContextAnalyzer:
    def __init__(self, portfolio_tickers):
        """Initialize analyzer with portfolio and context mappings"""
        self.portfolio = portfolio_tickers
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }
        
        self.info_manager = StockInfoManager()
        print("📊 Updating portfolio information...")
        self.info_manager.update_portfolio(self.portfolio)
        
        # Get stock info from manager
        self.stock_info = {}
        for ticker in self.portfolio:
            self.stock_info[ticker] = self.info_manager.get_info(ticker)
    
    def scrape_yahoo_finance(self, ticker):
        """Scrape news from Yahoo Finance"""
        url = f"https://finance.yahoo.com/quote/{ticker}/news"
        articles = []
        
        try:
            response = requests.get(url, headers=self.headers)
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                news_items = soup.find_all('h3', class_='Mb(5px)')[:10]
                
                for item in news_items:
                    link_tag = item.find('a')
                    if link_tag:
                        title = link_tag.text.strip()
                        link = link_tag.get('href', '')
                        if not link.startswith('http'):
                            link = 'https://finance.yahoo.com' + link
                        
                        # Try to find timestamp
                        time_element = item.find_next_sibling('div')
                        timestamp = time_element.text if time_element else 'Recent'
                        
                        articles.append({
                            'title': title,
                            'link': link,
                            'source': 'Yahoo Finance',
                            'ticker': ticker,
                            'timestamp': timestamp
                        })
            
            time.sleep(0.5)
            
        except Exception as e:
            pass
        
        return articles
    
    def scrape_google_news_rss(self, query):
        """Use Google News RSS feed"""
        rss_url = f"https://news.google.com/rss/search?q={quote(query)}&hl=en-US&gl=US&ceid=US:en"
        articles = []
        
        try:
            feed = feedparser.parse(rss_url)
            
            for entry in feed.entries[:10]:
                articles.append({
                    'title': entry.title,
                    'link': entry.link,
                    'source': entry.source.title if hasattr(entry, 'source') else 'Google News',
                    'summary': BeautifulSoup(entry.get('summary', ''), 'html.parser').text[:200]
                })
            
            time.sleep(0.5)
            
        except Exception as e:
            pass
        
        return articles
    
    def analyze_sentiment(self, text):
        """Analyze sentiment using TextBlob"""
        try:
            blob = TextBlob(text)
            polarity = blob.sentiment.polarity
            
            if polarity > 0.1:
                return 'positive', polarity
            elif polarity < -0.1:
                return 'negative', polarity
            else:
                return 'neutral', polarity
        except:
            return 'neutral', 0.0
    
    def get_stock_news_sentiment(self, ticker):
        """Get news and sentiment for a single stock"""
        all_articles = []
        
        # Get company name
        company = self.stock_info.get(ticker, {}).get('company', ticker)
        
        # Scrape from multiple sources
        all_articles.extend(self.scrape_yahoo_finance(ticker))
        all_articles.extend(self.scrape_google_news_rss(f"{ticker} {company} stock"))
        
        # Analyze sentiment
        sentiments = {'positive': 0, 'neutral': 0, 'negative': 0}
        sentiment_scores = []
        
        for article in all_articles[:10]:  # Limit to top 10
            full_text = article['title'] + ' ' + article.get('summary', '')
            sentiment, score = self.analyze_sentiment(full_text)
            sentiments[sentiment] += 1
            sentiment_scores.append(score)
        
        # Calculate average sentiment
        avg_sentiment = sum(sentiment_scores) / len(sentiment_scores) if sentiment_scores else 0
        
        return sentiments, avg_sentiment, all_articles
    
    def calculate_industry_sentiment(self, ticker):
        """Calculate industry sentiment based on peer companies"""
        info = self.stock_info.get(ticker, {})
        peers = info.get('peers', [])
        
        if not peers:
            return 0.0
        
        peer_sentiments = []
        peer_price_changes = []
        
        # Check peer stock performance (50% weight)
        for peer in peers[:3]:
            try:
                peer_stock = yf.Ticker(peer)
                hist = peer_stock.history(period='5d')
                if len(hist) >= 2:
                    # 5-day performance
                    peer_change = (hist['Close'].iloc[-1] - hist['Close'].iloc[0]) / hist['Close'].iloc[0]
                    peer_price_changes.append(peer_change)
            except:
                pass
        
        # Convert price changes to sentiment
        if peer_price_changes:
            avg_peer_change = sum(peer_price_changes) / len(peer_price_changes)
            # More aggressive scaling: -2% = -0.8, +2% = +0.8
            price_sentiment = max(-1, min(1, avg_peer_change * 40))
            peer_sentiments.append(price_sentiment)
        
        # Check peer news (50% weight)
        for peer in peers[:2]:  # Reduced to save time
            print(f"    Checking peer {peer}...")
            articles = self.scrape_google_news_rss(f"{peer} stock")
            
            for article in articles[:3]:  # Fewer articles
                text = article['title'] + ' ' + article.get('summary', '')
                _, score = self.analyze_sentiment(text)
                peer_sentiments.append(score)
        
        # Get industry-specific news
        industry = info.get('industry', '')
        if industry:
            industry_articles = self.scrape_google_news_rss(f"{industry} industry stocks")
            for article in industry_articles[:3]:
                text = article['title'] + ' ' + article.get('summary', '')
                _, score = self.analyze_sentiment(text)
                peer_sentiments.append(score)
        
        # Calculate weighted average
        if peer_sentiments:
            return round(sum(peer_sentiments) / len(peer_sentiments), 2)
        return 0.0
    
    def calculate_sector_sentiment(self, ticker):
        """Calculate sector sentiment using ETF performance and news"""
        info = self.stock_info.get(ticker, {})
        sector_etf = info.get('sector_etf', '')
        sector = info.get('sector', '')
        
        sentiment_score = 0.0
        
        # Get ETF performance (70% weight) - INCREASED weight and sensitivity
        if sector_etf:
            try:
                etf = yf.Ticker(sector_etf)
                hist = etf.history(period='5d')
                if len(hist) >= 2:
                    # Calculate 5-day return
                    five_day_return = (hist['Close'].iloc[-1] - hist['Close'].iloc[0]) / hist['Close'].iloc[0]
                    
                    # More aggressive scaling
                    # -2% = -0.8, -1% = -0.4, +1% = +0.4, +2% = +0.8
                    etf_sentiment = max(-1, min(1, five_day_return * 40))
                    
                    sentiment_score += etf_sentiment * 0.7  # 70% weight on price action
                    
                    # Also check today's move if available
                    if len(hist) >= 2:
                        today_return = (hist['Close'].iloc[-1] - hist['Close'].iloc[-2]) / hist['Close'].iloc[-2]
                        # If today was particularly bad, weight it extra
                        if today_return < -0.01:  # More than 1% down
                            sentiment_score -= 0.2  # Additional penalty for red day
            except:
                pass
        
        # Get sector news sentiment (30% weight) - REDUCED weight
        if sector:
            sector_articles = self.scrape_google_news_rss(f"{sector} sector stocks market")
            sector_sentiments = []
            
            for article in sector_articles[:5]:  # Reduced from 10
                text = article['title'] + ' ' + article.get('summary', '')
                _, score = self.analyze_sentiment(text)
                sector_sentiments.append(score)
            
            if sector_sentiments:
                news_sentiment = sum(sector_sentiments) / len(sector_sentiments)
                sentiment_score += news_sentiment * 0.3  # Only 30% weight on news
        
        return round(sentiment_score, 2)
    
    def run_analysis(self):
        """Run complete analysis for all stocks"""
        print(f"\n🚀 Starting Context-Aware Analysis")
        print(f"📊 Portfolio: {', '.join(self.portfolio)}")
        print(f"⏰ Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        results = []
        
        for ticker in self.portfolio:
            print(f"\n📈 Analyzing {ticker}...")
            
            # Get stock info
            info = self.stock_info.get(ticker, {})
            
            # Get individual stock sentiment
            print(f"  Getting news sentiment...")
            sentiments, avg_sentiment, articles = self.get_stock_news_sentiment(ticker)
            
            # Calculate industry sentiment
            print(f"  Calculating industry sentiment...")
            industry_sentiment = self.calculate_industry_sentiment(ticker)
            
            # Calculate sector sentiment
            print(f"  Calculating sector sentiment...")
            sector_sentiment = self.calculate_sector_sentiment(ticker)
            
            results.append({
                'ticker': ticker,
                'positive': sentiments['positive'],
                'neutral': sentiments['neutral'],
                'negative': sentiments['negative'],
                'industry': info.get('industry', 'N/A'),
                'industry_sentiment': industry_sentiment,
                'sector': info.get('sector', 'N/A'),
                'sector_sentiment': sector_sentiment
            })
            
            print(f"  ✅ Complete - Pos: {sentiments['positive']}, Neut: {sentiments['neutral']}, Neg: {sentiments['negative']}")
        
        return results
    
    def save_to_csv(self, results, filename=None):
        """Save results to CSV"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"stock_context_analysis_{timestamp}.csv"
        
        # Convert Path object to string if necessary
        filename = str(filename)
        
        df = pd.DataFrame(results)
        df.to_csv(filename, index=False)
        
        print(f"\n📊 CSV saved: {filename}")
        return filename
    
    def save_to_pdf(self, results, filename=None):
        """Generate 1-page PDF report"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"stock_context_report_{timestamp}.pdf"
        
        # Convert Path object to string if necessary
        filename = str(filename)
        
        # Use landscape orientation for wider table
        doc = SimpleDocTemplate(filename, pagesize=landscape(letter))
        story = []
        styles = getSampleStyleSheet()
        
        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=20,
            textColor=colors.HexColor('#1f77b4'),
            spaceAfter=10,
            alignment=TA_CENTER
        )
        
        title = Paragraph("Stock Portfolio Context Analysis", title_style)
        story.append(title)
        
        # Timestamp
        date_style = ParagraphStyle(
            'DateStyle',
            parent=styles['Normal'],
            fontSize=10,
            alignment=TA_CENTER,
            spaceAfter=20
        )
        # Add data freshness note
        freshness_style = ParagraphStyle(
            'FreshnessStyle',
            parent=styles['Normal'],
            fontSize=8,
            alignment=TA_CENTER,
            spaceAfter=15,
            textColor=colors.grey
        )
        
        # Get current market status
        now = datetime.now()
        market_day = now.strftime('%A')
        
        freshness_note = Paragraph(
            f"News data: Live from web | ETF prices: As of last market close | Current: {market_day}",
            freshness_style
        )
        story.append(freshness_note)
        
        # Create table data
        table_data = [['Ticker', 'Positive', 'Neutral', 'Negative', 'Industry', 'Industry\nSentiment', 'Sector', 'Sector\nSentiment']]
        
        for result in results:
            # Color code sentiment scores
            ind_sentiment = result['industry_sentiment']
            sec_sentiment = result['sector_sentiment']
            
            # Format sentiment scores with color
            ind_color = 'green' if ind_sentiment > 0.1 else 'red' if ind_sentiment < -0.1 else 'black'
            sec_color = 'green' if sec_sentiment > 0.1 else 'red' if sec_sentiment < -0.1 else 'black'
            
            row = [
                result['ticker'],
                str(result['positive']),
                str(result['neutral']),
                str(result['negative']),
                result['industry'],
                f"{ind_sentiment:+.2f}",
                result['sector'],
                f"{sec_sentiment:+.2f}"
            ]
            table_data.append(row)
        
        # Create table
        table = Table(table_data, colWidths=[1*inch, 0.8*inch, 0.8*inch, 0.8*inch, 2*inch, 1*inch, 2*inch, 1*inch])
        
        # Style the table
        table_style = TableStyle([
            # Header
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1f77b4')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            
            # Data
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f0f0f0')]),
            
            # Alignment
            ('ALIGN', (1, 1), (3, -1), 'CENTER'),  # Numbers centered
            ('ALIGN', (5, 1), (5, -1), 'CENTER'),  # Industry sentiment
            ('ALIGN', (7, 1), (7, -1), 'CENTER'),  # Sector sentiment
        ])
        
        # Color code sentiment values
        for i, result in enumerate(results, 1):
            # Industry sentiment coloring
            if result['industry_sentiment'] > 0.1:
                table_style.add('TEXTCOLOR', (5, i), (5, i), colors.green)
            elif result['industry_sentiment'] < -0.1:
                table_style.add('TEXTCOLOR', (5, i), (5, i), colors.red)
            
            # Sector sentiment coloring
            if result['sector_sentiment'] > 0.1:
                table_style.add('TEXTCOLOR', (7, i), (7, i), colors.green)
            elif result['sector_sentiment'] < -0.1:
                table_style.add('TEXTCOLOR', (7, i), (7, i), colors.red)
        
        table.setStyle(table_style)
        story.append(table)
        
        # Build PDF
        doc.build(story)
        print(f"📄 PDF saved: {filename}")
        return filename


def load_config(config_file='config.json'):
    """Load configuration from JSON file"""
    try:
        with open(config_file, 'r') as f:
            return json.load(f)
    except:
        return {'portfolio': {'stocks': []}}


if __name__ == "__main__":
    # Load configuration
    config = load_config()
    PORTFOLIO = config['portfolio']['stocks']
    
    if not PORTFOLIO:
        print("No stocks found in config.json")
        print("Please add stocks using: python portfolio_manager.py")
        exit(1)
    
    # Remove duplicates from portfolio
    PORTFOLIO = list(dict.fromkeys(PORTFOLIO))
    
    # Initialize analyzer
    analyzer = StockContextAnalyzer(PORTFOLIO)
    
    # Run analysis
    results = analyzer.run_analysis()
    
    # Save results
    csv_file = analyzer.save_to_csv(results)
    pdf_file = analyzer.save_to_pdf(results)
    
    print(f"\n✅ Analysis complete!")
    print(f"\n📁 Files generated:")
    print(f"   - {csv_file}")
    print(f"   - {pdf_file}")