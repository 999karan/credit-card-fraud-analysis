"""
Credit Card Fraud Project — Python Phase
Step 1: Extract data from MySQL into Pandas
Step 2: Basic cleaning checks
Step 3: Simple feature engineering
"""

import pandas as pd
import numpy as np
from sqlalchemy import create_engine

# ---------------------------------------------------------
# 1. Connect to MySQL
# ---------------------------------------------------------
from urllib.parse import quote_plus

import os
try:
    from dotenv import load_dotenv
    load_dotenv()          # reads DB_USER / DB_PASSWORD from a local .env file
except ImportError:
    pass

USER = os.getenv("DB_USER", "root")
PASSWORD = quote_plus(os.getenv("DB_PASSWORD", ""))
HOST = "127.0.0.1"
PORT = 3306
DATABASE = "credit_card_fraud"

engine = create_engine(
    f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}"
)

# ---------------------------------------------------------
# 2. Extract data into a DataFrame
# ---------------------------------------------------------
query = "SELECT * FROM transactions;"
df = pd.read_sql(query, engine)

print("Shape:", df.shape)
print(df.head())
print(df.dtypes)

# ---------------------------------------------------------
# 3. Basic cleaning checks
# ---------------------------------------------------------
print("\n--- Missing values per column ---")
print(df.isnull().sum())

print("\n--- Duplicate rows ---")
print(df.duplicated().sum())

print("\n--- Class distribution (fraud vs non-fraud) ---")
print(df["class"].value_counts())
print(df["class"].value_counts(normalize=True) * 100)

# ---------------------------------------------------------
# 4. Feature engineering
# ---------------------------------------------------------

# 4a. Scale 'amount'
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
df["amount_scaled"] = scaler.fit_transform(df[["amount"]])

# 4b. Log-transform amount
df["amount_log"] = np.log1p(df["amount"])

# 4c. Time-based features
df["hour_of_day_py"] = (df["time_sec"] // 3600) % 24
df["day_num_py"] = (df["time_sec"] // 86400) + 1

# 4d. Flag: is this a "night" transaction (0-6 hours)?
df["is_night"] = df["hour_of_day_py"].apply(lambda h: 1 if h < 6 else 0)

# 4e. Amount band (mirrors your SQL amount_bands lookup table)
def amount_band(amount):
    if amount <= 10:
        return "Very Low"
    elif amount <= 50:
        return "Low"
    elif amount <= 200:
        return "Medium"
    elif amount <= 1000:
        return "High"
    else:
        return "Very High"

df["amount_band"] = df["amount"].apply(amount_band)

print("\n--- Sample after feature engineering ---")
print(df[["time_sec", "amount", "amount_scaled", "amount_log",
          "hour_of_day_py", "day_num_py", "is_night", "amount_band", "class"]].head())

# ---------------------------------------------------------
# 5. Save cleaned data for the next step (EDA / Power BI)
# ---------------------------------------------------------
df.to_csv("transactions_cleaned.csv", index=False)
print("\nSaved cleaned data to transactions_cleaned.csv")