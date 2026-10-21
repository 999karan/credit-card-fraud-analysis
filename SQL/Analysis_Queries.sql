-- =====================================================================
-- Analysis_Queries.sql
-- Project: Credit Card Fraud Detection
-- Database: credit_card_fraud
-- Purpose: A collection of analytical queries on the "transactions"
--          table (joined with "amount_bands" where needed) to explore
--          fraud patterns.
--
-- Note on time_sec: This column represents seconds elapsed since the
-- first transaction in the dataset (dataset spans ~2 days). To get the
-- "hour of day" (0-23) regardless of which of the 2 days it falls on,
-- we take (time_sec MOD 86400) -> seconds within that day, then
-- divide by 3600 to get the hour.
-- =====================================================================

USE credit_card_fraud;


-- =====================================================================
-- QUERY 1: Total Fraud vs Non-Fraud count and percentage
-- ---------------------------------------------------------------------
-- Gives the raw count of fraud (class=1) and non-fraud (class=0)
-- transactions, along with what percentage each makes up of the total.
-- Useful for understanding class imbalance in the dataset.
-- =====================================================================
SELECT
    class,
    CASE WHEN class = 1 THEN 'Fraud' ELSE 'Non-Fraud' END AS transaction_type,
    COUNT(*) AS total_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions), 4) AS percentage
FROM transactions
GROUP BY class
ORDER BY class;


-- =====================================================================
-- QUERY 2: Fraud rate by Hour of Day
-- ---------------------------------------------------------------------
-- Converts time_sec into an hour-of-day value (0-23) using
-- (time_sec MOD 86400) / 3600, then calculates how many transactions
-- occurred in each hour and what fraction of those were fraudulent.
-- Helps spot whether fraud clusters around specific hours.
-- =====================================================================
SELECT
    FLOOR((time_sec % 86400) / 3600) AS hour_of_day,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN class = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(SUM(CASE WHEN class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS fraud_rate_percent
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- =====================================================================
-- QUERY 3: Average Amount - Fraud vs Non-Fraud
-- ---------------------------------------------------------------------
-- Compares the average transaction amount for fraudulent transactions
-- against non-fraudulent ones. Helps check whether fraud tends to
-- happen at higher, lower, or similar amounts compared to normal
-- transactions.
-- =====================================================================
SELECT
    CASE WHEN class = 1 THEN 'Fraud' ELSE 'Non-Fraud' END AS transaction_type,
    COUNT(*) AS total_count,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(MIN(amount), 2) AS min_amount,
    ROUND(MAX(amount), 2) AS max_amount
FROM transactions
GROUP BY class
ORDER BY class;


-- =====================================================================
-- QUERY 4: Amount Band wise Fraud Count
-- ---------------------------------------------------------------------
-- Joins the "transactions" table with the "amount_bands" lookup table
-- (based on where each transaction's amount falls between min_amount
-- and max_amount) and counts fraud vs non-fraud transactions within
-- each band. Helps identify which amount range is most prone to fraud.
-- =====================================================================
SELECT
    ab.band_name,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.class = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(SUM(CASE WHEN t.class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS fraud_rate_percent
FROM transactions t
JOIN amount_bands ab
    ON t.amount >= ab.min_amount
    AND (t.amount <= ab.max_amount OR ab.max_amount IS NULL)
GROUP BY ab.band_name, ab.band_id
ORDER BY ab.band_id;


-- =====================================================================
-- QUERY 5: Night (12 AM - 6 AM) vs Day Fraud Rate Comparison
-- ---------------------------------------------------------------------
-- Buckets each transaction into "Night" (hour 0 to 5, i.e. 12 AM to
-- just before 6 AM) or "Day" (hour 6 to 23) using the same
-- hour-of-day logic as Query 2, then compares the fraud rate between
-- the two periods.
-- =====================================================================
SELECT
    CASE
        WHEN FLOOR((time_sec % 86400) / 3600) BETWEEN 0 AND 5 THEN 'Night (12AM-6AM)'
        ELSE 'Day (6AM-12AM)'
    END AS time_period,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN class = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(SUM(CASE WHEN class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 4) AS fraud_rate_percent
FROM transactions
GROUP BY time_period
ORDER BY time_period;


-- =====================================================================
-- QUERY 6: Top 10 Highest Amount Fraud Transactions
-- ---------------------------------------------------------------------
-- Lists the 10 fraudulent transactions (class=1) with the highest
-- amounts. Useful for spotting the biggest-value fraud cases that may
-- need priority investigation.
-- =====================================================================
SELECT
    transaction_id,
    time_sec,
    FLOOR((time_sec % 86400) / 3600) AS hour_of_day,
    amount,
    class
FROM transactions
WHERE class = 1
ORDER BY amount DESC
LIMIT 10;

-- =====================================================================
-- END OF SCRIPT
-- =====================================================================
