library(methods)
library(quantmod)
library(ggplot2)
library(jsonlite)
library(corrplot)
library(reshape2)
library(TTR)

# Source the advanced correlation functions and PDF report generator
source("advanced_correlation_functions.R")
source("pdf_report_functions.R")

get_data_safe <- function(symbol, start_date, end_date) {
  tryCatch({
    data <- getSymbols(symbol, src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE, warnings = FALSE)
    return(data)
  }, error = function(e) {
    return(NULL)
  })
}

# Updated batch_analysis function with advanced analysis option
batch_analysis <- function(tickers, years_selected, advanced = FALSE) {
  benchmarks <- c("SPY", "QQQ", "USO")
  
  # If advanced analysis is requested, use the advanced function
  if(advanced) {
    cat("=== RUNNING ADVANCED CORRELATION ANALYSIS ===\n")
    results <- batch_advanced_analysis(tickers, years_selected)
    generate_advanced_summary(results)
    
    # Generate PDF report
    pdf_filename <- generate_pdf_report(results, tickers, years_selected)
    cat("\n=== PDF REPORT GENERATED ===\n")
    cat("PDF file:", pdf_filename, "\n")
    
    return(results)
  }
  
  # Original batch analysis code (simplified correlation matrix)
  end_date <- Sys.Date()
  start_date <- end_date - (years_selected * 365)
  
  cat("=== Batch Correlation Analysis ===\n")
  cat("Date range:", as.character(start_date), "to", as.character(end_date), "\n")
  cat("Benchmarks:", paste(benchmarks, collapse = ", "), "\n\n")
  
  # Get benchmark data first
  cat("Fetching benchmark data...\n")
  benchmark_data <- list()
  benchmark_returns <- list()
  
  for(i in 1:length(benchmarks)) {
    cat("  ", benchmarks[i], "...")
    data <- get_data_safe(benchmarks[i], start_date, end_date)
    if(!is.null(data)) {
      benchmark_data[[i]] <- data
      prices <- if(ncol(data) >= 6) Ad(data) else Cl(data)
      benchmark_returns[[i]] <- na.omit(diff(log(prices)))
      cat(" OK\n")
    } else {
      benchmark_data[[i]] <- NULL
      benchmark_returns[[i]] <- NULL
      cat(" FAILED\n")
    }
  }
  
  # Initialize correlation matrix
  correlation_matrix <- matrix(NA, nrow = length(tickers), ncol = length(benchmarks))
  rownames(correlation_matrix) <- tickers
  colnames(correlation_matrix) <- benchmarks
  
  # Process each stock
  cat("\nProcessing stocks...\n")
  valid_stocks <- character(0)
  
  for(i in 1:length(tickers)) {
    ticker <- tickers[i]
    cat(sprintf("  %s (%d/%d)...", ticker, i, length(tickers)))
    
    # Get stock data
    stock_data <- get_data_safe(ticker, start_date, end_date)
    
    if(!is.null(stock_data)) {
      # Calculate stock returns
      stock_prices <- if(ncol(stock_data) >= 6) Ad(stock_data) else Cl(stock_data)
      stock_returns <- na.omit(diff(log(stock_prices)))
      
      # Calculate correlations with each benchmark
      for(j in 1:length(benchmarks)) {
        if(!is.null(benchmark_returns[[j]])) {
          # Find common dates
          common_dates <- intersect(index(stock_returns), index(benchmark_returns[[j]]))
          
          if(length(common_dates) >= 10) {
            stock_aligned <- stock_returns[common_dates]
            benchmark_aligned <- benchmark_returns[[j]][common_dates]
            
            correlation_matrix[i, j] <- cor(as.numeric(stock_aligned), 
                                            as.numeric(benchmark_aligned), 
                                            use = "complete.obs")
          }
        }
      }
      
      valid_stocks <- c(valid_stocks, ticker)
      cat(" OK\n")
    } else {
      cat(" FAILED\n")
    }
  }
  
  # Filter to only valid stocks
  if(length(valid_stocks) == 0) {
    cat("ERROR: No valid stock data could be retrieved.\n")
    return()
  }
  
  correlation_matrix <- correlation_matrix[valid_stocks, , drop = FALSE]
  
  # Create correlation table visualization
  cat("\n=== Creating Correlation Table ===\n")
  
  # Create a data frame for the heatmap
  correlation_df <- as.data.frame(correlation_matrix)
  correlation_df$Stock <- rownames(correlation_df)
  correlation_df <- correlation_df[, c("Stock", benchmarks)]
  
  correlation_melted <- melt(correlation_df, id.vars = "Stock", 
                             variable.name = "Benchmark", value.name = "Correlation")
  
  # Create heatmap
  p <- ggplot(correlation_melted, aes(x = Benchmark, y = Stock, fill = Correlation)) +
    geom_tile(color = "white", size = 0.5) +
    scale_fill_gradient2(low = "#F44336", mid = "white", high = "#4CAF50", 
                         midpoint = 0, limit = c(-1, 1), space = "Lab",
                         name = "Correlation") +
    geom_text(aes(label = sprintf("%.2f", Correlation)), 
              color = "black", size = 3, fontface = "bold") +
    labs(
      title = "Portfolio Correlation Matrix",
      subtitle = paste("Correlations with Market Benchmarks -", years_selected, "Year Period"),
      x = "Market Benchmarks",
      y = "Portfolio Stocks",
      caption = "Red = Negative Correlation, Green = Positive Correlation"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      axis.title = element_text(size = 12, face = "bold"),
      axis.text = element_text(size = 10),
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      panel.grid = element_blank(),
      plot.caption = element_text(size = 9, color = "gray60")
    )
  
  # Save the heatmap
  filename <- paste0("portfolio_correlation_matrix_", years_selected, "y_", 
                     format(Sys.Date(), "%Y%m%d"), ".pdf")
  
  ggsave(filename, plot = p, width = 8, height = max(6, length(valid_stocks) * 0.4), device = "pdf")
  cat("Correlation matrix saved as:", filename, "\n")
  
  # Print correlation table to console
  cat("\n=== Portfolio Correlation Table ===\n")
  cat(sprintf("%-8s", "Stock"))
  for(benchmark in benchmarks) {
    cat(sprintf("%8s", benchmark))
  }
  cat("\n")
  cat(paste(rep("-", 8 + length(benchmarks) * 8), collapse = ""), "\n")
  cat("\n")
  
  for(i in 1:nrow(correlation_matrix)) {
    cat(sprintf("%-8s", rownames(correlation_matrix)[i]))
    for(j in 1:ncol(correlation_matrix)) {
      if(is.na(correlation_matrix[i, j])) {
        cat(sprintf("%8s", "N/A"))
      } else {
        cat(sprintf("%8.3f", correlation_matrix[i, j]))
      }
    }
    cat("\n")
  }
  
  cat("\n=== Portfolio Summary ===\n")
  cat("Total stocks analyzed:", length(valid_stocks), "/", length(tickers), "\n")
  cat("Time period:", years_selected, "years\n")
  cat("Analysis complete!\n")
}

