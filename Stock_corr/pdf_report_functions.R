# pdf_report_functions.R
# Simplified PDF Report Generation Functions for Advanced Correlation Analysis

library(ggplot2)
library(gridExtra)
library(grid)

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
    
    # All the rest: Individual Stock Analysis (one page per stock)
    for(stock in names(all_results)) {
      if(length(all_results[[stock]]) > 0) {
        create_stock_analysis_page(all_results[[stock]], stock)
      }
    }
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
    "Tail Dependence Analysis"
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
  risk_plot <- create_risk_matrix_plot(all_results)
  
  # Print the plot to PDF
  print(risk_plot)
}

# =============================================================================
# INDIVIDUAL STOCK ANALYSIS PAGE
# =============================================================================

create_stock_analysis_page <- function(stock_results, stock_name) {
  # Create correlation comparison chart
  correlation_plot <- create_stock_correlation_plot(stock_results, stock_name)
  
  # Create regime analysis chart  
  regime_plot <- create_regime_analysis_plot(stock_results, stock_name)
  
  # Generate insights text to add as subtitle to charts
  insights <- generate_stock_insights(stock_results)
  insights_text <- ""
  if(length(insights) > 0) {
    # Limit to first 2-3 insights to fit as subtitle
    key_insights <- insights[1:min(2, length(insights))]
    insights_text <- paste(key_insights, collapse = " | ")
  }
  
  # Create a combined plot with title and insights
  combined_plot <- grid.arrange(
    correlation_plot, regime_plot,
    ncol = 2,
    top = textGrob(paste("Analysis:", stock_name), 
                   gp = gpar(fontsize = 16, fontface = "bold")),
    bottom = textGrob(insights_text, 
                      gp = gpar(fontsize = 9, fontface = "italic"),
                      x = 0.5, hjust = 0.5)
  )
  
  # Print the combined plot (everything on one page)
  print(combined_plot)
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

calculate_portfolio_summary <- function(all_results, tickers) {
  high_risk_stocks <- character(0)
  medium_risk_stocks <- character(0)
  low_risk_stocks <- character(0)
  
  for(stock in names(all_results)) {
    risk_count <- 0
    total_benchmarks <- 0
    
    for(benchmark in names(all_results[[stock]])) {
      result <- all_results[[stock]][[benchmark]]
      
      if(!is.null(result)) {
        total_benchmarks <- total_benchmarks + 1
        
        # Check volatility dependency
        if(!is.null(result$high_vol) && !is.null(result$low_vol)) {
          if(result$high_vol$correlation - result$low_vol$correlation > 0.15) risk_count <- risk_count + 1
        }
        
        # Check regime dependency
        if(!is.null(result$bull) && !is.null(result$bear)) {
          if(result$bear$correlation - result$bull$correlation > 0.15) risk_count <- risk_count + 1
        }
        
        # Check tail dependency
        if(!is.null(result$lower_tail) && result$lower_tail$correlation > 0.6) risk_count <- risk_count + 1
      }
    }
    
    # Classify based on average risk factors
    if(total_benchmarks > 0) {
      avg_risk <- risk_count / total_benchmarks
      if(avg_risk >= 1.5) {
        high_risk_stocks <- c(high_risk_stocks, stock)
      } else if(avg_risk >= 0.8) {
        medium_risk_stocks <- c(medium_risk_stocks, stock)
      } else {
        low_risk_stocks <- c(low_risk_stocks, stock)
      }
    }
  }
  
  return(list(
    high_risk_stocks = high_risk_stocks,
    medium_risk_stocks = medium_risk_stocks,
    low_risk_stocks = low_risk_stocks,
    total_stocks = length(tickers)
  ))
}

generate_portfolio_insights <- function(summary_stats) {
  insights <- character(0)
  
  total_stocks <- summary_stats$total_stocks
  high_risk_pct <- length(summary_stats$high_risk_stocks) / total_stocks * 100
  
  if(high_risk_pct > 50) {
    insights <- c(insights, "High concentration of risky assets - diversification concerns")
  } else if(high_risk_pct > 25) {
    insights <- c(insights, "Moderate risk concentration - monitor during volatile periods")
  } else {
    insights <- c(insights, "Well-diversified portfolio from correlation perspective")
  }
  
  if(length(summary_stats$high_risk_stocks) > 0) {
    insights <- c(insights, "High-risk stocks show correlation spikes during market stress")
  }
  
  return(insights)
}

create_risk_matrix_plot <- function(all_results) {
  # Prepare data for risk matrix
  risk_data <- data.frame(
    Stock = character(0),
    Benchmark = character(0),
    Overall_Corr = numeric(0),
    Vol_Effect = numeric(0),
    Regime_Effect = numeric(0)
  )
  
  for(stock in names(all_results)) {
    for(benchmark in names(all_results[[stock]])) {
      result <- all_results[[stock]][[benchmark]]
      
      if(!is.null(result) && !is.null(result$overall)) {
        vol_effect <- 0
        if(!is.null(result$high_vol) && !is.null(result$low_vol)) {
          vol_effect <- result$high_vol$correlation - result$low_vol$correlation
        }
        
        regime_effect <- 0
        if(!is.null(result$bull) && !is.null(result$bear)) {
          regime_effect <- result$bear$correlation - result$bull$correlation
        }
        
        risk_data <- rbind(risk_data, data.frame(
          Stock = stock,
          Benchmark = benchmark,
          Overall_Corr = result$overall$correlation,
          Vol_Effect = vol_effect,
          Regime_Effect = regime_effect
        ))
      }
    }
  }
  
  if(nrow(risk_data) > 0) {
    p <- ggplot(risk_data, aes(x = Vol_Effect, y = Regime_Effect, 
                               size = abs(Overall_Corr), color = Stock)) +
      geom_point(alpha = 0.7) +
      scale_size_continuous(range = c(3, 10), name = "Abs Correlation") +
      labs(title = "Portfolio Risk Assessment Matrix",
           subtitle = "Higher values indicate greater correlation dependency",
           x = "Volatility Effect (High Vol - Low Vol Correlation)",
           y = "Regime Effect (Bear - Bull Correlation)",
           caption = "Points in upper-right quadrant show highest risk") +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5),
        legend.position = "bottom"
      ) +
      geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
      geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5)
    
    return(p)
  } else {
    # Return simple plot if no data
    return(ggplot() + 
             labs(title = "Portfolio Risk Assessment Matrix",
                  subtitle = "No sufficient data available for risk matrix") +
             theme_minimal() +
             theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5)))
  }
}

