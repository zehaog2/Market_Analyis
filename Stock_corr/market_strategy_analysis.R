# market_strategy_analysis.R
# Comprehensive Market Strategy Analysis PDF Generator

library(ggplot2)
library(gridExtra)
library(grid)
library(knitr)
library(kableExtra)

generate_market_strategy_pdf <- function(output_filename = NULL) {
  
  if(is.null(output_filename)) {
    output_filename <- paste0("market_strategy_analysis_", format(Sys.Date(), "%Y%m%d"), ".pdf")
  }
  
  cat("=== Generating Market Strategy Analysis PDF ===\n")
  cat("Output file:", output_filename, "\n")
  
  # Start PDF device
  pdf(output_filename, width = 11, height = 8.5)
  
  tryCatch({
    # Page 1: Title and Overview
    create_strategy_title_page()
    
    # Page 2: Risk Matrix Position Explanation
    create_risk_matrix_explanation_page()
    
    # Page 3: Bull Market Strategy Matrix
    create_bull_market_strategy_page()
    
    # Page 4: Bear Market Strategy Matrix
    create_bear_market_strategy_page()
    
    # Page 5: Sideways Market Strategy Matrix
    create_sideways_market_strategy_page()
    
    # Page 6: Beta Impact Analysis
    create_beta_impact_analysis_page()
    
    # Page 7: Comprehensive Strategy Summary
    create_comprehensive_strategy_summary_page()
    
    # Page 8: Practical Implementation Guide
    create_implementation_guide_page()
    
    cat("Market Strategy Analysis PDF generated successfully!\n")
    
  }, error = function(e) {
    cat("Error generating PDF:", e$message, "\n")
  }, finally = {
    dev.off()
  })
  
  return(output_filename)
}

# =============================================================================
# PAGE 1: TITLE PAGE
# =============================================================================

create_strategy_title_page <- function() {
  plot.new()
  
  # Title
  text(0.5, 0.9, "Market Strategy Analysis", 
       cex = 2.5, font = 2, col = "darkblue")
  
  # Subtitle
  text(0.5, 0.82, "Risk Matrix Positioning & Beta Strategy Guide", 
       cex = 1.5, col = "darkblue")
  
  # Date
  text(0.5, 0.75, paste("Generated:", format(Sys.Date(), "%B %d, %Y")), 
       cex = 1.2)
  
  # Overview
  text(0.5, 0.65, "Analysis Framework:", cex = 1.3, font = 2)
  
  framework_items <- c(
    "• Risk Matrix: 4 quadrants based on volatility and regime effects",
    "• Beta Analysis: High (>1.0) vs Low (<1.0) sensitivity",
    "• Market Conditions: Bull, Bear, and Sideways scenarios",
    "• Strategy Grades: A+ (excellent) to D (poor) ratings"
  )
  
  for(i in 1:length(framework_items)) {
    text(0.5, 0.58 - (i-1) * 0.04, framework_items[i], cex = 1.1)
  }
  
  # Disclaimer
  text(0.5, 0.35, "Strategic Guidelines:", cex = 1.3, font = 2)
  text(0.5, 0.28, "This analysis provides theoretical frameworks for portfolio positioning", cex = 1)
  text(0.5, 0.24, "based on correlation patterns and market sensitivity.", cex = 1)
  text(0.5, 0.18, "Past performance does not guarantee future results.", cex = 0.9, col = "red")
  
  # Legend
  text(0.5, 0.08, "Risk Matrix Quadrants: Upper-Left | Upper-Right | Lower-Left | Lower-Right", 
       cex = 1, font = 2)
}

# =============================================================================
# PAGE 2: RISK MATRIX EXPLANATION
# =============================================================================

