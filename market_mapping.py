# Sector to ETF mapping - Standard 11 SPDR Sector ETFs
'''
import yfinance as yf
import pandas as pd

# Load S&P 500 companies (contains tickers + sectors)
SP500_URL = 'https://datahub.io/core/s-and-p-500-companies/r/constituents.csv'
df_sp500 = pd.read_csv(SP500_URL)
'''

SECTOR_ETF_MAP = {
    'Technology': 'XLK',
    'Financial Services': 'XLF',
    'Healthcare': 'XLV',
    'Consumer Cyclical': 'XLY',
    'Industrials': 'XLI',
    'Consumer Defensive': 'XLP',
    'Energy': 'XLE',
    'Utilities': 'XLU',
    'Real Estate': 'XLRE',
    'Basic Materials': 'XLB',
    'Communication Services': 'XLC',
    'Financials': 'XLF',
    'Health Care': 'XLV',
    'Consumer Discretionary': 'XLY',
    'Consumer Staples': 'XLP',
    'Materials': 'XLB'
}

SECTOR_LEADERS = {
    'Technology': ['AAPL', 'MSFT', 'NVDA', 'GOOGL', 'META', 'AMD','AVGO','ORCL','CRM'],
    'Financial Services': ['BRK.B', 'JPM', 'V', 'MA', 'BAC','MS'],
    'Healthcare': ['LLY', 'JNJ', 'UNH', 'MRK', 'ABBV', 'TMO'],
    'Consumer Cyclical': ['AMZN', 'TSLA', 'HD', 'MCD', 'NKE', 'LOW','SBUX'],
    'Industrials': ['CAT', 'UNP', 'HON', 'BA', 'LMT', 'RTX','GE','UPS','HON'],
    'Consumer Defensive': ['WMT', 'PG', 'KO', 'PM','PEP', 'COST','CL'],
    'Energy': ['XOM', 'CVX', 'COP', 'SLB', 'EOG','BP','MPC'],
    'Utilities': ['NEE', 'DUK', 'SO', 'D', 'AEP','SRE'],
    'Real Estate': ['AMT', 'PLD', 'CCI', 'EQIX', 'PSA','SPG'],
    'Basic Materials': ['LIN', 'SHW', 'APD', 'FCX', 'NEM','DD','ECL'],
    'Communication Services': ['T', 'VZ', 'AZ', 'DIS', 'NFLX', 'CMCSA']
}

'''
SECTOR_LEADERS = {}
for sector, group in df_sp500.groupby('Sector'):
    tickers = group['Symbol'].tolist()
    market_caps = {}
    for ticker in tickers:
        try:
            info = yf.Ticker(ticker).info
            market_cap = info.get('marketCap', None)
            if market_cap:
                market_caps[ticker] = market_cap
        except:
            continue
    # Sort tickers in this sector by market cap descending
    top_tickers = sorted(market_caps.items(), key=lambda x: x[1], reverse=True)[:8]
    SECTOR_LEADERS[sector] = [ticker for ticker, cap in top_tickers]
for sector, leaders in SECTOR_LEADERS.items():
    print(f"{sector}: {leaders}")
'''

