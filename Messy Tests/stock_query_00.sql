SELECT
   ticker,name, close_price
FROM
   data
WHERE
   /*
   sector IN ('Consumer Defensive', 'Healthcare','Energy','Technology','Industrials')*/
   name NOT LIKE '%Bond%'
   AND name NOT LIKE '%ETF%'
   AND name NOT LIKE '%Fund%'
   AND name NOT LIKE '%Treasury%'
   AND name NOT LIKE '%Index%'
   AND name NOT LIKE '%Acquisition%'
   AND name NOT LIKE '%pharma%'
   AND name NOT LIKE '%therap%'
   /*
   AND close_price BETWEEN 20 AND 50 
   */

   AND money_flow_2_week > 50
   /*AND macd_12_26 > macd_signal_12_26_9*/
   AND last_dividend_date is NULL

   AND parkinson_historical_volatility_10 < parkinson_historical_volatility_60
   AND parkinson_historical_volatility_10 < parkinson_historical_volatility_120
   AND (parkinson_historical_volatility_180 - parkinson_historical_volatility_10) >= 0.05


   AND previous_volume > 100000
   AND ABS((sma_10 +2/11*(close_price-sma_10)) - (sma_20 +2/21*(close_price-sma_20))) < (close_price * 0.02)
   AND ABS(sma_20 - (sma_50 +2/51*(close_price-sma_50))) < (close_price * 0.02)
   AND ABS((sma_10 +2/11*(close_price-sma_10)) - (sma_50 +2/51*(close_price-sma_50))) < (close_price * 0.02)
   AND close_price > (sma_50 +2/51*(close_price-sma_50))
   AND (sma_10 +2/11*(close_price-sma_10)) >= (sma_20 +2/21*(close_price-sma_20))
ORDER BY
   close_price ASC