create_risk_matrix_explanation_page <- function() {
  plot.new()
  
  # Title
  text(0.5, 0.95, "Risk Matrix Position Explanation", 
       cex = 2, font = 2, col = "darkblue")
  
  # Create visual representation of quadrants
  # Draw axes
  segments(0.2, 0.5, 0.8, 0.5, lwd = 2)  # X-axis
  segments(0.5, 0.3, 0.5, 0.7, lwd = 2)  # Y-axis
  
  # Add axis labels
  text(0.9, 0.5, "Volatility Effect", cex = 1.2, font = 2)
  text(0.5, 0.75, "Regime Effect", cex = 1.2, font = 2, srt = 90)
  
  # Quadrant labels and explanations
  # Upper-Left
  rect(0.2, 0.5, 0.5, 0.7, col = "lightblue", border = "blue")
  text(0.35, 0.6, "UPPER-LEFT", cex = 1.1, font = 2)
  text(0.35, 0.78, "Vol Effect < 0, Regime Effect > 0", cex = 0.9)
  text(0.35, 0.76, "Less correlated in volatility", cex = 0.8)
  text(0.35, 0.74, "More correlated in bear markets", cex = 0.8)
  
  # Upper-Right
  rect(0.5, 0.5, 0.8, 0.7, col = "lightcoral", border = "red")
  text(0.65, 0.6, "UPPER-RIGHT", cex = 1.1, font = 2)
  text(0.65, 0.78, "Vol Effect > 0, Regime Effect > 0", cex = 0.9)
  text(0.65, 0.76, "More correlated in volatility", cex = 0.8)
  text(0.65, 0.74, "More correlated in bear markets", cex = 0.8)
  
  # Lower-Left
  rect(0.2, 0.3, 0.5, 0.5, col = "lightgreen", border = "green")
  text(0.35, 0.4, "LOWER-LEFT", cex = 1.1, font = 2)
  text(0.35, 0.22, "Vol Effect < 0, Regime Effect < 0", cex = 0.9)
  text(0.35, 0.20, "Less correlated in volatility", cex = 0.8)
  text(0.35, 0.18, "Less correlated in bear markets", cex = 0.8)
  
  # Lower-Right
  rect(0.5, 0.3, 0.8, 0.5, col = "lightyellow", border = "orange")
  text(0.65, 0.4, "LOWER-RIGHT", cex = 1.1, font = 2)
  text(0.65, 0.22, "Vol Effect > 0, Regime Effect < 0", cex = 0.9)
  text(0.65, 0.20, "More correlated in volatility", cex = 0.8)
  text(0.65, 0.18, "Less correlated in bear markets", cex = 0.8)
  
  # Beta explanation
  text(0.5, 0.12, "Beta Impact:", cex = 1.3, font = 2)
  text(0.5, 0.08, "High Beta (>1.0): Amplifies market moves | Low Beta (<1.0): Dampens market moves", 
       cex = 1.1)
  text(0.5, 0.04, "Beta multiplies the correlation effect when stocks move together", cex = 1)
}

# =============================================================================
# PAGE 3: BULL MARKET STRATEGY
# =============================================================================

create_bull_market_strategy_page <- function() {
  # Create strategy matrix for bull market
  bull_data <- data.frame(
    Position = c("Upper-Left", "Upper-Right", "Lower-Left", "Lower-Right"),
    High_Beta = c("B+", "C", "A", "B+"),
    Low_Beta = c("C+", "D+", "B", "C"),
    High_Beta_Desc = c(
      "Good upside, protected from volatility, vulnerable to bear transition",
      "Good upside, vulnerable to volatility AND bear markets",
      "Good upside, maximum protection from all risks",
      "Good upside, vulnerable to volatility, protected from bear markets"
    ),
    Low_Beta_Desc = c(
      "Limited upside, some protection",
      "Limited upside, high risk",
      "Limited upside, maximum protection",
      "Limited upside, mixed protection"
    )
  )
  
  # Create the visualization
  plot.new()
  
  # Title
  text(0.5, 0.95, "Bull Market Strategy Matrix", 
       cex = 2, font = 2, col = "darkgreen")
  
  # Create strategy grid
  create_strategy_grid(bull_data, "Bull Market Conditions")
  
  # Key insights
  text(0.5, 0.25, "Bull Market Key Insights:", cex = 1.3, font = 2)
  
  insights <- c(
    "• Lower-Left + High Beta: Optimal strategy (Grade A)",
    "• Upper-Right + High Beta: Avoid - high risk when volatility hits",
    "• High Beta essential for bull market participation",
    "• Protection during corrections more important than bear market protection"
  )
  
  for(i in 1:length(insights)) {
    text(0.5, 0.20 - (i-1) * 0.03, insights[i], cex = 1.1)
  }
}

# =============================================================================
# PAGE 4: BEAR MARKET STRATEGY
# =============================================================================

