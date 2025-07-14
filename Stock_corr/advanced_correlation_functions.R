# =============================================================================
# ADVANCED CORRELATION ANALYSIS FUNCTION WITH BETA
# =============================================================================

advanced_correlation_analysis <- function(stock_returns, benchmark_returns, stock_name, benchmark_name) {
  
  cat("=== Advanced Correlation Analysis ===\n")
  cat("Stock:", stock_name, "vs", benchmark_name, "\n")
  cat("Sample size:", length(stock_returns), "observations\n\n")
  
  # Ensure we have common dates and remove NAs
  common_data <- na.omit(cbind(stock_returns, benchmark_returns))
  stock_clean <- common_data[,1]
  bench_clean <- common_data[,2]
  
  if(length(stock_clean) < 30) {
    cat("ERROR: Insufficient data for analysis (need at least 30 observations)\n")
    return(NULL)
  }
  
  # Initialize results structure
  results <- list()
  
  # =============================================================================
  # METHOD D: Statistical Significance Testing (Base Analysis)
  # =============================================================================
  cat("D. Statistical Significance Analysis\n")
  cat("=====================================\n")
  
  # Overall correlation with significance
  overall_test <- cor.test(stock_clean, bench_clean)
  
  # Calculate overall beta
  overall_beta <- cov(stock_clean, bench_clean) / var(bench_clean)
  
  results$overall <- list(
    correlation = as.numeric(overall_test$estimate),
    beta = overall_beta,
    p_value = overall_test$p.value,
    conf_low = overall_test$conf.int[1],
    conf_high = overall_test$conf.int[2],
    significant = overall_test$p.value < 0.05
  )
  
  cat(sprintf("Overall Correlation: %.4f\n", results$overall$correlation))
  cat(sprintf("Overall Beta: %.4f\n", results$overall$beta))
  cat(sprintf("P-value: %.6f %s\n", results$overall$p_value, 
              ifelse(results$overall$significant, "(SIGNIFICANT)", "(not significant)")))
  cat(sprintf("95%% Confidence Interval: [%.4f, %.4f]\n", 
              results$overall$conf_low, results$overall$conf_high))
  cat("\n")
  
  # =============================================================================
  # METHOD E: Volatility-Adjusted Correlations
  # =============================================================================
  cat("E. Volatility-Adjusted Correlations\n")
  cat("====================================\n")
  
  # Calculate rolling volatility (20-day window)
  if(length(stock_clean) >= 20) {
    stock_vol <- runSD(stock_clean, n = 20)
    bench_vol <- runSD(bench_clean, n = 20)
    
    # Remove initial NAs from rolling calculation
    valid_vol_idx <- !is.na(stock_vol) & !is.na(bench_vol)
    stock_vol_clean <- stock_vol[valid_vol_idx]
    bench_vol_clean <- bench_vol[valid_vol_idx]
    stock_vol_returns <- stock_clean[valid_vol_idx]
    bench_vol_returns <- bench_clean[valid_vol_idx]
    
    if(length(stock_vol_clean) >= 30) {
      # Define volatility regimes
      vol_75th <- quantile(stock_vol_clean, 0.75, na.rm = TRUE)
      vol_25th <- quantile(stock_vol_clean, 0.25, na.rm = TRUE)
      
      high_vol_mask <- stock_vol_clean > vol_75th
      low_vol_mask <- stock_vol_clean < vol_25th
      
      # Calculate volatility-regime correlations and betas
      if(sum(high_vol_mask, na.rm = TRUE) >= 10) {
        high_vol_test <- cor.test(stock_vol_returns[high_vol_mask], 
                                  bench_vol_returns[high_vol_mask])
        high_vol_beta <- cov(stock_vol_returns[high_vol_mask], 
                             bench_vol_returns[high_vol_mask]) / var(bench_vol_returns[high_vol_mask])
        
        results$high_vol <- list(
          correlation = as.numeric(high_vol_test$estimate),
          beta = high_vol_beta,
          p_value = high_vol_test$p.value,
          n_obs = sum(high_vol_mask, na.rm = TRUE),
          significant = high_vol_test$p.value < 0.05
        )
      }
      
      if(sum(low_vol_mask, na.rm = TRUE) >= 10) {
        low_vol_test <- cor.test(stock_vol_returns[low_vol_mask], 
                                 bench_vol_returns[low_vol_mask])
        low_vol_beta <- cov(stock_vol_returns[low_vol_mask], 
                            bench_vol_returns[low_vol_mask]) / var(bench_vol_returns[low_vol_mask])
        
        results$low_vol <- list(
          correlation = as.numeric(low_vol_test$estimate),
          beta = low_vol_beta,
          p_value = low_vol_test$p.value,
          n_obs = sum(low_vol_mask, na.rm = TRUE),
          significant = low_vol_test$p.value < 0.05
        )
      }
      
      # Report volatility analysis
      if(!is.null(results$high_vol)) {
        cat(sprintf("High Volatility Periods: %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                    results$high_vol$correlation, results$high_vol$beta, 
                    results$high_vol$p_value, results$high_vol$n_obs,
                    ifelse(results$high_vol$significant, "*", "")))
      }
      if(!is.null(results$low_vol)) {
        cat(sprintf("Low Volatility Periods:  %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                    results$low_vol$correlation, results$low_vol$beta,
                    results$low_vol$p_value, results$low_vol$n_obs,
                    ifelse(results$low_vol$significant, "*", "")))
      }
      
      # Volatility regime comparison
      if(!is.null(results$high_vol) && !is.null(results$low_vol)) {
        vol_diff <- results$high_vol$correlation - results$low_vol$correlation
        beta_diff <- results$high_vol$beta - results$low_vol$beta
        cat(sprintf("Volatility Effect: %.4f correlation, %.2f beta (High - Low)\n", vol_diff, beta_diff))
        if(vol_diff > 0.1) {
          cat("→ Strong volatility dependency: correlations increase during volatile periods\n")
        } else if(vol_diff < -0.1) {
          cat("→ Inverse volatility dependency: correlations decrease during volatile periods\n")
        } else {
          cat("→ Minimal volatility dependency\n")
        }
      }
    }
  }
  cat("\n")
  
  # =============================================================================
  # METHOD C: Regime-Dependent Correlations
  # =============================================================================
  cat("C. Regime-Dependent Correlations\n")
  cat("=================================\n")
  
  # Define market regimes based on benchmark returns
  bench_60th <- quantile(bench_clean, 0.6, na.rm = TRUE)
  bench_40th <- quantile(bench_clean, 0.4, na.rm = TRUE)
  
  bull_mask <- bench_clean > bench_60th
  bear_mask <- bench_clean < bench_40th
  neutral_mask <- bench_clean >= bench_40th & bench_clean <= bench_60th
  
  # Bull market analysis
  if(sum(bull_mask, na.rm = TRUE) >= 10) {
    bull_test <- cor.test(stock_clean[bull_mask], bench_clean[bull_mask])
    bull_beta <- cov(stock_clean[bull_mask], bench_clean[bull_mask]) / var(bench_clean[bull_mask])
    
    results$bull <- list(
      correlation = as.numeric(bull_test$estimate),
      beta = bull_beta,
      p_value = bull_test$p.value,
      n_obs = sum(bull_mask, na.rm = TRUE),
      significant = bull_test$p.value < 0.05
    )
    cat(sprintf("Bull Market (top 40%% days): %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                results$bull$correlation, results$bull$beta, results$bull$p_value, 
                results$bull$n_obs, ifelse(results$bull$significant, "*", "")))
  }
  
  # Bear market analysis
  if(sum(bear_mask, na.rm = TRUE) >= 10) {
    bear_test <- cor.test(stock_clean[bear_mask], bench_clean[bear_mask])
    bear_beta <- cov(stock_clean[bear_mask], bench_clean[bear_mask]) / var(bench_clean[bear_mask])
    
    results$bear <- list(
      correlation = as.numeric(bear_test$estimate),
      beta = bear_beta,
      p_value = bear_test$p.value,
      n_obs = sum(bear_mask, na.rm = TRUE),
      significant = bear_test$p.value < 0.05
    )
    cat(sprintf("Bear Market (bottom 40%% days): %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                results$bear$correlation, results$bear$beta, results$bear$p_value, 
                results$bear$n_obs, ifelse(results$bear$significant, "*", "")))
  }
  
  # Neutral market analysis
  if(sum(neutral_mask, na.rm = TRUE) >= 10) {
    neutral_test <- cor.test(stock_clean[neutral_mask], bench_clean[neutral_mask])
    neutral_beta <- cov(stock_clean[neutral_mask], bench_clean[neutral_mask]) / var(bench_clean[neutral_mask])
    
    results$neutral <- list(
      correlation = as.numeric(neutral_test$estimate),
      beta = neutral_beta,
      p_value = neutral_test$p.value,
      n_obs = sum(neutral_mask, na.rm = TRUE),
      significant = neutral_test$p.value < 0.05
    )
    cat(sprintf("Neutral Market (middle 20%% days): %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                results$neutral$correlation, results$neutral$beta, results$neutral$p_value, 
                results$neutral$n_obs, ifelse(results$neutral$significant, "*", "")))
  }
  
  # Regime comparison
  if(!is.null(results$bull) && !is.null(results$bear)) {
    regime_diff <- results$bear$correlation - results$bull$correlation
    beta_diff <- results$bear$beta - results$bull$beta
    cat(sprintf("Regime Effect: %.4f correlation, %.2f beta (Bear - Bull)\n", regime_diff, beta_diff))
    if(regime_diff > 0.15) {
      cat("→ Strong regime dependency: much higher correlation in bear markets\n")
    } else if(regime_diff < -0.15) {
      cat("→ Contrarian behavior: lower correlation in bear markets\n")
    } else {
      cat("→ Consistent behavior across market regimes\n")
    }
  }
  cat("\n")
  
  # =============================================================================
  # METHOD F: Tail Dependence Analysis
  # =============================================================================
  cat("F. Tail Dependence Analysis\n")
  cat("============================\n")
  
  # Calculate standard deviations for extreme thresholds
  stock_sd <- sd(stock_clean, na.rm = TRUE)
  bench_sd <- sd(bench_clean, na.rm = TRUE)
  
  # Define extreme events (±2 standard deviations)
  stock_extreme_pos <- stock_clean > 2 * stock_sd
  stock_extreme_neg <- stock_clean < -2 * stock_sd
  bench_extreme_pos <- bench_clean > 2 * bench_sd
  bench_extreme_neg <- bench_clean < -2 * bench_sd
  
  # Upper tail dependence (extreme positive moves)
  upper_tail_mask <- stock_extreme_pos | bench_extreme_pos
  if(sum(upper_tail_mask, na.rm = TRUE) >= 5) {
    upper_tail_test <- cor.test(stock_clean[upper_tail_mask], bench_clean[upper_tail_mask])
    upper_tail_beta <- cov(stock_clean[upper_tail_mask], bench_clean[upper_tail_mask]) / var(bench_clean[upper_tail_mask])
    
    results$upper_tail <- list(
      correlation = as.numeric(upper_tail_test$estimate),
      beta = upper_tail_beta,
      p_value = upper_tail_test$p.value,
      n_obs = sum(upper_tail_mask, na.rm = TRUE),
      significant = upper_tail_test$p.value < 0.05
    )
    cat(sprintf("Upper Tail (extreme positive): %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                results$upper_tail$correlation, results$upper_tail$beta, 
                results$upper_tail$p_value, results$upper_tail$n_obs,
                ifelse(results$upper_tail$significant, "*", "")))
  }
  
  # Lower tail dependence (extreme negative moves)
  lower_tail_mask <- stock_extreme_neg | bench_extreme_neg
  if(sum(lower_tail_mask, na.rm = TRUE) >= 5) {
    lower_tail_test <- cor.test(stock_clean[lower_tail_mask], bench_clean[lower_tail_mask])
    lower_tail_beta <- cov(stock_clean[lower_tail_mask], bench_clean[lower_tail_mask]) / var(bench_clean[lower_tail_mask])
    
    results$lower_tail <- list(
      correlation = as.numeric(lower_tail_test$estimate),
      beta = lower_tail_beta,
      p_value = lower_tail_test$p.value,
      n_obs = sum(lower_tail_mask, na.rm = TRUE),
      significant = lower_tail_test$p.value < 0.05
    )
    cat(sprintf("Lower Tail (extreme negative): %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                results$lower_tail$correlation, results$lower_tail$beta,
                results$lower_tail$p_value, results$lower_tail$n_obs,
                ifelse(results$lower_tail$significant, "*", "")))
  }
  
  # Alternative: Quantile-based tail analysis (top/bottom 5%)
  upper_95_stock <- quantile(stock_clean, 0.95, na.rm = TRUE)
  lower_5_stock <- quantile(stock_clean, 0.05, na.rm = TRUE)
  upper_95_bench <- quantile(bench_clean, 0.95, na.rm = TRUE)
  lower_5_bench <- quantile(bench_clean, 0.05, na.rm = TRUE)
  
  extreme_positive_mask <- (stock_clean > upper_95_stock) | (bench_clean > upper_95_bench)
  extreme_negative_mask <- (stock_clean < lower_5_stock) | (bench_clean < lower_5_bench)
  
  if(sum(extreme_positive_mask, na.rm = TRUE) >= 5) {
    ext_pos_test <- cor.test(stock_clean[extreme_positive_mask], bench_clean[extreme_positive_mask])
    ext_pos_beta <- cov(stock_clean[extreme_positive_mask], bench_clean[extreme_positive_mask]) / var(bench_clean[extreme_positive_mask])
    cat(sprintf("95th Percentile Tail: %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                ext_pos_test$estimate, ext_pos_beta, ext_pos_test$p.value, 
                sum(extreme_positive_mask, na.rm = TRUE),
                ifelse(ext_pos_test$p.value < 0.05, "*", "")))
  }
  
  if(sum(extreme_negative_mask, na.rm = TRUE) >= 5) {
    ext_neg_test <- cor.test(stock_clean[extreme_negative_mask], bench_clean[extreme_negative_mask])
    ext_neg_beta <- cov(stock_clean[extreme_negative_mask], bench_clean[extreme_negative_mask]) / var(bench_clean[extreme_negative_mask])
    cat(sprintf("5th Percentile Tail: %.4f (β=%.2f, p=%.4f, n=%d) %s\n", 
                ext_neg_test$estimate, ext_neg_beta, ext_neg_test$p.value, 
                sum(extreme_negative_mask, na.rm = TRUE),
                ifelse(ext_neg_test$p.value < 0.05, "*", "")))
  }
  
  # Tail asymmetry analysis
  if(!is.null(results$upper_tail) && !is.null(results$lower_tail)) {
    tail_asymmetry <- results$lower_tail$correlation - results$upper_tail$correlation
    beta_asymmetry <- results$lower_tail$beta - results$upper_tail$beta
    cat(sprintf("Tail Asymmetry: %.4f correlation, %.2f beta (Lower - Upper)\n", tail_asymmetry, beta_asymmetry))
    if(tail_asymmetry > 0.2) {
      cat("→ Stronger downside dependence: correlations spike during crashes\n")
    } else if(tail_asymmetry < -0.2) {
      cat("→ Stronger upside dependence: correlations spike during rallies\n")
    } else {
      cat("→ Symmetric tail behavior\n")
    }
  }
  
  cat("\n* = Statistically significant (p < 0.05)\n")
  
  # =============================================================================
  # COMBINED INSIGHTS SUMMARY
  # =============================================================================
  cat("\n", paste(rep("=", 60), collapse = ""), "\n")
  cat("COMBINED ANALYSIS INSIGHTS\n")
  cat(paste(rep("=", 60), collapse = ""), "\n")
  
  # Overall assessment
  overall_strength <- abs(results$overall$correlation)
  if(overall_strength > 0.7) {
    strength_desc <- "STRONG"
  } else if(overall_strength > 0.4) {
    strength_desc <- "MODERATE" 
  } else if(overall_strength > 0.2) {
    strength_desc <- "WEAK"
  } else {
    strength_desc <- "VERY WEAK"
  }
  
  cat(sprintf("1. Overall Relationship: %s correlation (%.3f) with beta %.2f\n", 
              strength_desc, results$overall$correlation, results$overall$beta))
  
  # Risk assessment
  risk_factors <- character(0)
  
  # Check for volatility dependency
  if(!is.null(results$high_vol) && !is.null(results$low_vol)) {
    vol_diff <- results$high_vol$correlation - results$low_vol$correlation
    if(vol_diff > 0.15) {
      risk_factors <- c(risk_factors, "High volatility dependency")
    }
  }
  
  # Check for regime dependency  
  if(!is.null(results$bull) && !is.null(results$bear)) {
    regime_diff <- results$bear$correlation - results$bull$correlation
    if(regime_diff > 0.15) {
      risk_factors <- c(risk_factors, "Bear market correlation spike")
    }
  }
  
  # Check for tail dependency
  if(!is.null(results$lower_tail) && results$lower_tail$correlation > 0.6) {
    risk_factors <- c(risk_factors, "High downside tail dependence")
  }
  
  cat("2. Risk Factors:\n")
  if(length(risk_factors) > 0) {
    for(i in 1:length(risk_factors)) {
      cat(sprintf("   - %s\n", risk_factors[i]))
    }
  } else {
    cat("   - No major risk factors identified\n")
  }
  
  # Diversification assessment
  cat("3. Diversification Benefit: ")
  if(length(risk_factors) >= 2) {
    cat("LOW - correlation increases when diversification is most needed\n")
  } else if(overall_strength < 0.3) {
    cat("HIGH - provides good diversification across market conditions\n")
  } else if(overall_strength < 0.6) {
    cat("MODERATE - some diversification benefit\n")
  } else {
    cat("LOW - high correlation limits diversification benefit\n")
  }
  
  cat("\n")  
  return(results)
}

