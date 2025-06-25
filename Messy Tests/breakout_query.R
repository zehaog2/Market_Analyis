# Breakout Detection Functions for US Non-Dividend Stocks
# Assumes data frame with columns: Date, Open, High, Low, Close, Volume

library(TTR)
library(dplyr)
library(quantmod)
library(stringr)

# 0. Stock Universe Filtering
get_us_stock_universe <- function(use_quantmod = TRUE, min_price = 5, min_volume = 100000) {
  
  if (use_quantmod) {
    # Method 1: Try to get stock lists from APIs
    nasdaq_symbols <- NULL
    nyse_symbols <- NULL
    
    # Try NASDAQ API
    tryCatch({
      nasdaq_url <- "https://www.nasdaq.com/api/screener/stocks?tableonly=true&limit=25000&offset=0"
      nasdaq_data <- jsonlite::fromJSON(nasdaq_url)$data
      nasdaq_symbols <- nasdaq_data$symbol
      cat("Successfully retrieved", length(nasdaq_symbols), "NASDAQ symbols\n")
    }, error = function(e) {
      cat("ERROR: Failed to retrieve NASDAQ symbols:", e$message, "\n")
    })
    
    # Try NYSE API
    tryCatch({
      nyse_url <- "https://www.nasdaq.com/api/screener/stocks?tableonly=true&limit=25000&offset=0&exchange=NYSE"
      nyse_data <- jsonlite::fromJSON(nyse_url)$data
      nyse_symbols <- nyse_data$symbol
      cat("Successfully retrieved", length(nyse_symbols), "NYSE symbols\n")
    }, error = function(e) {
      cat("ERROR: Failed to retrieve NYSE symbols:", e$message, "\n")
    })
    
    # Check if we got data from APIs
    if (is.null(nasdaq_symbols) && is.null(nyse_symbols)) {
      stop("ERROR: Failed to retrieve stock symbols from both NASDAQ and NYSE APIs. 
           Please check your internet connection or try again later.
           You may need to use a different data source or API.")
    }
    
    # Combine available symbols
    all_symbols <- unique(c(nasdaq_symbols, nyse_symbols))
    
    if (length(all_symbols) == 0) {
      stop("ERROR: No stock symbols retrieved from APIs.")
    }
    
    return(all_symbols)
    
  } else {
    stop("ERROR: use_quantmod is set to FALSE. Please set use_quantmod = TRUE to retrieve stock symbols from APIs.")
  }
}

filter_stock_universe <- function(symbols, get_company_names = TRUE) {
  
  # Define exclusion patterns
  exclusion_patterns <- c(
    "Bond", "ETF", "Fund", "Treasury", "Index", "Acquisition", 
    "pharma", "therap", "REIT", "Trust", "Preferred", "Warrant",
    "Unit", "Rights", "Note", "Debt"
  )
  
  if (get_company_names) {
    # Try to get company names for filtering
    filtered_symbols <- c()
    
    for (symbol in symbols) {
      tryCatch({
        # Try to get company info
        company_info <- try(getQuote(symbol), silent = TRUE)
        
        if (class(company_info) != "try-error") {
          company_name <- rownames(company_info)[1]
          
          # Check if name contains exclusion patterns
          exclude <- any(sapply(exclusion_patterns, function(pattern) {
            grepl(pattern, company_name, ignore.case = TRUE)
          }))
          
          if (!exclude) {
            filtered_symbols <- c(filtered_symbols, symbol)
          }
        }
      }, error = function(e) {
        # If we can't get info, include symbol (conservative approach)
        filtered_symbols <- c(filtered_symbols, symbol)
      })
    }
  } else {
    # Filter based on symbol patterns only
    filtered_symbols <- symbols[!grepl(paste(exclusion_patterns, collapse = "|"), 
                                       symbols, ignore.case = TRUE)]
  }
  
  return(unique(filtered_symbols))
}

# Alternative: Direct database filtering (if you have a stock database)
filter_stock_database <- function(connection) {
  query <- "
  SELECT symbol, name, sector, market_cap, avg_volume, price
  FROM stocks 
  WHERE country = 'US'
    AND name NOT LIKE '%Bond%'
    AND name NOT LIKE '%ETF%'
    AND name NOT LIKE '%Fund%'
    AND name NOT LIKE '%Treasury%'
    AND name NOT LIKE '%Index%'
    AND name NOT LIKE '%Acquisition%'
    AND name NOT LIKE '%pharma%'
    AND name NOT LIKE '%therap%'
    AND name NOT LIKE '%REIT%'
    AND name NOT LIKE '%Trust%'
    AND name NOT LIKE '%Preferred%'
    AND price >= 5
    AND avg_volume >= 100000
    AND market_cap >= 100000000
  ORDER BY market_cap DESC
  "
  
  # Execute query (uncomment if you have database connection)
  # result <- dbGetQuery(connection, query)
  # return(result$symbol)
  
  return(query)  # Return query for reference
}

# Quick stock screening with basic filters
quick_stock_screen <- function(symbols, min_price = 5, min_volume = 100000, 
                               days_back = 90, exclude_penny = TRUE) {  # Increased days_back
  qualified_stocks <- list()
  
  for (symbol in symbols) {
    tryCatch({
      # Get recent data with more days to ensure we have enough for EMA50
      stock_data <- getSymbols(symbol, src = "yahoo", auto.assign = FALSE,
                               from = Sys.Date() - days_back, to = Sys.Date())
      
      if (!is.null(stock_data) && nrow(stock_data) >= 60) {  # Ensure minimum rows for EMA50
        # Extract OHLCV data
        prices <- as.numeric(Cl(stock_data))
        volumes <- as.numeric(Vo(stock_data))
        
        # Apply filters
        current_price <- tail(prices, 1)
        avg_volume <- mean(volumes, na.rm = TRUE)
        
        # Check criteria
        if (current_price >= min_price && 
            avg_volume >= min_volume &&
            !is.na(current_price) && 
            !is.na(avg_volume)) {
          
          # Convert to data frame format
          df <- data.frame(
            Date = index(stock_data),
            Open = as.numeric(Op(stock_data)),
            High = as.numeric(Hi(stock_data)),
            Low = as.numeric(Lo(stock_data)),
            Close = as.numeric(Cl(stock_data)),
            Volume = as.numeric(Vo(stock_data))
          )
          
          qualified_stocks[[symbol]] <- df
          cat("✓", symbol, "qualified\n")
        } else {
          cat("✗", symbol, "failed basic criteria\n")
        }
      } else {
        cat("✗", symbol, "insufficient data\n")
      }
    }, error = function(e) {
      cat("✗", symbol, "error:", e$message, "\n")
    })
  }
  
  return(qualified_stocks)
}

# 1. Volume Confirmation
volume_breakout_filter <- function(data, volume_multiplier = 1.5, lookback = 20) {
  data$avg_volume <- SMA(data$Volume, n = lookback)
  data$volume_ratio <- data$Volume / data$avg_volume
  data$volume_breakout <- data$volume_ratio >= volume_multiplier
  
  return(data)
}

# 2. Multiple Timeframe Alignment (simplified for daily data)
timeframe_alignment <- function(data, short_ema = 10, medium_ema = 20, long_ema = 50) {
  data$ema_10 <- EMA(data$Close, n = short_ema)
  data$ema_20 <- EMA(data$Close, n = medium_ema)
  data$ema_50 <- EMA(data$Close, n = long_ema)
  
  # Check alignment: EMA10 > EMA20 > EMA50
  data$ema_aligned <- (data$ema_10 > data$ema_20) & (data$ema_20 > data$ema_50)
  
  # Check if EMAs are spreading (strengthening trend)
  data$ema_10_slope <- (data$ema_10 - lag(data$ema_10, 3)) / 3
  data$ema_20_slope <- (data$ema_20 - lag(data$ema_20, 3)) / 3
  
  data$ema_strength <- ifelse(data$ema_aligned, 1, 0) +
    ifelse(data$ema_10_slope > 0, 1, 0) +
    ifelse(data$ema_20_slope > 0, 1, 0)
  
  return(data)
}

# 3. Volatility Expansion (ATR)
volatility_expansion <- function(data, atr_period = 14, expansion_threshold = 1.2) {
  data$atr <- ATR(data[,c("High", "Low", "Close")], n = atr_period)$atr
  data$atr_avg <- SMA(data$atr, n = 20)
  data$atr_expansion <- data$atr > (expansion_threshold * data$atr_avg)
  
  return(data)
}

# 4. Market Structure - Pivot Points and Fibonacci
market_structure_breakout <- function(data, pivot_window = 10, fib_lookback = 50) {
  # Find pivot highs and lows
  data$pivot_high <- rollapply(data$High, width = 2*pivot_window + 1, 
                               FUN = function(x) which.max(x) == pivot_window + 1,
                               fill = FALSE, align = "center")
  
  data$pivot_low <- rollapply(data$Low, width = 2*pivot_window + 1,
                              FUN = function(x) which.min(x) == pivot_window + 1,
                              fill = FALSE, align = "center")
  
  # Get recent high and low for Fibonacci levels
  data$recent_high <- rollapply(data$High, width = fib_lookback, FUN = max, 
                                fill = NA, align = "right")
  data$recent_low <- rollapply(data$Low, width = fib_lookback, FUN = min,
                               fill = NA, align = "right")
  
  # Calculate Fibonacci levels
  data$fib_range <- data$recent_high - data$recent_low
  data$fib_50 <- data$recent_low + 0.5 * data$fib_range
  data$fib_618 <- data$recent_low + 0.618 * data$fib_range
  
  # Check for breakouts above key levels
  data$structure_breakout <- (data$Close > data$recent_high) |
    (data$Close > data$fib_618 & lag(data$Close) <= data$fib_618)
  
  return(data)
}

# 5. Enhanced Momentum Indicators
enhanced_momentum <- function(data, rsi_period = 14, stoch_k = 14, stoch_d = 3) {
  # Standard RSI
  data$rsi <- RSI(data$Close, n = rsi_period)
  
  # Stochastic RSI
  stoch_rsi <- stoch(data[,c("rsi", "rsi", "rsi")], nFastK = stoch_k, nFastD = stoch_d)
  data$stoch_rsi_k <- stoch_rsi[,1]
  data$stoch_rsi_d <- stoch_rsi[,2]
  
  # Williams %R
  data$williams_r <- WPR(data[,c("High", "Low", "Close")], n = 14)
  
  # MACD Histogram
  macd_data <- MACD(data$Close)
  data$macd_histogram <- macd_data[,3]
  data$macd_hist_positive <- data$macd_histogram > 0
  
  # Momentum strength score
  data$momentum_score <- 
    ifelse(data$rsi > 50 & data$rsi < 70, 1, 0) +  # RSI in bullish but not overbought
    ifelse(data$stoch_rsi_k > 20 & data$stoch_rsi_k > data$stoch_rsi_d, 1, 0) +  # Stoch RSI bullish
    ifelse(data$williams_r > -80, 1, 0) +  # Williams %R not oversold
    ifelse(data$macd_hist_positive, 1, 0)  # MACD histogram positive
  
  return(data)
}

# 6. Relative Strength vs Market
relative_strength <- function(stock_data, market_data, rs_period = 20) {
  # Calculate price change ratios
  stock_return <- (stock_data$Close / lag(stock_data$Close, rs_period)) - 1
  market_return <- (market_data$Close / lag(market_data$Close, rs_period)) - 1
  
  stock_data$relative_strength <- stock_return - market_return
  stock_data$rs_positive <- stock_data$relative_strength > 0
  
  # RS rank (percentile over last 60 days)
  stock_data$rs_rank <- rollapply(stock_data$relative_strength, width = 60,
                                  FUN = function(x) percent_rank(x)[length(x)],
                                  fill = NA, align = "right")
  
  return(stock_data)
}

# 7. Master Filter Function
breakout_filter <- function(data, market_data = NULL, 
                            volume_mult = 1.5,
                            atr_expansion = 1.2,
                            min_momentum_score = 2,
                            min_ema_strength = 2,
                            require_structure_breakout = TRUE,
                            min_rs_rank = 0.6) {
  
  # Apply all individual filters
  data <- volume_breakout_filter(data, volume_multiplier = volume_mult)
  data <- timeframe_alignment(data)
  data <- volatility_expansion(data, expansion_threshold = atr_expansion)
  data <- market_structure_breakout(data)
  data <- enhanced_momentum(data)
  
  if (!is.null(market_data)) {
    data <- relative_strength(data, market_data)
  }
  
  # Create master filter
  data$breakout_candidate <- 
    data$volume_breakout &
    (data$ema_strength >= min_ema_strength) &
    data$atr_expansion &
    (data$momentum_score >= min_momentum_score)
  
  if (require_structure_breakout) {
    data$breakout_candidate <- data$breakout_candidate & data$structure_breakout
  }
  
  if (!is.null(market_data) && !is.null(min_rs_rank)) {
    data$breakout_candidate <- data$breakout_candidate & 
      (data$rs_rank >= min_rs_rank | is.na(data$rs_rank))
  }
  
  return(data)
}

# 8. Utility function to screen multiple stocks
screen_breakout_stocks <- function(stock_list, market_data = NULL, ...) {
  
  results <- list()
  
  for (symbol in names(stock_list)) {
    tryCatch({
      filtered_data <- breakout_filter(stock_list[[symbol]], market_data, ...)
      
      # Get latest signals
      latest_signals <- tail(filtered_data, 5)  # Last 5 days
      breakout_signals <- sum(latest_signals$breakout_candidate, na.rm = TRUE)
      
      if (breakout_signals > 0) {
        results[[symbol]] <- list(
          symbol = symbol,
          latest_close = tail(filtered_data$Close, 1),
          breakout_signals = breakout_signals,
          volume_ratio = tail(filtered_data$volume_ratio, 1),
          momentum_score = tail(filtered_data$momentum_score, 1),
          ema_strength = tail(filtered_data$ema_strength, 1),
          rs_rank = ifelse(!is.null(market_data), tail(filtered_data$rs_rank, 1), NA)
        )
      }
    }, error = function(e) {
      cat("Error processing", symbol, ":", e$message, "\n")
    })
  }
  
  return(results)
}

# Master Pipeline: Universe Filtering + Breakout Detection
complete_stock_screening_pipeline <- function(use_quantmod = TRUE, 
                                              min_price = 5,
                                              min_volume = 100000,
                                              days_back = 90,  # Increased for EMA50
                                              # Breakout filter parameters
                                              volume_mult = 1.5,
                                              atr_expansion = 1.2,
                                              min_momentum_score = 2,
                                              min_ema_strength = 2,
                                              require_structure_breakout = TRUE) {
  
  cat("Step 1: Getting US stock universe...\n")
  all_symbols <- get_us_stock_universe(use_quantmod = use_quantmod)
  cat("Found", length(all_symbols), "initial symbols\n")
  
  cat("Step 2: Filtering out unwanted securities...\n")
  filtered_symbols <- filter_stock_universe(all_symbols, get_company_names = FALSE)
  cat("After filtering:", length(filtered_symbols), "symbols remain\n")
  
  cat("Step 3: Screening stocks with basic criteria...\n")
  qualified_stocks <- quick_stock_screen(filtered_symbols, 
                                         min_price = min_price,
                                         min_volume = min_volume,
                                         days_back = days_back)
  cat("After basic screening:", length(qualified_stocks), "stocks qualify\n")
  
  if (length(qualified_stocks) == 0) {
    cat("No stocks passed basic screening. Try lowering criteria.\n")
    return(NULL)
  }
  
  cat("Step 4: Applying breakout filters...\n")
  
  # Get SPY data for relative strength
  spy_data <- try({
    spy <- getSymbols("SPY", src = "yahoo", auto.assign = FALSE,
                      from = Sys.Date() - days_back, to = Sys.Date())
    data.frame(
      Date = index(spy),
      Close = as.numeric(Cl(spy))
    )
  })
  
  if (class(spy_data) == "try-error") {
    spy_data <- NULL
    cat("Could not get SPY data for relative strength analysis\n")
  }
  
  # Apply breakout filters to qualified stocks
  breakout_candidates <- screen_breakout_stocks(
    qualified_stocks, 
    market_data = spy_data,
    volume_mult = volume_mult,
    atr_expansion = atr_expansion,
    min_momentum_score = min_momentum_score,
    min_ema_strength = min_ema_strength,
    require_structure_breakout = require_structure_breakout
  )
  
  cat("Final result:", length(breakout_candidates), "breakout candidates found\n")
  
  return(list(
    all_symbols = all_symbols,
    filtered_symbols = filtered_symbols,
    qualified_stocks = qualified_stocks,
    breakout_candidates = breakout_candidates
  ))
}

# Utility function to display results nicely
display_breakout_results <- function(results) {
  
  if (is.null(results) || length(results$breakout_candidates) == 0) {
    cat("No breakout candidates found.\n")
    return(NULL)
  }
  
  # Convert to data frame for easier viewing
  candidates_df <- do.call(rbind, lapply(names(results$breakout_candidates), function(symbol) {
    candidate <- results$breakout_candidates[[symbol]]
    data.frame(
      Symbol = symbol,
      Price = round(candidate$latest_close, 2),
      Volume_Ratio = round(candidate$volume_ratio, 2),
      Momentum_Score = candidate$momentum_score,
      EMA_Strength = candidate$ema_strength,
      RS_Rank = round(candidate$rs_rank, 3),
      Breakout_Signals = candidate$breakout_signals,
      stringsAsFactors = FALSE
    )
  }))
  
  # Sort by combined score
  candidates_df$Combined_Score <- (candidates_df$Volume_Ratio * 0.3) + 
    (candidates_df$Momentum_Score * 0.3) +
    (candidates_df$EMA_Strength * 0.2) +
    (ifelse(is.na(candidates_df$RS_Rank), 0.5, candidates_df$RS_Rank) * 0.2)
  
  candidates_df <- candidates_df[order(-candidates_df$Combined_Score), ]
  
  cat("\n=== BREAKOUT CANDIDATES ===\n")
  print(candidates_df)
  
  return(candidates_df)
}

# =============================================================================
# HOW TO RUN THE CODE - STEP BY STEP INSTRUCTIONS
# =============================================================================

# STEP 1: Install required packages (run once)
# install.packages(c("TTR", "dplyr", "quantmod", "stringr", "jsonlite"))

# STEP 2: Load the libraries
library(TTR)
library(dplyr)
library(quantmod)
library(stringr)
library(jsonlite)

# STEP 3: Source all the functions above (copy and paste all functions, or save to file and source)
# If you saved to a file called "breakout_functions.R":
# source("breakout_functions.R")

# STEP 4: Run the complete pipeline
cat("Starting stock screening pipeline...\n")

# Basic run with default parameters
results <- complete_stock_screening_pipeline()

# Display the results
candidates <- display_breakout_results(results)

# STEP 5: Test different parameter combinations
cat("\n\n=== TESTING DIFFERENT COMBINATIONS ===\n")

# Conservative approach (fewer but higher quality signals)
cat("\nRunning conservative screening...\n")
conservative_results <- complete_stock_screening_pipeline(
  min_price = 10,
  min_volume = 500000,
  volume_mult = 2.0,
  min_momentum_score = 3,
  min_ema_strength = 3,
  require_structure_breakout = TRUE
)
conservative_candidates <- display_breakout_results(conservative_results)

# Aggressive approach (more candidates, lower thresholds)
cat("\nRunning aggressive screening...\n")
aggressive_results <- complete_stock_screening_pipeline(
  min_price = 5,
  min_volume = 100000,
  volume_mult = 1.2,
  min_momentum_score = 1,
  min_ema_strength = 1,
  require_structure_breakout = FALSE
)
aggressive_candidates <- display_breakout_results(aggressive_results)

# Medium approach (balanced)
cat("\nRunning balanced screening...\n")
balanced_results <- complete_stock_screening_pipeline(
  min_price = 7,
  min_volume = 250000,
  volume_mult = 1.5,
  min_momentum_score = 2,
  min_ema_strength = 2,
  require_structure_breakout = TRUE
)
balanced_candidates <- display_breakout_results(balanced_results)

# STEP 6: Save results to CSV files for further analysis
if (!is.null(conservative_candidates)) {
  write.csv(conservative_candidates, "conservative_breakout_candidates.csv", row.names = FALSE)
  cat("Conservative results saved to conservative_breakout_candidates.csv\n")
}

if (!is.null(aggressive_candidates)) {
  write.csv(aggressive_candidates, "aggressive_breakout_candidates.csv", row.names = FALSE)
  cat("Aggressive results saved to aggressive_breakout_candidates.csv\n")
}

if (!is.null(balanced_candidates)) {
  write.csv(balanced_candidates, "balanced_breakout_candidates.csv", row.names = FALSE)
  cat("Balanced results saved to balanced_breakout_candidates.csv\n")
}

# STEP 7: Analyze individual stocks in detail (optional)
if (!is.null(results$breakout_candidates) && length(results$breakout_candidates) > 0) {
  
  # Get the top candidate for detailed analysis
  top_symbol <- names(results$breakout_candidates)[1]
  cat("\n=== DETAILED ANALYSIS OF TOP CANDIDATE:", top_symbol, "===\n")
  
  # Get the stock data
  top_stock_data <- results$qualified_stocks[[top_symbol]]
  
  if (!is.null(top_stock_data)) {
    # Apply all filters to see detailed breakdown
    detailed_analysis <- breakout_filter(top_stock_data, 
                                         market_data = NULL,  # You can add SPY data here
                                         volume_mult = 1.5,
                                         min_momentum_score = 2)
    
    # Show last 10 days of data with all indicators
    recent_data <- tail(detailed_analysis, 10)
    
    # Select key columns for display
    key_columns <- c("Date", "Close", "Volume", "volume_ratio", "ema_strength", 
                     "momentum_score", "atr_expansion", "breakout_candidate")
    
    if (all(key_columns %in% names(recent_data))) {
      cat("Recent data with indicators:\n")
      print(recent_data[, key_columns])
    }
  }
}

cat("\n=== SCREENING COMPLETE ===\n")
cat("Check the CSV files for detailed results\n")
cat("Modify parameters above to test different combinations\n")