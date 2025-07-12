library(ggplot2)
library(ggimage)

#' Create Portfolio Risk Assessment Matrix Plot
#' @param all_results List of correlation analysis results from batch_advanced_analysis()
#' @param icon_dir Directory containing ticker icon files (default: "ticker_icons")
#' @param use_icons Boolean to use stock logos (TRUE) or colored points (FALSE)
#' @return ggplot object
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
  
  # Calculate image/point sizes
  abs_corr <- agg_data$Overall_Corr
  min_c <- min(abs_corr, na.rm = TRUE)
  max_c <- max(abs_corr, na.rm = TRUE)
  
  if(use_icons) {
    # Icon-based plot
    agg_data$icon <- file.path(icon_dir, paste0(agg_data$Stock_Display, ".png"))
    
    # Check for missing icons
    missing_icons <- !file.exists(agg_data$icon)
    if(any(missing_icons)) {
      cat("Warning: Missing icons for:", paste(agg_data$Stock_Display[missing_icons], collapse = ", "), "\n")
    }
    
    # Size range for images
    size_min <- 0.04
    size_max <- 0.10
    
    if(max_c - min_c == 0) {
      agg_data$img_size <- (size_min + size_max) / 2
    } else {
      agg_data$img_size <- (abs_corr - min_c) / (max_c - min_c) * (size_max - size_min) + size_min
    }
    
    # Create plot with icons
    p <- ggplot(agg_data, aes(x = Vol_Effect, y = Regime_Effect))
    
    # Add images for existing icons
    if(any(!missing_icons)) {
      p <- p + geom_image(
        data = agg_data[!missing_icons, ],
        aes(image = icon, size = img_size),
        asp = 1
      )
    }
    
    # Add text for missing icons
    if(any(missing_icons)) {
      p <- p + geom_text(
        data = agg_data[missing_icons, ],
        aes(label = Stock_Display, size = img_size * 100),
        hjust = 0.5, vjust = 0.5,
        color = "darkblue", fontface = "bold"
      )
    }
    
    p <- p + scale_size_identity()
    
  } else {
    # Point-based plot (fallback)
    p <- ggplot(agg_data, aes(x = Vol_Effect, y = Regime_Effect, 
                              size = Overall_Corr, color = Stock_Display)) +
      geom_point(alpha = 0.8) +
      geom_text(aes(label = Stock_Display), hjust = 0, vjust = 0, 
                nudge_x = 0.01, nudge_y = 0.01, size = 3, show.legend = FALSE) +
      scale_size_continuous(range = c(4, 12), name = "Abs Correlation") +
      scale_color_viridis_d(name = "Stock")
  }
  
  # Add common styling
  p <- p +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5, color = "gray60") +
    geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5, color = "gray60") +
    labs(
      title = "Portfolio Risk Assessment Matrix",
      subtitle = if(use_icons) "Icon size reflects correlation strength" else "Point size reflects correlation strength",
      x = "Volatility Effect (High Vol − Low Vol Correlation)",
      y = "Regime Effect (Bear − Bull Correlation)",
      caption = "Upper-right quadrant indicates highest conditional risk"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray60"),
      plot.caption = element_text(size = 10, color = "gray60"),
      legend.position = if(use_icons) "none" else "bottom",
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