#Debug temp0
if (!exists("batch_analysis", mode = "function")) {
  stop("batch_analysis function not defined!")
}

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

cat("=== Stock Correlation Analyzer ===\n\n")

# Check for batch mode
if(length(args) >= 2 && args[1] == "--batch") {
  # BATCH MODE - Process multiple stocks from JSON file
  json_file <- args[2]
  years_selected <- if(length(args) >= 3) as.numeric(args[3]) else 2
  advanced_mode <- if(length(args) >= 4 && args[4] == "--advanced") TRUE else FALSE
  
  if(is.na(years_selected) || !years_selected %in% 1:5) {
    years_selected <- 2
  }
  
  cat("BATCH MODE: Processing portfolio from", json_file, "\n")
  cat("Time period:", years_selected, "years\n")
  cat("Advanced analysis:", ifelse(advanced_mode, "ENABLED", "DISABLED"), "\n\n")
  
  # Load JSON config
  if(!file.exists(json_file)) {
    cat("ERROR: JSON file", json_file, "not found!\n")
    quit(status = 1)
  }
  
  tryCatch({
    config <- fromJSON(json_file)
    tickers <- config$portfolio$stocks
    
    if(is.null(tickers) || length(tickers) == 0) {
      cat("ERROR: No stocks found in portfolio.stocks array\n")
      quit(status = 1)
    }
    
    # Remove any trailing commas from JSON parsing
    tickers <- tickers[!is.na(tickers) & tickers != ""]
    tickers <- toupper(tickers)
    
    cat("Found", length(tickers), "stocks:", paste(tickers, collapse = ", "), "\n\n")
    
  }, error = function(e) {
    cat("ERROR: Failed to parse JSON file:", e$message, "\n")
    quit(status = 1)
  })
  
  # Run batch analysis
  batch_analysis(tickers, years_selected, advanced = advanced_mode)
  quit()
}