create_bear_market_strategy_page <- function() {
  # Create strategy matrix for bear market
  bear_data <- data.frame(
    Position = c("Upper-Left", "Upper-Right", "Lower-Left", "Lower-Right"),
    High_Beta = c("D", "F", "A-", "A-"),
    Low_Beta = c("C", "D", "A+", "A"),
    High_Beta_Desc = c(
      "Amplifies bear market losses, no protection",
      "Amplifies losses with maximum correlation",
      "Some protection but high beta limits benefit",
      "Good protection with some amplification risk"
    ),
    Low_Beta_Desc = c(
      "Limited losses but still correlated",
      "Maximum losses with correlation",
      "Maximum protection with limited losses",
      "Good protection with dampened losses"
    )
  )
  
  plot.new()
  
  # Title
  text(0.5, 0.95, "Bear Market Strategy Matrix", 
       cex = 2, font = 2, col = "darkred")
  
  # Create strategy grid
  create_strategy_grid(bear_data, "Bear Market Conditions")
  
  # Key insights
  text(0.5, 0.25, "Bear Market Key Insights:", cex = 1.3, font = 2)
  
  insights <- c(
    "• Lower-Left + Low Beta: Optimal defensive strategy (Grade A+)",
    "• Upper-Right positions: Avoid completely (Grade D-F)",
    "• Low Beta essential for limiting losses",
    "• Negative regime effect more important than volatility effect"
  )
  
  for(i in 1:length(insights)) {
    text(0.5, 0.20 - (i-1) * 0.03, insights[i], cex = 1.1)
  }
}

# =============================================================================
# PAGE 5: SIDEWAYS MARKET STRATEGY
# =============================================================================

create_sideways_market_strategy_page <- function() {
  # Create strategy matrix for sideways market
  sideways_data <- data.frame(
    Position = c("Upper-Left", "Upper-Right", "Lower-Left", "Lower-Right"),
    High_Beta = c("B", "C-", "A-", "C+"),
    Low_Beta = c("B+", "C", "A", "B"),
    High_Beta_Desc = c(
      "Amplifies small moves, protected from volatility",
      "Amplifies volatility, vulnerable to whipsaws",
      "Best balance of protection and opportunity",
      "Mixed - vulnerable to choppy action"
    ),
    Low_Beta_Desc = c(
      "Stable with some protection",
      "Vulnerable to market choppiness",
      "Maximum stability and protection",
      "Decent stability with mixed protection"
    )
  )
  
  plot.new()
  
  # Title
  text(0.5, 0.95, "Sideways Market Strategy Matrix", 
       cex = 2, font = 2, col = "darkorange")
  
  # Create strategy grid
  create_strategy_grid(sideways_data, "Sideways Market Conditions")
  
  # Key insights
  text(0.5, 0.25, "Sideways Market Key Insights:", cex = 1.3, font = 2)
  
  insights <- c(
    "• Lower-Left positions: Consistently perform well",
    "• Upper-Right positions: Vulnerable to whipsaws and volatility",
    "• Beta preference depends on volatility level",
    "• Focus on consistency over amplification"
  )
  
  for(i in 1:length(insights)) {
    text(0.5, 0.20 - (i-1) * 0.03, insights[i], cex = 1.1)
  }
}

# =============================================================================
# HELPER FUNCTION: CREATE STRATEGY GRID
# =============================================================================

create_strategy_grid <- function(data, title) {
  # Create visual grid
  grid_x <- c(0.2, 0.45, 0.7)
  grid_y <- c(0.75, 0.6, 0.45)
  
  # Headers
  text(0.325, 0.82, "High Beta (>1.0)", cex = 1.2, font = 2)
  text(0.575, 0.82, "Low Beta (<1.0)", cex = 1.2, font = 2)
  
  # Position labels and grades
  for(i in 1:4) {
    y_pos <- grid_y[ifelse(i <= 2, 1, 2)]
    if(i %in% c(2, 4)) y_pos <- grid_y[3]
    
    # Position name
    text(0.1, y_pos, data$Position[i], cex = 1.1, font = 2)
    
    # High Beta grade and description
    grade_color <- get_grade_color(data$High_Beta[i])
    text(0.325, y_pos + 0.02, data$High_Beta[i], cex = 1.4, font = 2, col = grade_color)
    text(0.325, y_pos - 0.02, data$High_Beta_Desc[i], cex = 0.8, adj = 0.5)
    
    # Low Beta grade and description
    grade_color <- get_grade_color(data$Low_Beta[i])
    text(0.575, y_pos + 0.02, data$Low_Beta[i], cex = 1.4, font = 2, col = grade_color)
    text(0.575, y_pos - 0.02, data$Low_Beta_Desc[i], cex = 0.8, adj = 0.5)
  }
}

