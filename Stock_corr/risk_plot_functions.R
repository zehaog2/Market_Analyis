library(ggplot2)
library(ggimage)

#' Create Portfolio Risk Assessment Matrix Plot
#' @param all_results List of correlation analysis results from batch_advanced_analysis()
#' @param icon_dir Directory containing ticker icon files (default: "ticker_icons")
#' @param use_icons Boolean to use stock logos (TRUE) or colored points (FALSE)
#' @return ggplot object
create_risk_matrix_plot <- function(all_results, icon_dir = "ticker_icons", use_icons = FALSE) {
  # Build the risk data frame
  risk_data <- data.frame()
  
  for(stock in names(all_results)) {
    for(benchmark in names(all_results[[stock]])) {
      result <- all_results[[stock]][[benchmark]]
      
      if(!is.null(result$overall)) {
        # Calculate volatility effect
        vol_effect <- 0
        if(!is.null(result$high_vol) && !is.null(result$low_vol)) {
          vol_effect <- result$high_vol$correlation - result$low_vol$correlation
        }
        
        # Calculate regime effect
        regime_effect <- 0
        if(!is.null(result$bear) && !is.null(result$bull)) {
          regime_effect <- result$bear$correlation - result$bull$correlation
        }
        
        risk_data <- rbind(risk_data, data.frame(
          Stock = stock,
          Benchmark = benchmark,
          Overall_Corr = result$overall$correlation,
          Vol_Effect = vol_effect,
          Regime_Effect = regime_effect,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  # Return empty plot if no data
  if(nrow(risk_data) == 0) {
    return(
      ggplot() +
        labs(title = "Portfolio Risk Assessment Matrix",
             subtitle = "No sufficient data available for risk matrix") +
        theme_minimal() +
        theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
    )
  }
  
  # Get unique stocks and aggregate data
  unique_stocks <- unique(risk_data$Stock)
  agg_data <- data.frame()
  
  for(stock in unique_stocks) {
    stock_subset <- risk_data[risk_data$Stock == stock, ]
    
    agg_data <- rbind(agg_data, data.frame(
      Stock = stock,
      Vol_Effect = mean(stock_subset$Vol_Effect, na.rm = TRUE),
      Regime_Effect = mean(stock_subset$Regime_Effect, na.rm = TRUE),
      Overall_Corr = mean(abs(stock_subset$Overall_Corr), na.rm = TRUE),
      stringsAsFactors = FALSE
    ))
  }
  
  # Fix common ticker symbol inconsistencies
  agg_data$Stock_Display <- agg_data$Stock
  
  # Create plot with ticker names only (no circles)
  p <- ggplot(agg_data, aes(x = Vol_Effect, y = Regime_Effect, color = Stock_Display)) +
    geom_text(aes(label = Stock_Display), 
              hjust = 0.5, vjust = 0.5, 
              size = 4, fontface = "bold", 
              show.legend = FALSE) +
    scale_color_viridis_d(name = "Stock") +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5, color = "gray60") +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5, color = "gray60") +
    labs(
      title = "Portfolio Risk Assessment Matrix",
      subtitle = "Position indicates conditional correlation risk",
      x = "Volatility Effect (High Vol − Low Vol Correlation)",
      y = "Regime Effect (Bear − Bull Correlation)",
      caption = "Upper-right quadrant indicates highest conditional risk"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray60"),
      plot.caption = element_text(size = 10, color = "gray60"),
      legend.position = "none",
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "gray80", fill = NA, linewidth = 0.5)
    )
  
  # Add quadrant annotations
  max_x <- max(abs(agg_data$Vol_Effect), na.rm = TRUE)
  max_y <- max(abs(agg_data$Regime_Effect), na.rm = TRUE)
  
  if(max_x > 0 && max_y > 0) {
    p <- p +
      annotate("text", x = max_x * 0.75, y = max_y * 0.75, 
               label = "HIGH RISK", size = 3.5, color = "red", 
               alpha = 0.7, fontface = "bold") +
      annotate("text", x = -max_x * 0.75, y = -max_y * 0.75, 
               label = "DEFENSIVE", size = 3.5, color = "darkgreen", 
               alpha = 0.7, fontface = "bold")
  }
  
  return(p)
}