# Initialize variables
ticker <- NULL
sector_etf <- NULL
years_selected <- 2  # Default value

# Handle command line arguments or interactive mode
if(length(args) >= 1) {
  # Command line mode
  ticker <- toupper(args[1])
  
  if(length(args) >= 2 && args[2] != "NONE") {
    sector_etf <- toupper(args[2])
  }
  
  if(length(args) >= 3) {
    years_selected <- as.numeric(args[3])
    if(is.na(years_selected) || !years_selected %in% 1:5) {
      years_selected <- 2
    }
  }
  
  cat("Command line mode:\n")
  cat("Ticker:", ticker, "\n")
  cat("Sector ETF:", ifelse(is.null(sector_etf), "None", sector_etf), "\n")
  cat("Years:", years_selected, "\n\n")
  
} else {
  # Interactive mode
  cat("Interactive mode - Enter your preferences:\n\n")
  
  # Get ticker
  repeat {
    cat("Enter stock ticker (e.g., AAPL, MSFT, TSLA): ")
    ticker_input <- readLines("stdin", n=1)
    ticker <- toupper(trimws(ticker_input))
    if(nchar(ticker) > 0) break
    cat("Please enter a valid ticker.\n")
  }
  
  # Get sector ETF
  cat("\nSelect Sector ETF (or press Enter to skip):\n")
  cat("1. XLK - Technology\n")
  cat("2. XLV - Healthcare\n") 
  cat("3. XLF - Financials\n")
  cat("4. XLE - Energy\n")
  cat("5. XLI - Industrials\n")
  cat("6. XLY - Consumer Discretionary\n")
  cat("7. XLP - Consumer Staples\n")
  cat("8. XLU - Utilities\n")
  cat("9. XLB - Materials\n")
  cat("10. XLRE - Real Estate\n")
  cat("11. XLC - Communication Services\n")
  cat("Enter choice (1-11) or press Enter to skip: ")
  
  sector_choice <- trimws(readLines("stdin", n=1))
  sector_etfs <- c("XLK", "XLV", "XLF", "XLE", "XLI", "XLY", "XLP", "XLU", "XLB", "XLRE", "XLC")
  
  if(sector_choice != "" && sector_choice %in% as.character(1:11)) {
    sector_etf <- sector_etfs[as.numeric(sector_choice)]
    cat("Selected:", sector_etf, "\n")
  }
  
  # Get time period
  cat("\nEnter time period in years (1, 2, 3, 4, or 5): ")
  years_input <- trimws(readLines("stdin", n=1))
  years_selected <- as.numeric(years_input)
  
  if(is.na(years_selected) || !years_selected %in% 1:5) {
    cat("Invalid input. Using default: 2 years\n")
    years_selected <- 2
  }
}

# Define benchmarks
benchmarks <- c("SPY", "QQQ", "USO")
if(!is.null(sector_etf)) {
  benchmarks <- c(benchmarks, sector_etf)
}

cat("\n=== Analysis Configuration ===\n")
cat("Stock:", ticker, "\n")
cat("Benchmarks:", paste(benchmarks, collapse = ", "), "\n")
cat("Time period:", years_selected, "years\n")

end_date <- Sys.Date()
start_date <- end_date - (years_selected * 365)

cat("Date range:", as.character(start_date), "to", as.character(end_date), "\n")
cat("\n=== Fetching Data ===\n")

# Get stock data
cat("Fetching", ticker, "data...\n")
stock_data <- get_data_safe(ticker, start_date, end_date)

if(is.null(stock_data)) {
  cat("ERROR: Failed to fetch stock data for", ticker, "\n")
  cat("Please check if the ticker is valid and try again.\n")
  quit(status = 1)
}

# Get stock returns
stock_prices <- if(ncol(stock_data) >= 6) Ad(stock_data) else Cl(stock_data)
stock_returns <- diff(log(stock_prices))
stock_returns <- na.omit(stock_returns)

