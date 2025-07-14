# pdf_report_functions.R
# PDF Report Generation Functions for Advanced Correlation Analysis - With Beta

library(ggplot2)
library(gridExtra)
library(grid)
source("risk_plot_functions.R")

# =============================================================================
# PDF REPORT GENERATOR - MAIN FUNCTION
# =============================================================================

generate_pdf_report <- function(all_results, tickers, years_selected, output_filename = NULL) {
  
  if(is.null(output_filename)) {
    output_filename <- paste0("portfolio_advanced_correlation_report_", 
                              years_selected, "y_", 
                              format(Sys.Date(), "%Y%m%d"), ".pdf")
  }
  
  cat("=== Generating PDF Report ===\n")
  cat("Output file:", output_filename, "\n")
  
  # Start PDF device with proper settings
  pdf(output_filename, width = 11, height = 8.5)
  
  tryCatch({
    # Page 1: Title Page
    create_title_page(tickers, years_selected)
    
    # Page 2: Risk Assessment Matrix
    create_risk_matrix_page(all_results)
    
    # Individual Stock Analysis (4 stocks per page)
    create_stock_analysis_pages(all_results)
    
    cat("PDF report generated successfully!\n")
    
  }, error = function(e) {
    cat("Error generating PDF:", e$message, "\n")
  }, finally = {
    dev.off()  # Always close the PDF device
  })
  
  return(output_filename)
}

# =============================================================================
# TITLE PAGE
# =============================================================================

create_title_page <- function(tickers, years_selected) {
  # Create empty plot and add text using grid
  plot.new()
  
  # Title
  text(0.5, 0.9, "Advanced Portfolio Correlation Analysis", 
       cex = 2.5, font = 2, col = "darkblue")
  
  # Subtitle
  text(0.5, 0.82, "Comprehensive Risk Assessment Report", 
       cex = 1.5, col = "darkblue")
  
  # Analysis period
  text(0.5, 0.75, paste("Analysis Period:", years_selected, ifelse(years_selected == 1, "Year", "Years")), 
       cex = 1.2)
  
  # Portfolio stocks
  text(0.5, 0.65, "Portfolio Stocks:", cex = 1.2, font = 2)
  
  # Stock list
  stock_text <- paste(tickers, collapse = ", ")
  if(nchar(stock_text) > 60) {
    # Split into multiple lines
    stock_chunks <- split(tickers, ceiling(seq_along(tickers) / 6))
    for(i in 1:length(stock_chunks)) {
      text(0.5, 0.6 - (i-1) * 0.04, paste(stock_chunks[[i]], collapse = ", "), cex = 1)
    }
  } else {
    text(0.5, 0.6, stock_text, cex = 1)
  }
  
  # Report details
  text(0.5, 0.45, paste("Report Generated:", format(Sys.Date(), "%B %d, %Y")), cex = 1)
  text(0.5, 0.4, "Benchmarks: SPY (S&P 500)", cex = 1)
  
  # Analysis methods
  text(0.5, 0.3, "Analysis Methods:", cex = 1.2, font = 2)
  
  methods <- c(
    "Statistical Significance Testing",
    "Volatility-Adjusted Correlations", 
    "Market Regime Analysis",
    "Tail Dependence Analysis",
    "Beta Calculations for Market Sensitivity"
  )
  
  for(i in 1:length(methods)) {
    text(0.5, 0.25 - (i-1) * 0.03, paste("•", methods[i]), cex = 0.9)
  }
}

# =============================================================================
# RISK ASSESSMENT MATRIX PAGE
# =============================================================================

create_risk_matrix_page <- function(all_results) {
  # Create the risk matrix plot
  risk_plot <- create_risk_matrix_plot(all_results, use_icons = FALSE)
  
  # Print the plot to PDF
  print(risk_plot)
}

# =============================================================================
# INDIVIDUAL STOCK ANALYSIS PAGES (4 stocks per page)
# =============================================================================

