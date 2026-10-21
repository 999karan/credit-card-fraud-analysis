"""
Credit Card Fraud Project — EDA & Visualization Phase
Reads transactions_cleaned.csv (already extracted/cleaned in the previous Python step)
and generates key EDA charts using Matplotlib/Seaborn.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("whitegrid")

# ---------------------------------------------------------
# 1. Load the cleaned data
# ---------------------------------------------------------
df = pd.read_csv("transactions_cleaned.csv")

print("Shape:", df.shape)
print(df.head())

# ---------------------------------------------------------
# 2. Fraud vs Non-Fraud Count
# ---------------------------------------------------------
plt.figure(figsize=(6, 5))
class_counts = df["class"].value_counts()
sns.barplot(x=["Non-Fraud (0)", "Fraud (1)"], y=class_counts.values, color="steelblue")
plt.title("Fraud vs Non-Fraud Transaction Count")
plt.ylabel("Number of Transactions")
plt.tight_layout()
plt.savefig("chart_fraud_vs_nonfraud_count.png")
plt.close()
print("Saved chart_fraud_vs_nonfraud_count.png")

# ---------------------------------------------------------
# 3. Amount Distribution: Fraud vs Non-Fraud (log scale, since Amount is skewed)
# ---------------------------------------------------------
plt.figure(figsize=(10, 5))
sns.histplot(
    data=df, x="amount_log", hue="class", bins=50,
    palette={0: "steelblue", 1: "crimson"}, alpha=0.6, element="step"
)
plt.title("Amount Distribution (log-scaled): Fraud vs Non-Fraud")
plt.xlabel("Log(Amount + 1)")
plt.ylabel("Count")
plt.tight_layout()
plt.savefig("chart_amount_distribution.png")
plt.close()
print("Saved chart_amount_distribution.png")

# ---------------------------------------------------------
# 4. Fraud Rate by Hour of Day
# ---------------------------------------------------------
hourly_fraud = df.groupby("hour_of_day_py")["class"].mean().reset_index()
hourly_fraud["fraud_rate_pct"] = hourly_fraud["class"] * 100

plt.figure(figsize=(12, 5))
plt.plot(hourly_fraud["hour_of_day_py"], hourly_fraud["fraud_rate_pct"], marker="o", color="crimson")
plt.title("Fraud Rate (%) by Hour of Day")
plt.xlabel("Hour of Day")
plt.ylabel("Fraud Rate (%)")
plt.xticks(range(0, 24))
plt.tight_layout()
plt.savefig("chart_fraud_rate_by_hour.png")
plt.close()
print("Saved chart_fraud_rate_by_hour.png")

# ---------------------------------------------------------
# 5. Fraud Count by Amount Band
# ---------------------------------------------------------
band_order = ["Very Low", "Low", "Medium", "High", "Very High"]
fraud_by_band = (
    df[df["class"] == 1]["amount_band"]
    .value_counts()
    .reindex(band_order)
    .reset_index()
)
fraud_by_band.columns = ["amount_band", "fraud_count"]

plt.figure(figsize=(8, 5))
sns.barplot(data=fraud_by_band, x="amount_band", y="fraud_count", color="darkorange")
plt.title("Fraud Count by Amount Band")
plt.xlabel("Amount Band")
plt.ylabel("Number of Fraud Transactions")
plt.tight_layout()
plt.savefig("chart_fraud_by_amount_band.png")
plt.close()
print("Saved chart_fraud_by_amount_band.png")

# ---------------------------------------------------------
# 6. Night vs Day Fraud Rate
# ---------------------------------------------------------
night_fraud = df.groupby("is_night")["class"].mean().reset_index()
night_fraud["fraud_rate_pct"] = night_fraud["class"] * 100
night_fraud["label"] = night_fraud["is_night"].map({0: "Day (6am-12am)", 1: "Night (12am-6am)"})

plt.figure(figsize=(6, 5))
sns.barplot(data=night_fraud, x="label", y="fraud_rate_pct", color="purple")
plt.title("Fraud Rate: Night vs Day")
plt.ylabel("Fraud Rate (%)")
plt.xlabel("")
plt.tight_layout()
plt.savefig("chart_fraud_night_vs_day.png")
plt.close()
print("Saved chart_fraud_night_vs_day.png")

# ---------------------------------------------------------
# 7. Correlation Heatmap (numeric columns only, sampled if large)
# ---------------------------------------------------------
numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
# Keep it readable — drop extremely high-dimensional PCA columns if too many,
# otherwise this will just plot everything (V1-V28 + amount + class etc.)
corr = df[numeric_cols].corr()

plt.figure(figsize=(16, 12))
sns.heatmap(corr, cmap="coolwarm", center=0, cbar=True)
plt.title("Correlation Heatmap (All Numeric Features)")
plt.tight_layout()
plt.savefig("chart_correlation_heatmap.png")
plt.close()
print("Saved chart_correlation_heatmap.png")

print("\nAll charts saved in the project folder.")