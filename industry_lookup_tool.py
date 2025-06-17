#!/usr/bin/env python3
"""
Industry Fear & Greed Lookup Tool
"""

import argparse
import webbrowser
from pathlib import Path
from datetime import datetime
import difflib
from fear_greed_enhanced import FearGreedEnhanced
from market_mapping import INDUSTRY_PEERS


class IndustryLookup:
    """Interactive tool for industry-specific fear/greed analysis"""
    
    def __init__(self, period_days=180):
        self.analyzer = FearGreedEnhanced(period_days)
        self.industries = list(INDUSTRY_PEERS.keys())
        self.output_dir = Path('industry_charts')
        self.output_dir.mkdir(exist_ok=True)
        
        # Override the analyzer's output directory
        self.analyzer.output_dir = self.output_dir
        
        print(f"🔍 Industry Lookup Tool initialized")
        print(f"📁 Output directory: {self.output_dir}")
        print(f"📅 Analysis period: {period_days} days")
        print(f"🏭 Available industries: {len(self.industries)}")
    
    def search_industries(self, query, max_results=10):
        """Search for industries matching the query"""
        query = query.lower()
        matches = []
        
        # Exact matches first
        for industry in self.industries:
            if query == industry.lower():
                matches.append(('exact', industry, 1.0))
        
        # Partial matches
        for industry in self.industries:
            if query in industry.lower() and query != industry.lower():
                # Calculate match score based on how much of the industry name matches
                score = len(query) / len(industry)
                matches.append(('partial', industry, score))
        
        # Fuzzy matches using difflib
        if len(matches) < max_results:
            for industry in self.industries:
                if industry not in [m[1] for m in matches]:
                    similarity = difflib.SequenceMatcher(None, query, industry.lower()).ratio()
                    if similarity > 0.3:  # Minimum similarity threshold
                        matches.append(('fuzzy', industry, similarity))
        
        # Sort by match type and score
        matches.sort(key=lambda x: (x[0] != 'exact', x[0] != 'partial', -x[2]))
        
        return matches[:max_results]
    
    def show_industry_details(self, industry_name):
        """Show details about an industry"""
        if industry_name not in INDUSTRY_PEERS:
            print(f"❌ Industry '{industry_name}' not found")
            return False
        
        stocks = INDUSTRY_PEERS[industry_name]
        
        print(f"\n🏭 Industry: {industry_name}")
        print("=" * (len(industry_name) + 12))
        print(f"📊 Representative stocks: {len(stocks)}")
        print(f"🔝 Top stocks: {', '.join(stocks[:5])}")
        
        if len(stocks) > 5:
            print(f"💼 All stocks: {', '.join(stocks)}")
        
        return True
    
    def generate_industry_chart(self, industry_name):
        """Generate chart for a specific industry"""
        if industry_name not in INDUSTRY_PEERS:
            print(f"❌ Industry '{industry_name}' not found")
            return None
        
        try:
            print(f"\n📊 Generating chart for {industry_name}...")
            
            stocks = INDUSTRY_PEERS[industry_name]
            chart_path = self.analyzer.create_industry_chart(industry_name, stocks)
            
            print(f"✅ Chart generated: {chart_path}")
            return chart_path
            
        except Exception as e:
            print(f"❌ Error generating chart: {e}")
            return None
    
    def interactive_search(self):
        """Interactive search interface"""
        print(f"\n🔍 Interactive Industry Search")
        print("=" * 35)
        print("💡 Tips:")
        print("   • Type 'list' to see all industries")
        print("   • Type 'exit' to quit")
        print("   • Type partial names for fuzzy search")
        print("   • Press Enter for random industry\n")
        
        while True:
            try:
                query = input("🔍 Search for industry (or 'exit'): ").strip()
                
                if not query:
                    # Random industry
                    import random
                    industry = random.choice(self.industries)
                    print(f"🎲 Random industry: {industry}")
                    self.show_industry_details(industry)
                    
                    if input("\n📊 Generate chart? (y/N): ").lower().startswith('y'):
                        chart_path = self.generate_industry_chart(industry)
                        if chart_path:
                            if input("🌐 Open chart? (y/N): ").lower().startswith('y'):
                                webbrowser.open(f'file://{chart_path.absolute()}')
                    continue
                
                if query.lower() == 'exit':
                    print("👋 Goodbye!")
                    break
                
                if query.lower() == 'list':
                    self.list_all_industries()
                    continue
                
                # Search for industries
                matches = self.search_industries(query)
                
                if not matches:
                    print(f"❌ No industries found matching '{query}'")
                    continue
                
                print(f"\n🔍 Found {len(matches)} matches for '{query}':")
                print("-" * 50)
                
                for i, (match_type, industry, score) in enumerate(matches, 1):
                    match_indicator = "🎯" if match_type == 'exact' else "📍" if match_type == 'partial' else "🔍"
                    print(f"{i:2d}. {match_indicator} {industry}")
                
                # Get user choice
                try:
                    choice = input(f"\n📊 Select industry (1-{len(matches)}) or Enter to search again: ").strip()
                    
                    if not choice:
                        continue
                    
                    choice_num = int(choice)
                    if 1 <= choice_num <= len(matches):
                        selected_industry = matches[choice_num - 1][1]
                        
                        # Show details
                        self.show_industry_details(selected_industry)
                        
                        # Offer to generate chart
                        if input("\n📊 Generate chart? (y/N): ").lower().startswith('y'):
                            chart_path = self.generate_industry_chart(selected_industry)
                            if chart_path:
                                if input("🌐 Open chart? (y/N): ").lower().startswith('y'):
                                    webbrowser.open(f'file://{chart_path.absolute()}')
                    else:
                        print("❌ Invalid selection")
                        
                except ValueError:
                    print("❌ Please enter a number")
                    
            except KeyboardInterrupt:
                print("\n👋 Goodbye!")
                break
            except Exception as e:
                print(f"❌ Error: {e}")
    
    def list_all_industries(self, columns=3):
        """List all available industries in columns"""
        print(f"\n🏭 All Available Industries ({len(self.industries)} total):")
        print("=" * 60)
        
        # Sort industries
        sorted_industries = sorted(self.industries)
        
        # Calculate column width
        max_width = max(len(industry) for industry in sorted_industries)
        col_width = max_width + 3
        
        # Print in columns
        for i in range(0, len(sorted_industries), columns):
            row = sorted_industries[i:i+columns]
            formatted_row = [f"{industry:<{col_width}}" for industry in row]
            print("".join(formatted_row))
        
        print(f"\n💡 Use search to find specific industries")
    
    def quick_generate(self, industry_name, open_chart=True):
        """Quick generation without interaction"""
        # Find industry (allow partial matches)
        matches = self.search_industries(industry_name, max_results=1)
        
        if not matches:
            print(f"❌ No industry found matching '{industry_name}'")
            return None
        
        # Use the best match
        selected_industry = matches[0][1]
        
        if matches[0][0] != 'exact':
            print(f"🔍 Using closest match: '{selected_industry}' for '{industry_name}'")
        
        # Show details
        self.show_industry_details(selected_industry)
        
        # Generate chart
        chart_path = self.generate_industry_chart(selected_industry)
        
        if chart_path and open_chart:
            webbrowser.open(f'file://{chart_path.absolute()}')
        
        return chart_path