# =============================================================================
# PAGE 6: BETA IMPACT ANALYSIS
# =============================================================================

create_beta_impact_analysis_page <- function() {
  plot.new()
  
  # Title
  text(0.5, 0.95, "Beta Impact Analysis", 
       cex = 2, font = 2, col = "darkblue")
  
  # Create beta impact examples
  text(0.5, 0.88, "How Beta Amplifies Risk Matrix Effects", cex = 1.4, font = 2)
  
  # Example scenarios
  scenarios <- list(
    list(
      title = "Lower-Left + High Beta (β = 1.8)",
      example = "Market drops 10%, Stock correlation drops to 0.3",
      calc = "Expected move: 10% × 0.3 × 1.8 = 5.4% decline",
      assessment = "Good protection - correlation drops, beta amplifies smaller move"
    ),
    list(
      title = "Upper-Right + High Beta (β = 1.8)",
      example = "Market drops 10%, Stock correlation rises to 0.9",
      calc = "Expected move: 10% × 0.9 × 1.8 = 16.2% decline",
      assessment = "Disaster - correlation rises, beta amplifies larger move"
    ),
    list(
      title = "Lower-Left + Low Beta (β = 0.4)",
      example = "Market rises 10%, Stock correlation drops to 0.3",
      calc = "Expected move: 10% × 0.3 × 0.4 = 1.2% gain",
      assessment = "Limited upside - protection comes at cost of participation"
    ),
    list(
      title = "Upper-Right + Low Beta (β = 0.4)",
      example = "Market rises 10%, Stock correlation rises to 0.9",
      calc = "Expected move: 10% × 0.9 × 0.4 = 3.6% gain",
      assessment = "Limited upside but also limited downside protection"
    )
  )
  
  y_start <- 0.78
  for(i in 1:length(scenarios)) {
    scenario <- scenarios[[i]]
    y_pos <- y_start - (i-1) * 0.16
    
    # Title
    text(0.5, y_pos, scenario$title, cex = 1.2, font = 2)
    
    # Example
    text(0.5, y_pos - 0.03, scenario$example, cex = 1)
    
    # Calculation
    text(0.5, y_pos - 0.06, scenario$calc, cex = 1, font = 2, col = "blue")
    
    # Assessment
    text(0.5, y_pos - 0.09, scenario$assessment, cex = 1, col = "darkgreen")
  }
  
  # Key takeaway
  text(0.5, 0.12, "Key Takeaway:", cex = 1.3, font = 2)
  text(0.5, 0.08, "Beta amplifies whatever correlation effect occurs", cex = 1.2)
  text(0.5, 0.04, "Choose beta based on your confidence in the position's correlation behavior", cex = 1.1)
}

# =============================================================================
# PAGE 7: COMPREHENSIVE STRATEGY SUMMARY
# =============================================================================

create_comprehensive_strategy_summary_page <- function() {
  plot.new()
  
  # Title
  text(0.5, 0.95, "Comprehensive Strategy Summary", 
       cex = 2, font = 2, col = "darkblue")
  
  # All-weather rankings
  text(0.5, 0.88, "All-Weather Strategy Rankings", cex = 1.4, font = 2)
  
  # Create ranking table
  rankings <- data.frame(
    Rank = 1:8,
    Strategy = c(
      "Lower-Left + Low Beta",
      "Lower-Left + High Beta", 
      "Lower-Right + Low Beta",
      "Upper-Left + Low Beta",
      "Lower-Right + High Beta",
      "Upper-Left + High Beta",
      "Upper-Right + Low Beta",
      "Upper-Right + High Beta"
    ),
    Score = c("A+", "A-", "B+", "B", "B-", "C+", "D+", "F"),
    Rationale = c(
      "Maximum protection, consistent performance",
      "Good protection, bull market participation",
      "Bear protection, limited volatility risk",
      "Some protection, limited participation",
      "Mixed protection, moderate participation",
      "Volatility protection, bear market risk",
      "High correlation risk, limited upside",
      "Maximum risk, vulnerable to all conditions"
    )
  )
  
  # Display rankings
  y_start <- 0.78
  for(i in 1:8) {
    y_pos <- y_start - (i-1) * 0.07
    
    # Rank
    text(0.05, y_pos, rankings$Rank[i], cex = 1.1, font = 2)
    
    # Strategy
    text(0.35, y_pos, rankings$Strategy[i], cex = 1.1, font = 2)
    
    # Score
    score_color <- get_grade_color(rankings$Score[i])
    text(0.6, y_pos, rankings$Score[i], cex = 1.2, font = 2, col = score_color)
    
    # Rationale
    text(0.95, y_pos, rankings$Rationale[i], cex = 0.9, adj = 1)
  }
  
  # Bottom line
  text(0.5, 0.15, "Bottom Line Recommendation:", cex = 1.3, font = 2)
  text(0.5, 0.10, "Focus on Lower-Left quadrant positions for consistent performance", cex = 1.2)
  text(0.5, 0.06, "Adjust beta based on market outlook and risk tolerance", cex = 1.1)
}