create_stock_analysis_pages <- function(all_results) {
  stock_names <- names(all_results)
  
  # Process stocks in groups of 4
  for(i in seq(1, length(stock_names), by = 4)) {
    # Get up to 4 stocks for this page
    page_stocks <- stock_names[i:min(i+3, length(stock_names))]
    
    # Create plots for each stock on this page
    plots_list <- list()
    
    for(j in 1:length(page_stocks)) {
      stock_name <- page_stocks[j]
      stock_results <- all_results[[stock_name]]
      
      if(length(stock_results) > 0) {
        # Create correlation plot
        corr_plot <- create_stock_correlation_plot(stock_results, stock_name)
        # Create regime plot  
        regime_plot <- create_regime_analysis_plot(stock_results, stock_name)
        
        plots_list[[2*j-1]] <- corr_plot
        plots_list[[2*j]] <- regime_plot
      }
    }
    
    # Arrange plots in 4x2 grid (4 rows, 2 columns)
    if(length(plots_list) > 0) {
      combined_plot <- grid.arrange(grobs = plots_list, ncol = 2)
      print(combined_plot)
    }
  }
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

create_stock_correlation_plot <- function(stock_results, stock_name) {
  # Prepare correlation data
  corr_data <- data.frame(
    Condition = character(0),
    Benchmark = character(0),
    Correlation = numeric(0),
    Beta = numeric(0)
  )
  
  # Get overall beta for title
  overall_beta <- NA
  
  for(benchmark in names(stock_results)) {
    result <- stock_results[[benchmark]]
    
    if(!is.null(result)) {
      # Get overall beta for title
      if(!is.na(overall_beta) && !is.null(result$overall$beta)) {
        overall_beta <- result$overall$beta
      } else if(is.na(overall_beta) && !is.null(result$overall$beta)) {
        overall_beta <- result$overall$beta
      }
      
      # Overall correlation
      if(!is.null(result$overall)) {
        corr_data <- rbind(corr_data, data.frame(
          Condition = "Overall",
          Benchmark = benchmark,
          Correlation = result$overall$correlation,
          Beta = result$overall$beta
        ))
      }
      
      # Bull market
      if(!is.null(result$bull)) {
        corr_data <- rbind(corr_data, data.frame(
          Condition = "Bull Market",
          Benchmark = benchmark,
          Correlation = result$bull$correlation,
          Beta = result$bull$beta
        ))
      }
      
      # Bear market
      if(!is.null(result$bear)) {
        corr_data <- rbind(corr_data, data.frame(
          Condition = "Bear Market",
          Benchmark = benchmark,
          Correlation = result$bear$correlation,
          Beta = result$bear$beta
        ))
      }
    }
  }
  
  # Create title with beta
  beta_text <- if(!is.na(overall_beta)) paste0("(β=", sprintf("%.2f", overall_beta), ")") else ""
  plot_title <- paste("Market Regime Correlations:", stock_name, beta_text)
  
  if(nrow(corr_data) > 0) {
    p <- ggplot(corr_data, aes(x = Benchmark, y = Correlation, fill = Condition)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("Overall" = "lightblue", 
                                   "Bull Market" = "lightgreen", 
                                   "Bear Market" = "lightcoral")) +
      labs(title = plot_title,
           y = "Correlation Coefficient",
           x = "Benchmark") +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "right"
      ) +
      ylim(-1, 1)
    
    return(p)
  } else {
    return(ggplot() + 
             labs(title = paste("No correlation data for", stock_name)) +
             theme_minimal())
  }
}

create_regime_analysis_plot <- function(stock_results, stock_name) {
  # Prepare volatility data
  vol_data <- data.frame(
    Regime = character(0),
    Benchmark = character(0),
    Correlation = numeric(0),
    Beta = numeric(0)
  )
  
  # Get overall beta for title
  overall_beta <- NA
  
  for(benchmark in names(stock_results)) {
    result <- stock_results[[benchmark]]
    
    if(!is.null(result)) {
      # Get overall beta for title
      if(!is.na(overall_beta) && !is.null(result$overall$beta)) {
        overall_beta <- result$overall$beta
      } else if(is.na(overall_beta) && !is.null(result$overall$beta)) {
        overall_beta <- result$overall$beta
      }
      
      # High volatility
      if(!is.null(result$high_vol)) {
        vol_data <- rbind(vol_data, data.frame(
          Regime = "High Volatility",
          Benchmark = benchmark,
          Correlation = result$high_vol$correlation,
          Beta = result$high_vol$beta
        ))
      }
      
      # Low volatility
      if(!is.null(result$low_vol)) {
        vol_data <- rbind(vol_data, data.frame(
          Regime = "Low Volatility",
          Benchmark = benchmark,
          Correlation = result$low_vol$correlation,
          Beta = result$low_vol$beta
        ))
      }
    }
  }
  
  # Create title with beta
  beta_text <- if(!is.na(overall_beta)) paste0("(β=", sprintf("%.2f", overall_beta), ")") else ""
  plot_title <- paste("Volatility Regime Correlations:", stock_name, beta_text)
  
  if(nrow(vol_data) > 0) {
    p <- ggplot(vol_data, aes(x = Benchmark, y = Correlation, fill = Regime)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("High Volatility" = "orange", 
                                   "Low Volatility" = "lightgreen")) +
      labs(title = plot_title,
           y = "Correlation Coefficient",
           x = "Benchmark") +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "right"
      ) +
      ylim(-1, 1)
    
    return(p)
  } else {
    return(ggplot() + 
             labs(title = paste("No volatility data for", stock_name)) +
             theme_minimal())
  }
}

generate_stock_insights <- function(stock_results) {
  insights <- character(0)
  
  for(benchmark in names(stock_results)) {
    result <- stock_results[[benchmark]]
    
    if(!is.null(result)) {
      # Check for volatility dependency
      if(!is.null(result$high_vol) && !is.null(result$low_vol)) {
        vol_diff <- result$high_vol$correlation - result$low_vol$correlation
        if(vol_diff > 0.2) {
          insights <- c(insights, paste("High volatility dependency with", benchmark,
                                        sprintf("(+%.2f)", vol_diff)))
        }
      }
      
      # Check for regime dependency
      if(!is.null(result$bull) && !is.null(result$bear)) {
        regime_diff <- result$bear$correlation - result$bull$correlation
        if(regime_diff > 0.2) {
          insights <- c(insights, paste("Bear market correlation spike with", benchmark,
                                        sprintf("(+%.2f)", regime_diff)))
        }
      }
      
      # Check for tail dependency
      if(!is.null(result$lower_tail) && result$lower_tail$correlation > 0.7) {
        insights <- c(insights, paste("High downside tail dependence with", benchmark,
                                      sprintf("(%.2f)", result$lower_tail$correlation)))
      }
    }
  }
  
  if(length(insights) == 0) {
    insights <- c("Relatively stable correlation patterns across market conditions")
  }
  
  return(insights)
}