def main():
    """Main function with CLI support"""
    parser = argparse.ArgumentParser(
        description='Industry Fear & Greed Lookup Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python industry_lookup_tool.py                           # Interactive mode
  python industry_lookup_tool.py --industry "Semiconductors"  # Generate specific industry
  python industry_lookup_tool.py --list                    # List all industries
  python industry_lookup_tool.py --search "software"       # Search for industries
  python industry_lookup_tool.py --industry "Banks" --days 90  # 90-day analysis
        """
    )
    
    parser.add_argument('--industry', type=str,
                       help='Industry name to analyze (supports partial matching)')
    parser.add_argument('--search', type=str,
                       help='Search for industries matching this term')
    parser.add_argument('--list', action='store_true',
                       help='List all available industries')
    parser.add_argument('--days', type=int, default=180,
                       help='Number of days to analyze (default: 180)')
    parser.add_argument('--no-browser', action='store_true',
                       help='Don\'t open browser automatically')
    parser.add_argument('--output-dir', type=str,
                       help='Custom output directory')
    
    args = parser.parse_args()
    
    # Initialize lookup tool
    lookup = IndustryLookup(period_days=args.days)
    
    # Set custom output directory if specified
    if args.output_dir:
        lookup.output_dir = Path(args.output_dir)
        lookup.output_dir.mkdir(exist_ok=True)
        lookup.analyzer.output_dir = lookup.output_dir
    
    try:
        if args.list:
            # List all industries
            lookup.list_all_industries()
        
        elif args.search:
            # Search for industries
            matches = lookup.search_industries(args.search)
            
            if matches:
                print(f"\n🔍 Found {len(matches)} matches for '{args.search}':")
                print("-" * 50)
                for i, (match_type, industry, score) in enumerate(matches, 1):
                    match_indicator = "🎯" if match_type == 'exact' else "📍" if match_type == 'partial' else "🔍"
                    stock_count = len(INDUSTRY_PEERS[industry])
                    print(f"{i:2d}. {match_indicator} {industry} ({stock_count} stocks)")
            else:
                print(f"❌ No industries found matching '{args.search}'")
        
        elif args.industry:
            # Generate chart for specific industry
            lookup.quick_generate(args.industry, open_chart=not args.no_browser)
        
        else:
            # Interactive mode
            lookup.interactive_search()
        
        print(f"\n✅ Industry lookup completed!")
        
    except KeyboardInterrupt:
        print(f"\n⏹️  Interrupted by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())