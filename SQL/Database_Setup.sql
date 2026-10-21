-- =====================================================================
-- Database_Setup.sql
-- Project: Credit Card Fraud Detection
-- Purpose: Create database, main transactions table, a supporting
--          amount_bands lookup table, and performance indexes.
-- =====================================================================


-- =====================================================================
-- SECTION 1: DATABASE CREATION
-- ---------------------------------------------------------------------
-- Creates the "credit_card_fraud" database if it doesn't already exist,
-- and switches the active session to use it.
-- =====================================================================
CREATE DATABASE IF NOT EXISTS credit_card_fraud
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE credit_card_fraud;


-- =====================================================================
-- SECTION 2: TRANSACTIONS TABLE
-- ---------------------------------------------------------------------
-- Main table storing every credit card transaction along with its
-- PCA-transformed features (v1 to v28), amount, and fraud label.
--
-- Data type notes:
--   - transaction_id : Unique identifier for each row (Primary Key,
--                       auto-incrementing since raw dataset usually
--                       does not provide an explicit ID).
--   - time_sec        : Seconds elapsed since the first transaction in
--                       the dataset. Stored as INT (whole seconds).
--   - v1 to v28       : PCA-transformed anonymized features. These are
--                       continuous decimal values with high precision,
--                       so DOUBLE is used to avoid truncation.
--   - amount          : Transaction amount in currency units. DECIMAL
--                       is used (instead of FLOAT/DOUBLE) since money
--                       values need exact precision, not floating
--                       point approximation.
--   - class           : Fraud label -> 0 = Non-Fraud, 1 = Fraud.
--                       Stored as TINYINT(1) since it's binary.
--
-- Dataset note: Verified against the uploaded creditcard.csv
-- (2,84,807 rows). Amount ranges from 0.00 to 25,691.16, and the
-- data is heavily imbalanced -> 2,84,315 non-fraud (Class=0) vs
-- only 492 fraud (Class=1), i.e. ~0.17% fraud rate. DECIMAL(12,2)
-- comfortably covers the amount range with exact precision.
-- =====================================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
    time_sec        INT NOT NULL,

    -- PCA-transformed anonymized features (V1 to V28)
    v1  DOUBLE, v2  DOUBLE, v3  DOUBLE, v4  DOUBLE, v5  DOUBLE,
    v6  DOUBLE, v7  DOUBLE, v8  DOUBLE, v9  DOUBLE, v10 DOUBLE,
    v11 DOUBLE, v12 DOUBLE, v13 DOUBLE, v14 DOUBLE, v15 DOUBLE,
    v16 DOUBLE, v17 DOUBLE, v18 DOUBLE, v19 DOUBLE, v20 DOUBLE,
    v21 DOUBLE, v22 DOUBLE, v23 DOUBLE, v24 DOUBLE, v25 DOUBLE,
    v26 DOUBLE, v27 DOUBLE, v28 DOUBLE,

    amount          DECIMAL(12, 2) NOT NULL,
    class           TINYINT(1) NOT NULL DEFAULT 0,

    -- Timestamp for when the row was inserted into this table
    -- (useful for auditing/tracking, not part of original dataset)
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- =====================================================================
-- SECTION 3: AMOUNT_BANDS LOOKUP TABLE
-- ---------------------------------------------------------------------
-- A lookup/reference table that categorizes transaction amounts into
-- readable bands (Very Low, Low, Medium, High, Very High). This can be
-- used for analysis, reporting, or joining with the transactions table
-- based on amount ranges.
--
-- min_amount / max_amount define the range boundaries for each band.
-- max_amount is NULL for the topmost band (Very High) to represent
-- "no upper limit".
-- =====================================================================
CREATE TABLE IF NOT EXISTS amount_bands (
    band_id     INT AUTO_INCREMENT PRIMARY KEY,
    band_name   VARCHAR(20) NOT NULL,
    min_amount  DECIMAL(12, 2) NOT NULL,
    max_amount  DECIMAL(12, 2) NULL,   -- NULL = no upper bound
    description VARCHAR(100)
) ENGINE=InnoDB;

-- NOTE: Ranges below are based on the actual distribution of the
-- "Amount" column in the source dataset (creditcard.csv, ~2.85 lakh
-- rows). They roughly correspond to the 25th, 50th, 75th and 95th
-- percentiles, so each band captures a meaningful chunk of real data
-- instead of arbitrary round numbers.
--   25th percentile  ~ 5.60
--   50th percentile  ~ 22.00
--   75th percentile  ~ 77.17
--   95th percentile  ~ 365.00
--   max amount       ~ 25,691.16
INSERT INTO amount_bands (band_name, min_amount, max_amount, description)
VALUES
    ('Very Low',  0.00,    5.60,      'Bottom 25% of transactions (smallest amounts)'),
    ('Low',       5.61,    22.00,     '25th to 50th percentile of transactions'),
    ('Medium',    22.01,   77.17,     '50th to 75th percentile of transactions'),
    ('High',      77.18,   365.00,    '75th to 95th percentile of transactions'),
    ('Very High', 365.01,  NULL,      'Top 5% of transactions (largest amounts, up to 25,691.16)');


-- =====================================================================
-- SECTION 4: INDEXES FOR PERFORMANCE
-- ---------------------------------------------------------------------
-- Fraud detection queries frequently filter/group by "class" (fraud
-- vs non-fraud) and by "time_sec" (time-based analysis/trends).
-- Adding indexes on these columns speeds up such lookups significantly
-- on large datasets.
-- =====================================================================
CREATE INDEX idx_transactions_class     ON transactions (class);
CREATE INDEX idx_transactions_time_sec  ON transactions (time_sec);

-- =====================================================================
-- END OF SCRIPT
-- =====================================================================