INDUSTRY_PEERS = {
    # Technology Sector
    'Semiconductors': ['NVDA', 'AMD', 'INTC', 'MU', 'TSM', 'QCOM', 'AVGO', 'TXN', 'ADI', 'MRVL', 'NXPI', 'MCHP', 'ON', 'SWKS', 'QRVO'],
    'Software Application': ['MSFT', 'CRM', 'ADBE', 'NOW', 'INTU', 'WDAY', 'PANW', 'CRWD', 'ZM', 'TEAM', 'DOCU', 'ZS', 'OKTA', 'SNOW', 'DDOG'],
    'Software Infrastructure': ['ORCL', 'VMW', 'MSFT', 'PLTR', 'NET', 'MDB', 'ESTC', 'SPLK', 'FSLY', 'CFLT'],
    'Internet Content & Information': ['GOOGL', 'META', 'NFLX', 'SNAP', 'PINS', 'TWTR', 'SPOT', 'MTCH', 'ZG', 'YELP'],
    'Consumer Electronics': ['AAPL', 'SONY', 'SONO', 'GPRO', 'ROKU', 'VZIO', 'KOSS', 'HEAR', 'VUZI'],
    'Computer Hardware': ['DELL', 'HPE', 'HPQ', 'NTAP', 'PSTG', 'WDC', 'STX', 'LOGI', 'SMCI', 'ANET'],
    'Electronic Components': ['APH', 'TEL', 'GLW', 'JBL', 'FLEX', 'CLS', 'PLXS', 'SANM', 'VICR'],
    'Communication Equipment': ['CSCO', 'ANET', 'JNPR', 'CIEN', 'COMM', 'LITE', 'INFN', 'RBBN', 'GILT'],
    'Information Technology Services': ['IBM', 'ACN', 'CTSH', 'INFY', 'WIT', 'EPAM', 'GLOB', 'FIS', 'FISV'],
    'Solar': ['ENPH', 'SEDG', 'FSLR', 'RUN', 'SPWR', 'CSIQ', 'JKS', 'NOVA', 'MAXN', 'SOL'],
    'Scientific & Technical Instruments': ['TMO', 'DHR', 'A', 'ILMN', 'WAT', 'KEYS', 'TRMB', 'GRMN', 'COHR'],
    
    # Financial Services Sector
    'Banks—Regional': ['JPM', 'BAC', 'WFC', 'USB', 'PNC', 'TFC', 'FHN', 'KEY', 'RF', 'CFG', 'HBAN', 'CMA', 'ZION', 'WTFC'],
    'Banks—Diversified': ['C', 'BCS', 'HSBC', 'DB', 'ING', 'SAN', 'SMFG', 'MUFG', 'KB', 'SHG'],
    'Asset Management': ['BLK', 'BX', 'KKR', 'APO', 'ARES', 'CG', 'OWL', 'HLNE', 'STEP', 'AMG'],
    'Capital Markets': ['GS', 'MS', 'SCHW', 'COIN', 'HOOD', 'IBKR', 'SF', 'LPLA', 'RJF', 'VIRT'],
    'Insurance—Property & Casualty': ['BRK.B', 'CB', 'TRV', 'ALL', 'PGR', 'AIG', 'HIG', 'CINF', 'WRB', 'RLI'],
    'Insurance—Life': ['PRU', 'MET', 'PFG', 'LNC', 'VOYA', 'RGA', 'BHF', 'CNO', 'GL', 'AEL'],
    'Insurance—Diversified': ['AIG', 'MFC', 'SLF', 'AFL', 'GNW', 'KMPR', 'THG', 'UFCS', 'PIH'],
    'Financial Data & Stock Exchanges': ['CME', 'ICE', 'NDAQ', 'CBOE', 'MSCI', 'SPGI', 'MCO', 'TRU', 'MKTX'],
    'Credit Services': ['V', 'MA', 'AXP', 'DFS', 'COF', 'SYF', 'ALLY', 'CACC', 'WU', 'PYPL'],
    'Insurance Brokers': ['MMC', 'AON', 'WTW', 'AJG', 'BRO', 'ACGL', 'RYAN', 'ERIE', 'GSHD'],
    'Mortgage Finance': ['RKT', 'UWMC', 'COOP', 'PFSI', 'GHLD', 'HMPT', 'TREE', 'LDI', 'OPEN'],
    
    # Healthcare Sector
    'Drug Manufacturers—General': ['JNJ', 'PFE', 'MRK', 'ABBV', 'BMY', 'AZN', 'NVS', 'GSK', 'SNY', 'NVO'],
    'Drug Manufacturers—Specialty & Generic': ['ZTS', 'CTLT', 'JAZZ', 'VTRS', 'TEVA', 'MYL', 'PRGO', 'ENDP', 'AMRX'],
    'Biotechnology': ['AMGN', 'GILD', 'VRTX', 'REGN', 'MRNA', 'BIIB', 'ILMN', 'ALNY', 'BMRN', 'SGEN'],
    'Medical Devices': ['ABT', 'MDT', 'TMO', 'DHR', 'SYK', 'BSX', 'ISRG', 'BDX', 'EW', 'ZBH'],
    'Medical Instruments & Supplies': ['DXCM', 'ALGN', 'HOLX', 'PODD', 'TFX', 'RMD', 'NVCR', 'NEOG', 'ICUI'],
    'Healthcare Plans': ['UNH', 'ELV', 'CI', 'HUM', 'CVS', 'CNC', 'MOH', 'OSCR', 'ALHC', 'CLOV'],
    'Medical Care Facilities': ['HCA', 'THC', 'UHS', 'CHE', 'DVA', 'ENSG', 'USPH', 'AMED', 'EHAB'],
    'Diagnostics & Research': ['LH', 'DGX', 'TECH', 'PKI', 'CRL', 'MEDP', 'ICLR', 'QGEN', 'EXAS'],
    'Medical Distribution': ['MCK', 'CAH', 'ABC', 'COR', 'HSIC', 'PDCO', 'OMI', 'WOOF', 'PETQ'],
    'Health Information Services': ['VEEV', 'TDOC', 'DOCS', 'HIMS', 'ONEM', 'CRNX', 'PHIN', 'TMDX', 'ACCD'],
    'Pharmaceutical Retailers': ['CVS', 'WBA', 'RAD', 'PETS', 'GNC', 'HITI', 'BODY', 'IMTE', 'DRUG'],
    
    # Consumer Cyclical Sector
    'Internet Retail': ['AMZN', 'EBAY', 'ETSY', 'CHWY', 'W', 'RVLV', 'OSTK', 'FTCH', 'REAL', 'WISH'],
    'Specialty Retail': ['HD', 'LOW', 'TJX', 'ROST', 'BBY', 'AZO', 'ORLY', 'TSCO', 'DKS', 'ULTA'],
    'Apparel Retail': ['GPS', 'ANF', 'AEO', 'URBN', 'CHS', 'PLCE', 'CATO', 'ZUMZ', 'EXPR', 'TLYS'],
    'Home Improvement Retail': ['HD', 'LOW', 'FND', 'BLDR', 'BECN', 'GMS', 'IBP', 'PGTI', 'AZEK'],
    'Auto Manufacturers': ['TSLA', 'F', 'GM', 'TM', 'HMC', 'RACE', 'STLA', 'VOW3', 'BMW', 'RIVN'],
    'Auto Parts': ['APTV', 'BWA', 'LEA', 'MGA', 'GNTX', 'ALV', 'DAN', 'ADNT', 'FOXF', 'MPAA'],
    'Restaurants': ['MCD', 'SBUX', 'CMG', 'YUM', 'DPZ', 'QSR', 'DRI', 'TXRH', 'WING', 'SHAK'],
    'Travel Services': ['BKNG', 'EXPE', 'ABNB', 'TRIP', 'TCOM', 'MMYT', 'DESP', 'TZOO', 'SABR'],
    'Resorts & Casinos': ['LVS', 'WYNN', 'MGM', 'CZR', 'PENN', 'DKNG', 'BYD', 'RRR', 'MCRI', 'FLL'],
    'Leisure': ['DIS', 'NCLH', 'RCL', 'CCL', 'MAR', 'HLT', 'H', 'PLNT', 'VICI', 'MTN'],
    'Apparel Manufacturing': ['NKE', 'LULU', 'VFC', 'UAA', 'PVH', 'RL', 'COLM', 'SKX', 'CROX', 'GOOS'],
    'Footwear & Accessories': ['NKE', 'DECK', 'CROX', 'WWW', 'BOOT', 'RCKY', 'SHOO', 'WEYS', 'SQBG'],
    'Packaging & Containers': ['AMCR', 'CCK', 'BERY', 'SEE', 'ATR', 'SON', 'SLGN', 'GPK', 'PKG'],
    'Personal Services': ['SCI', 'CSV', 'CPRT', 'ROL', 'ABM', 'MMS', 'ARMK', 'CTAS', 'BFAM'],
    'Residential Construction': ['DHI', 'LEN', 'NVR', 'PHM', 'TOL', 'KBH', 'MTH', 'TPH', 'MHO', 'CCS'],
    'Textile Manufacturing': ['CULP', 'DXYN', 'LAKE', 'NVST', 'UFI', 'CTT', 'FORD', 'AIN', 'TXT'],
    'Department Stores': ['M', 'JWN', 'KSS', 'DDS', 'BURL', 'BIG', 'HIBB', 'ZUMZ', 'SCVL'],
    'Luxury Goods': ['EL', 'TPR', 'CPRI', 'MOV', 'FOSL', 'GIII', 'JEWL', 'SIG', 'DIAM'],
    'Furnishings, Fixtures & Appliances': ['WHR', 'MLKN', 'SNBR', 'HELE', 'LOVE', 'ETD', 'FLXS', 'KIRK'],
    
    # Industrials Sector
    'Aerospace & Defense': ['BA', 'LMT', 'RTX', 'NOC', 'GD', 'TDG', 'TXT', 'HWM', 'HII', 'SPR'],
    'Airlines': ['DAL', 'UAL', 'LUV', 'AAL', 'ALK', 'JBLU', 'SAVE', 'HA', 'MESA', 'RJET'],
    'Railroads': ['UNP', 'CSX', 'NSC', 'CP', 'CNI', 'KSU', 'WAB', 'TRN', 'RAIL', 'GBX'],
    'Trucking': ['ODFL', 'JBHT', 'XPO', 'SAIA', 'CHRW', 'LSTR', 'WERN', 'KNX', 'ARCB', 'MRTN'],
    'Integrated Freight & Logistics': ['UPS', 'FDX', 'EXPD', 'HUBG', 'FWRD', 'GXO', 'RXO', 'UHAL', 'ECHO'],
    'Farm & Heavy Construction Machinery': ['CAT', 'DE', 'AGCO', 'CNH', 'TEX', 'MTW', 'OSK', 'HY', 'PCAR'],
    'Industrial Distribution': ['FAST', 'GWW', 'AIT', 'MSM', 'WSO', 'DXPE', 'PKOH', 'LAWX', 'SITE'],
    'Business Equipment & Supplies': ['ZBRA', 'NCR', 'DBD', 'GTLS', 'NDSN', 'BLDP', 'PLUG', 'FCEL', 'HYSR'],
    'Specialty Industrial Machinery': ['AME', 'ITW', 'DHR', 'ROP', 'DOV', 'XYL', 'IEX', 'MIDD', 'GTEC'],
    'Engineering & Construction': ['ACM', 'EME', 'PWR', 'FLR', 'GVA', 'ROAD', 'STRL', 'MTRX', 'IEA'],
    'Infrastructure Operations': ['TTEK', 'BIP', 'BEPC', 'AM', 'VRRM', 'AZEK', 'TILE', 'JELD', 'ROCK'],
    'Building Products & Equipment': ['MAS', 'BLDR', 'OC', 'TREX', 'LII', 'CSL', 'NX', 'DOOR', 'PATK'],
    'Conglomerates': ['BRK.B', 'MMM', 'GE', 'HON', 'ITW', 'DHR', 'ROP', 'BAH', 'HEI', 'TDY'],
    'Consulting Services': ['ACN', 'BAH', 'CACI', 'SAIC', 'KBR', 'ICF', 'HURN', 'FORR', 'RGP'],
    'Electrical Equipment & Parts': ['EMR', 'ETN', 'ROK', 'GNRC', 'HUBB', 'AYI', 'ENS', 'VICR', 'WIRE'],
    'Pollution & Treatment Controls': ['RSG', 'WM', 'WCN', 'SRCL', 'CLH', 'MEG', 'CECO', 'HCCI', 'ADES'],
    'Security & Protection Services': ['LHX', 'FTNT', 'RPD', 'BRC', 'BCO', 'NSSC', 'DGLY', 'MARK', 'VSSV'],
    'Staffing & Employment Services': ['RHI', 'KELYA', 'KELYB', 'MAN', 'TBI', 'HSII', 'BBSI', 'JOBS', 'DHX'],
    'Tools & Accessories': ['SWK', 'SNA', 'LECO', 'KMT', 'ATI', 'CRS', 'SHYF', 'TWIN', 'XONE'],
    'Waste Management': ['WM', 'RSG', 'CWST', 'ECOL', 'CLH', 'ADSW', 'HCCI', 'PCT', 'DSNY'],
    'Marine Shipping': ['ZIM', 'MATX', 'KEX', 'GOGL', 'SBLK', 'EGLE', 'DSX', 'EDRY', 'GLBS'],
    'Metal Fabrication': ['VMI', 'RYI', 'CMCO', 'HAYN', 'CRS', 'NWPX', 'TRS', 'MEC', 'IIIN'],
    'Rental & Leasing Services': ['URI', 'AL', 'R', 'WLFC', 'EHTH', 'MGRC', 'HEES', 'RAMP', 'FTAI'],
    
    # Consumer Defensive Sector
    'Packaged Foods': ['MDLZ', 'GIS', 'K', 'CAG', 'CPB', 'HRL', 'MKC', 'SJM', 'POST', 'LANC'],
    'Beverages—Non-Alcoholic': ['KO', 'PEP', 'MNST', 'KDP', 'CELH', 'FIZZ', 'CCEP', 'PRMW', 'SHOT'],
    'Beverages—Wineries & Distilleries': ['STZ', 'DEO', 'BF.B', 'MGPI', 'VINO', 'VINE', 'EAST', 'WVVI'],
    'Beverages—Brewers': ['BUD', 'TAP', 'SAM', 'HEINY', 'BREW', 'ABEV', 'CCU', 'FMX', 'HOOK'],
    'Confectioners': ['HSY', 'MDLZ', 'TR', 'RMCF', 'COCO', 'STKL', 'CANDY', 'JBSS', 'LWAY'],
    'Farm Products': ['ADM', 'BG', 'DOLE', 'FDP', 'CALM', 'VITL', 'LMNR', 'ALCO', 'VFF'],
    'Household & Personal Products': ['PG', 'CL', 'KMB', 'CHD', 'CLX', 'EPC', 'SPB', 'ENR', 'COTY'],
    'Discount Stores': ['WMT', 'TGT', 'COST', 'DG', 'DLTR', 'BJ', 'PSMT', 'OLLI', 'GO', 'FIVE'],
    'Food Distribution': ['SYY', 'PFGC', 'USFD', 'CHEF', 'SPTN', 'UNFI', 'SENEA', 'WILC', 'JBSS'],
    'Grocery Stores': ['KR', 'ACI', 'SFM', 'NGVC', 'GO', 'IMKTA', 'WMK', 'VLGEA', 'ASAI'],
    'Tobacco': ['PM', 'MO', 'BTI', 'UVV', 'VGR', 'XXII', 'RLX', 'KAVL', 'GNLN'],
    'Education & Training Services': ['CHGG', 'ATGE', 'ARCE', 'LOPE', 'STRA', 'PRDO', 'UTI', 'LAUR', 'HMHC'],
    'Packaged Foods & Meats': ['TSN', 'HRL', 'SAFM', 'PPC', 'LW', 'BRFS', 'CHEF', 'SENEA', 'PORK'],
    
    # Energy Sector
    'Oil & Gas E&P': ['XOM', 'CVX', 'COP', 'EOG', 'OXY', 'PXD', 'HES', 'DVN', 'FANG', 'MRO'],
    'Oil & Gas Integrated': ['XOM', 'CVX', 'SHEL', 'BP', 'TTE', 'ENB', 'SU', 'E', 'EC', 'YPF'],
    'Oil & Gas Midstream': ['KMI', 'WMB', 'OKE', 'ET', 'EPD', 'MMP', 'MPLX', 'PAA', 'WES', 'DCP'],
    'Oil & Gas Refining & Marketing': ['MPC', 'PSX', 'VLO', 'PBF', 'DK', 'CVI', 'PARR', 'CAPL', 'CLMT'],
    'Oil & Gas Equipment & Services': ['SLB', 'HAL', 'BKR', 'FTI', 'NOV', 'CHX', 'WHD', 'LBRT', 'HP'],
    'Oil & Gas Drilling': ['RIG', 'VAL', 'DO', 'SDRL', 'BORR', 'WTTR', 'GLBL', 'PACD', 'TTI'],
    'Thermal Coal': ['BTU', 'ARCH', 'AMR', 'ARLP', 'CEIX', 'HCC', 'METC', 'NC', 'SXC'],
    'Uranium': ['CCJ', 'UUUU', 'UEC', 'DNN', 'LEU', 'URG', 'LTBR', 'FCUUF', 'NXE'],
    
    # Utilities Sector
    'Utilities—Regulated Electric': ['NEE', 'DUK', 'SO', 'D', 'AEP', 'EXC', 'SRE', 'XEL', 'ED', 'PCG'],
    'Utilities—Regulated Gas': ['ATO', 'NI', 'OGE', 'NFG', 'NJR', 'SWX', 'SR', 'NWN', 'OGS', 'SPH'],
    'Utilities—Regulated Water': ['AWK', 'WTR', 'AWR', 'CWT', 'SJW', 'MSEX', 'ARTNA', 'YORW', 'GWRS'],
    'Utilities—Renewable': ['NEP', 'BEP', 'AY', 'CWEN', 'EVA', 'TAC', 'NOVA', 'TERP', 'PEGI'],
    'Utilities—Independent Power Producers': ['VST', 'CEG', 'NRG', 'CLNE', 'REGI', 'NABL', 'AMTX', 'FF'],
    'Utilities—Diversified': ['ES', 'ETR', 'CMS', 'DTE', 'WEC', 'AEE', 'LNT', 'EVRG', 'CNP', 'PNW'],
    
    # Real Estate Sector
    'REIT—Residential': ['AVB', 'EQR', 'ESS', 'MAA', 'UDR', 'CPT', 'AIV', 'INVH', 'AMH', 'NXRT'],
    'REIT—Retail': ['SPG', 'O', 'REG', 'FRT', 'KIM', 'BRX', 'MAC', 'SKT', 'WPG', 'CBL'],
    'REIT—Industrial': ['PLD', 'DRE', 'FR', 'EGP', 'STAG', 'COLD', 'REXR', 'IIPR', 'PLYM', 'LPT'],
    'REIT—Office': ['BXP', 'VNO', 'KRC', 'HIW', 'DEI', 'PDM', 'WRE', 'CUZ', 'OFC', 'FSP'],
    'REIT—Healthcare Facilities': ['WELL', 'PEAK', 'VTR', 'OHI', 'HR', 'DOC', 'CTRE', 'CHCT', 'SBRA', 'LTC'],
    'REIT—Hotel & Motel': ['HST', 'RHP', 'PK', 'APLE', 'PEB', 'DRH', 'SHO', 'XHR', 'BHR', 'INN'],
    'REIT—Diversified': ['CONE', 'WPC', 'NLOP', 'ALEX', 'VER', 'EPRT', 'PINE', 'SRC', 'FCPT', 'GTY'],
    'REIT—Specialty': ['AMT', 'CCI', 'EQIX', 'DLR', 'SBAC', 'PSA', 'EXR', 'CUBE', 'LSI', 'NSA'],
    'REIT—Mortgage': ['AGNC', 'STWD', 'BXMT', 'ABR', 'TWO', 'NLY', 'ARR', 'RITM', 'RC', 'KREF'],
    'Real Estate Services': ['CBRE', 'JLL', 'CWK', 'CIGI', 'NMRK', 'COMP', 'RDFN', 'OPEN', 'Z', 'ZG'],
    'Real Estate—Development': ['HASI', 'AKR', 'HHC', 'FOR', 'MLP', 'FRPH', 'TCCO', 'DFIN', 'PAXS'],
    'Real Estate—Diversified': ['KW', 'NEN', 'CLPR', 'AAT', 'FOR', 'HASI', 'FPI', 'BRT', 'GOOD'],
    
    # Basic Materials Sector
    'Chemicals': ['LIN', 'APD', 'SHW', 'DD', 'DOW', 'PPG', 'LYB', 'ECL', 'ALB', 'FMC'],
    'Specialty Chemicals': ['SHW', 'PPG', 'ALB', 'IFF', 'CE', 'CBT', 'GCP', 'KOP', 'TROX', 'HWKN'],
    'Agricultural Inputs': ['NTR', 'MOS', 'CF', 'FMC', 'CTVA', 'SMG', 'IPI', 'UAN', 'REZI', 'MBII'],
    'Aluminum': ['AA', 'CENX', 'KALU', 'NTIC', 'ALUAF', 'NCLH', 'TG', 'ATI', 'AMPCO'],
    'Building Materials': ['VMC', 'MLM', 'CX', 'EXP', 'USCR', 'ASTE', 'MDU', 'SUM', 'CALX', 'HCMLY'],
    'Copper': ['FCX', 'SCCO', 'TECK', 'TRQ', 'CPMC', 'CMMC', 'AMLP', 'NFGC', 'TGB'],
    'Gold': ['NEM', 'GOLD', 'AEM', 'KGC', 'AU', 'AGI', 'HMY', 'EGO', 'SSRM', 'PAAS'],
    'Industrial Metals & Minerals': ['RIO', 'BHP', 'VALE', 'VEDL', 'MT', 'NWPX', 'HAYN', 'SXC', 'TMST'],
    'Paper & Paper Products': ['IP', 'WRK', 'PKG', 'SON', 'SEE', 'GPK', 'KS', 'CLW', 'MERC'],
    'Silver': ['PAAS', 'CDE', 'HL', 'SSRM', 'EXK', 'FSM', 'AG', 'MAG', 'SILV', 'ASM'],
    'Steel': ['NUE', 'STLD', 'CLF', 'X', 'RS', 'MT', 'TX', 'CMC', 'ASTL', 'ZEUS'],
    'Other Industrial Metals & Mining': ['RIO', 'BHP', 'VALE', 'TECK', 'SBSW', 'MP', 'LAC', 'LI', 'ALB'],
    'Other Precious Metals & Mining': ['SBSW', 'PLG', 'IMPUY', 'ANGPY', 'NILSY', 'AGPPY', 'ANFGF', 'GLCNF'],
    'Coking Coal': ['BTU', 'ARCH', 'AMR', 'METC', 'HCC', 'SXC', 'ARLP', 'CEIX', 'HNRG'],
    'Lumber & Wood Production': ['WY', 'PCH', 'RYN', 'UFPI', 'BLDR', 'LPX', 'OSB', 'DHI', 'TOL'],
    
    # Communication Services Sector
    'Internet Content & Information': ['GOOGL', 'META', 'NFLX', 'SNAP', 'PINS', 'SPOT', 'Z', 'YELP', 'TRIP'],
    'Entertainment': ['DIS', 'WBD', 'PARA', 'CMCSA', 'LYV', 'MSGS', 'WWE', 'EDR', 'CHTR'],
    'Telecom Services': ['T', 'VZ', 'TMUS', 'VOD', 'ORAN', 'TEF', 'TU', 'BCE', 'LUMN', 'USM'],
    'Advertising Agencies': ['OMC', 'IPG', 'WPP', 'PUBM', 'MDC', 'STGW', 'MGNI', 'CRTO', 'APPS'],
    'Broadcasting': ['FOX', 'FOXA', 'NXST', 'SBGI', 'GTN', 'TGNA', 'GCI', 'EVC', 'SSP'],
    'Electronic Gaming & Multimedia': ['EA', 'TTWO', 'ATVI', 'RBLX', 'U', 'GLUU', 'ZNGA', 'PLTK', 'GMBL'],
    'Publishing': ['NYT', 'NWSA', 'NWS', 'SCHL', 'PSO', 'LEE', 'MDP', 'GCI', 'DLX'],
    'Telecom Services—Domestic': ['T', 'VZ', 'TMUS', 'LUMN', 'FYBR', 'SHEN', 'TDS', 'ATNI', 'CBB'],

    'REIT—Hotel & Motel': ['HST', 'RHP', 'PK', 'APLE', 'PEB', 'DRH', 'SHO', 'XHR', 'BHR', 'INN'],
    'REIT—Diversified': ['CONE', 'WPC', 'NLOP', 'ALEX', 'VER', 'EPRT', 'PINE', 'SRC', 'FCPT', 'GTY'],
    'REIT—Specialty': ['AMT', 'CCI', 'EQIX', 'DLR', 'SBAC', 'PSA', 'EXR', 'CUBE', 'LSI', 'NSA'],
    'REIT—Mortgage': ['AGNC', 'STWD', 'BXMT', 'ABR', 'TWO', 'NLY', 'ARR', 'RITM', 'RC', 'KREF'],
    'Real Estate Services': ['CBRE', 'JLL', 'CWK', 'CIGI', 'NMRK', 'COMP', 'RDFN', 'OPEN', 'Z', 'ZG'],
    'Real Estate—Development': ['HASI', 'AKR', 'HHC', 'FOR', 'MLP', 'FRPH', 'TCCO', 'DFIN', 'PAXS'],
    'Real Estate—Diversified': ['KW', 'NEN', 'CLPR', 'AAT', 'FOR', 'HASI', 'FPI', 'BRT', 'GOOD'],
    
    # Basic Materials Sector
    'Chemicals': ['LIN', 'APD', 'SHW', 'DD', 'DOW', 'PPG', 'LYB', 'ECL', 'ALB', 'FMC'],
    'Specialty Chemicals': ['SHW', 'PPG', 'ALB', 'IFF', 'CE', 'CBT', 'GCP', 'KOP', 'TROX', 'HWKN'],
    'Agricultural Inputs': ['NTR', 'MOS', 'CF', 'FMC', 'CTVA', 'SMG', 'IPI', 'UAN', 'REZI', 'MBII'],
    'Aluminum': ['AA', 'CENX', 'KALU', 'NTIC', 'ALUAF', 'NCLH', 'TG', 'ATI', 'AMPCO'],
    'Building Materials': ['VMC', 'MLM', 'CX', 'EXP', 'USCR', 'ASTE', 'MDU', 'SUM', 'CALX', 'HCMLY'],
    'Copper': ['FCX', 'SCCO', 'TECK', 'TRQ', 'CPMC', 'CMMC', 'AMLP', 'NFGC', 'TGB'],
    'Gold': ['NEM', 'GOLD', 'AEM', 'KGC', 'AU', 'AGI', 'HMY', 'EGO', 'SSRM', 'PAAS'],
    'Industrial Metals & Minerals': ['RIO', 'BHP', 'VALE', 'VEDL', 'MT', 'NWPX', 'HAYN', 'SXC', 'TMST'],
    'Paper & Paper Products': ['IP', 'WRK', 'PKG', 'SON', 'SEE', 'GPK', 'KS', 'CLW', 'MERC'],
    'Silver': ['PAAS', 'CDE', 'HL', 'SSRM', 'EXK', 'FSM', 'AG', 'MAG', 'SILV', 'ASM'],
    'Steel': ['NUE', 'STLD', 'CLF', 'X', 'RS', 'MT', 'TX', 'CMC', 'ASTL', 'ZEUS'],
    'Other Industrial Metals & Mining': ['RIO', 'BHP', 'VALE', 'TECK', 'SBSW', 'MP', 'LAC', 'LI', 'ALB'],
    'Other Precious Metals & Mining': ['SBSW', 'PLG', 'IMPUY', 'ANGPY', 'NILSY', 'AGPPY', 'ANFGF', 'GLCNF'],
    'Coking Coal': ['BTU', 'ARCH', 'AMR', 'METC', 'HCC', 'SXC', 'ARLP', 'CEIX', 'HNRG'],
    'Lumber & Wood Production': ['WY', 'PCH', 'RYN', 'UFPI', 'BLDR', 'LPX', 'OSB', 'DHI', 'TOL'],
    
    # Communication Services Sector
    'Internet Content & Information': ['GOOGL', 'META', 'NFLX', 'SNAP', 'PINS', 'SPOT', 'Z', 'YELP', 'TRIP'],
    'Entertainment': ['DIS', 'WBD', 'PARA', 'CMCSA', 'LYV', 'MSGS', 'WWE', 'EDR', 'CHTR'],
    'Telecom Services': ['T', 'VZ', 'TMUS', 'VOD', 'ORAN', 'TEF', 'TU', 'BCE', 'LUMN', 'USM'],
    'Advertising Agencies': ['OMC', 'IPG', 'WPP', 'PUBM', 'MDC', 'STGW', 'MGNI', 'CRTO', 'APPS'],
    'Broadcasting': ['FOX', 'FOXA', 'NXST', 'SBGI', 'GTN', 'TGNA', 'GCI', 'EVC', 'SSP'],
    'Electronic Gaming & Multimedia': ['EA', 'TTWO', 'ATVI', 'RBLX', 'U', 'GLUU', 'ZNGA', 'PLTK', 'GMBL'],
    'Publishing': ['NYT', 'NWSA', 'NWS', 'SCHL', 'PSO', 'LEE', 'MDP', 'GCI', 'DLX'],
    'Telecom Services—Domestic': ['T', 'VZ', 'TMUS', 'LUMN', 'FYBR', 'SHEN', 'TDS', 'ATNI', 'CBB']
}

# Additional market indices and their ETFs
MARKET_INDICES = {
    'S&P 500': 'SPY',
    'Nasdaq 100': 'QQQ',
    'Dow Jones': 'DIA',
    'Russell 2000': 'IWM',
    'VIX': 'VXX',
    'Total Market': 'VTI',
    'International': 'EFA',
    'Emerging Markets': 'EEM',
    'Bonds': 'AGG',
    'Gold': 'GLD',
    'Oil': 'USO',
    'Bitcoin': 'BITO'
}