# =============================================================================
# BATCH ADVANCED ANALYSIS FUNCTION
# Processes multiple stocks with advanced correlation analysis
# =============================================================================

batch_advanced_analysis <- function(tickers, years_selected) {
  benchmarks <- c("SPY")
  
  # Calculate dates
  end_date <- Sys.Date()
  start_date <- end_date - (years_selected * 365)
  
  cat("=== BATCH ADVANCED CORRELATION ANALYSIS ===\n")
  cat("Date range:", as.character(start_date), "to", as.character(end_date), "\n")
  cat("Stocks:", paste(tickers, collapse = ", "), "\n")
  cat("Benchmarks:", paste(benchmarks, collapse = ", "), "\n\n")
  
  # Get benchmark data
  benchmark_data <- list()
  benchmark_returns <- list()
  
  for(i in 1:length(benchmarks)) {
    cat("Fetching", benchmarks[i], "...")
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
  
  # Analyze each stock against each benchmark
  all_results <- list()
  
  for(i in 1:length(tickers)) {
    ticker <- tickers[i]
    cat("\n", paste(rep("=", 80), collapse = ""), "\n")
    cat("ANALYZING:", ticker, "\n")
    cat(paste(rep("=", 80), collapse = ""), "\n")
    
    # Get stock data
    stock_data <- get_data_safe(ticker, start_date, end_date)
    
    if(!is.null(stock_data)) {
      stock_prices <- if(ncol(stock_data) >= 6) Ad(stock_data) else Cl(stock_data)
      stock_returns <- na.omit(diff(log(stock_prices)))
      
      ticker_results <- list()
      
      # Analyze against each benchmark
      for(j in 1:length(benchmarks)) {
        if(!is.null(benchmark_returns[[j]])) {
          cat("\n", paste(rep("-", 40), collapse = ""), "\n")
          result <- advanced_correlation_analysis(stock_returns, benchmark_returns[[j]], 
                                                  ticker, benchmarks[j])
          ticker_results[[benchmarks[j]]] <- result
        }
      }
      
      all_results[[ticker]] <- ticker_results
    } else {
      cat("ERROR: Could not fetch data for", ticker, "\n")
    }
  }
  
  return(all_results)
}

# =============================================================================
# SUMMARY REPORT GENERATOR
# Creates a consolidated summary of all analysis results
# =============================================================================

generate_advanced_summary <- function(all_results) {
  cat("\n", paste(rep("=", 80), collapse = ""), "\n")
  cat("PORTFOLIO ADVANCED CORRELATION SUMMARY\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  
  # Summary table
  cat("RISK ASSESSMENT SUMMARY\n")
  cat(paste(rep("-", 70), collapse = ""),"\n")
  cat(sprintf("%-8s %-8s %-8s %-6s %-12s %-12s %-15s\n", 
              "Stock", "Benchmark", "Overall", "Beta", "Bull/Bear", "Vol Effect", "Risk Level"))
  cat(paste(rep("-", 70), collapse = ""),"\n")
  
  for(stock in names(all_results)) {
    for(benchmark in names(all_results[[stock]])) {
      result <- all_results[[stock]][[benchmark]]
      
      if(!is.null(result)) {
        overall_corr <- result$overall$correlation
        overall_beta <- result$overall$beta
        
        # Calculate regime effect
        regime_effect <- "N/A"
        if(!is.null(result$bull) && !is.null(result$bear)) {
          regime_diff <- result$bear$correlation - result$bull$correlation
          regime_effect <- sprintf("%.2f", regime_diff)
        }
        
        # Calculate volatility effect
        vol_effect <- "N/A"
        if(!is.null(result$high_vol) && !is.null(result$low_vol)) {
          vol_diff <- result$high_vol$correlation - result$low_vol$correlation
          vol_effect <- sprintf("%.2f", vol_diff)
        }
        
        # Risk assessment
        risk_level <- "LOW"
        risk_count <- 0
        
        if(!is.null(result$high_vol) && !is.null(result$low_vol)) {
          if(result$high_vol$correlation - result$low_vol$correlation > 0.15) risk_count <- risk_count + 1
        }
        if(!is.null(result$bull) && !is.null(result$bear)) {
          if(result$bear$correlation - result$bull$correlation > 0.15) risk_count <- risk_count + 1
        }
        if(!is.null(result$lower_tail) && result$lower_tail$correlation > 0.6) risk_count <- risk_count + 1
        
        if(risk_count >= 2) {
          risk_level <- "HIGH"
        } else if(risk_count == 1) {
          risk_level <- "MEDIUM"
        }
        
        cat(sprintf("%-8s %-8s %-8.3f %-6.2f %-12s %-12s %-15s\n", 
                    stock, benchmark, overall_corr, overall_beta, regime_effect, vol_effect, risk_level))
      }
    }
  }
  
  cat("\nLEGEND:\n")
  cat("- Beta: Market sensitivity (1.0 = moves with market, >1.0 = amplified moves)\n")
  cat("- Bull/Bear: Difference between bear and bull market correlations\n")
  cat("- Vol Effect: Difference between high and low volatility correlations\n")
  cat("- Risk Level: HIGH = multiple risk factors, MEDIUM = some risk factors, LOW = minimal risk\n")
}