cat("Stock data: OK (", nrow(stock_returns), "observations)\n")

# Calculate correlations
correlations <- numeric(length(benchmarks))
names(correlations) <- benchmarks

cat("\nCalculating correlations...\n")
for(i in 1:length(benchmarks)) {
  benchmark <- benchmarks[i]
  cat("Processing", benchmark, "...")
  
  benchmark_data <- get_data_safe(benchmark, start_date, end_date)
  
  if(!is.null(benchmark_data)) {
    # Get benchmark returns
    benchmark_prices <- if(ncol(benchmark_data) >= 6) Ad(benchmark_data) else Cl(benchmark_data)
    benchmark_returns <- diff(log(benchmark_prices))
    benchmark_returns <- na.omit(benchmark_returns)
    
    # Find common dates
    common_dates <- intersect(index(stock_returns), index(benchmark_returns))
    
    if(length(common_dates) >= 10) {
      stock_aligned <- stock_returns[common_dates]
      benchmark_aligned <- benchmark_returns[common_dates]
      
      correlations[i] <- cor(as.numeric(stock_aligned), as.numeric(benchmark_aligned), use = "complete.obs")
      cat(" Correlation:", round(correlations[i], 3), "\n")
    } else {
      correlations[i] <- NA
      cat(" Not enough data\n")
    }
  } else {
    correlations[i] <- NA
    cat(" Failed to fetch\n")
  }
}

# Check if we have any valid correlations
valid_data <- !is.na(correlations)
if(sum(valid_data) == 0) {
  cat("ERROR: No valid correlation data could be calculated.\n")
  quit(status = 1)
}

plot_benchmarks <- benchmarks[valid_data]
plot_correlations <- correlations[valid_data]

cat("\n=== Creating Chart ===\n")

# Create data frame for plotting
df <- data.frame(
  ETF = factor(plot_benchmarks, levels = plot_benchmarks),
  Correlation = plot_correlations,
  Color = ifelse(plot_correlations >= 0, "Positive", "Negative")
)

# Create the plot
p <- ggplot(df, aes(x = ETF, y = Correlation, fill = Color)) +
  geom_col(width = 0.7, alpha = 0.8) +
  scale_fill_manual(values = c("Positive" = "#4CAF50", "Negative" = "#F44336")) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.2)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  labs(
    title = paste("Correlation Analysis:", ticker, "vs Market Benchmarks"),
    subtitle = paste("Analysis Period:", years_selected, ifelse(years_selected == 1, "Year", "Years")),
    x = "Market Benchmarks",
    y = "Correlation Coefficient",
    caption = "Green = Positive Correlation, Red = Negative Correlation\nRange: -1 (Perfect Negative) to +1 (Perfect Positive)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.caption = element_text(size = 9, color = "gray60")
  ) +
  geom_text(aes(label = sprintf("%.3f", Correlation)), 
            vjust = ifelse(df$Correlation >= 0, -0.5, 1.5),
            size = 4, fontface = "bold")

# Save the chart
filename <- paste0(ticker, "_correlation_", years_selected, "y_", format(Sys.Date(), "%Y%m%d"), ".pdf")

tryCatch({
  ggsave(filename, plot = p, width = 10, height = 6, device = "pdf")
  cat("Chart saved as:", filename, "\n")
}, error = function(e) {
  cat("Error saving chart:", e$message, "\n")
  # Try alternative filename
  alt_filename <- paste0("correlation_chart_", format(Sys.Date(), "%Y%m%d"), ".pdf")
  ggsave(alt_filename, plot = p, width = 10, height = 6, device = "pdf")
  cat("Chart saved as:", alt_filename, "\n")
})

cat("\n=== Analysis Complete ===\n")

# Print summary
cat("\nCorrelation Summary for", ticker, ":\n")
cat(paste(rep("=", 40), collapse = ""), "\n")
for(i in 1:length(plot_benchmarks)) {
  corr_val <- plot_correlations[i]
  strength <- if(abs(corr_val) > 0.7) "Strong" else if(abs(corr_val) > 0.3) "Moderate" else "Weak"
  direction <- if(corr_val > 0) "Positive" else "Negative"
  cat(sprintf("%-5s: %6.3f  (%s %s)\n", plot_benchmarks[i], corr_val, strength, direction))
}