create_stock_correlation_plot <- function(stock_results, stock_name) {
  # Prepare correlation data
  corr_data <- data.frame(
    Condition = character(0),
    Benchmark = character(0),
    Correlation = numeric(0)
  )
  
  for(benchmark in names(stock_results)) {
    result <- stock_results[[benchmark]]
    
    if(!is.null(result)) {
      # Overall correlation
      if(!is.null(result$overall)) {
        corr_data <- rbind(corr_data, data.frame(
          Condition = "Overall",
          Benchmark = benchmark,
          Correlation = result$overall$correlation
        ))
      }
      
      # Bull market
      if(!is.null(result$bull)) {
        corr_data <- rbind(corr_data, data.frame(
          Condition = "Bull Market",
          Benchmark = benchmark,
          Correlation = result$bull$correlation
        ))
      }
      
      # Bear market
      if(!is.null(result$bear)) {
        corr_data <- rbind(corr_data, data.frame(
          Condition = "Bear Market",
          Benchmark = benchmark,
          Correlation = result$bear$correlation
        ))
      }
    }
  }
  
  if(nrow(corr_data) > 0) {
    p <- ggplot(corr_data, aes(x = Benchmark, y = Correlation, fill = Condition)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("Overall" = "lightblue", 
                                   "Bull Market" = "lightgreen", 
                                   "Bear Market" = "lightcoral")) +
      labs(title = paste("Market Regime Correlations:", stock_name),
           y = "Correlation Coefficient",
           x = "Benchmark") +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom"
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
    Correlation = numeric(0)
  )
  
  for(benchmark in names(stock_results)) {
    result <- stock_results[[benchmark]]
    
    if(!is.null(result)) {
      # High volatility
      if(!is.null(result$high_vol)) {
        vol_data <- rbind(vol_data, data.frame(
          Regime = "High Volatility",
          Benchmark = benchmark,
          Correlation = result$high_vol$correlation
        ))
      }
      
      # Low volatility
      if(!is.null(result$low_vol)) {
        vol_data <- rbind(vol_data, data.frame(
          Regime = "Low Volatility",
          Benchmark = benchmark,
          Correlation = result$low_vol$correlation
        ))
      }
    }
  }
  
  if(nrow(vol_data) > 0) {
    p <- ggplot(vol_data, aes(x = Benchmark, y = Correlation, fill = Regime)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
      scale_fill_manual(values = c("High Volatility" = "orange", 
                                   "Low Volatility" = "lightgreen")) +
      labs(title = paste("Volatility Regime Correlations:", stock_name),
           y = "Correlation Coefficient",
           x = "Benchmark") +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom"
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