# =============================================================================
# PAGE 8: IMPLEMENTATION GUIDE
# =============================================================================

create_implementation_guide_page <- function() {
  plot.new()
  
  # Title
  text(0.5, 0.95, "Practical Implementation Guide", 
       cex = 2, font = 2, col = "darkblue")
  
  # Portfolio allocation suggestions
  text(0.5, 0.88, "Suggested Portfolio Allocations", cex = 1.4, font = 2)
  
  # Conservative portfolio
  text(0.25, 0.82, "Conservative Portfolio", cex = 1.2, font = 2, col = "darkgreen")
  conservative <- c(
    "60% Lower-Left + Low Beta",
    "25% Lower-Right + Low Beta", 
    "10% Upper-Left + Low Beta",
    "5% Cash/Bonds"
  )
  
  for(i in 1:length(conservative)) {
    text(0.25, 0.78 - (i-1) * 0.03, conservative[i], cex = 1)
  }
  
  # Aggressive portfolio
  text(0.75, 0.82, "Aggressive Portfolio", cex = 1.2, font = 2, col = "darkred")
  aggressive <- c(
    "40% Lower-Left + High Beta",
    "30% Lower-Right + High Beta",
    "20% Upper-Left + High Beta",
    "10% Lower-Left + Low Beta"
  )
  
  for(i in 1:length(aggressive)) {
    text(0.75, 0.78 - (i-1) * 0.03, aggressive[i], cex = 1)
  }
  
  # Market timing adjustments
  text(0.5, 0.60, "Market Timing Adjustments", cex = 1.4, font = 2)
  
  timing_guide <- c(
    "Expecting Bull Market: Increase high beta allocations",
    "Expecting Bear Market: Increase low beta, focus on lower quadrants",
    "Expecting Volatility: Emphasize negative volatility effect positions",
    "Uncertain Outlook: Default to Lower-Left + Low Beta core"
  )
  
  for(i in 1:length(timing_guide)) {
    text(0.5, 0.54 - (i-1) * 0.04, timing_guide[i], cex = 1.1)
  }
  
  # Monitoring and rebalancing
  text(0.5, 0.35, "Monitoring and Rebalancing", cex = 1.4, font = 2)
  
  monitoring <- c(
    "• Review risk matrix positions quarterly",
    "• Monitor correlation changes during different market conditions",
    "• Rebalance when positions drift significantly from targets",
    "• Adjust beta exposure based on volatility regime changes"
  )
  
  for(i in 1:length(monitoring)) {
    text(0.5, 0.30 - (i-1) * 0.03, monitoring[i], cex = 1.1)
  }
  
  # Final disclaimer
  text(0.5, 0.10, "Important Disclaimer:", cex = 1.2, font = 2, col = "red")
  text(0.5, 0.06, "These strategies are based on historical correlation patterns", cex = 1)
  text(0.5, 0.02, "and may not predict future performance. Consult with financial professionals.", cex = 1)
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

get_grade_color <- function(grade) {
  if(grade %in% c("A+", "A", "A-")) return("darkgreen")
  if(grade %in% c("B+", "B", "B-")) return("blue")
  if(grade %in% c("C+", "C", "C-")) return("orange")
  if(grade %in% c("D+", "D", "D-")) return("red")
  if(grade == "F") return("darkred")
  return("black")
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Example usage:
# generate_market_strategy_pdf("my_strategy_analysis.pdf")