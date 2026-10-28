# Digital-Payment-Fraud-and-Risk-Analysis
(https://github.com/user-attachments/files/34073456/README.md)
# Digital Payment Risk & Fraud Analysis

An end-to-end analytics project that explores **when, where and how fraud occurs** in digital payments, using **Python, SQL (MySQL) and Power BI**. It includes a rule-based risk-scoring model, and tests whether that model actually separates fraudulent from legitimate transactions.

---

## Business Problem

A digital payments company wants to understand:

- What is the overall fraud rate and the value lost to fraud?
- Which payment modes, transaction types, devices, locations and hours carry more fraud?
- Do risk signals (IP risk, failed attempts, login attempts, account age, international transactions) identify fraud?
- Can a simple risk score help flag transactions for review?

## Dataset

- **Source:** synthetic digital-payment fraud dataset (7,500 transactions, 15 columns, no missing values, no duplicate transaction IDs).
- **Key fields:** `transaction_amount`, `transaction_type`, `payment_mode`, `device_type`, `device_location`, `account_age_days`, `transaction_hour`, `previous_failed_attempts`, `ip_risk_score`, `login_attempts_last_24h`, `is_international`, `fraud_label` (1 = fraud).
- The currency is not specified in the dataset, so amounts are shown as-is.

## Tools Used

| Tool | Purpose |
|---|---|
| Python (pandas, matplotlib, seaborn) | Data checks, EDA, feature engineering (category bands), cleaned dataset |
| MySQL | Data quality checks, cleaned view, business questions, rule-based risk scoring, Power BI dataset view |
| Power BI | Two-page interactive dashboard |

## Project Workflow

1. **Python (`notebook/`)**: validated the data (nulls, duplicates, ranges), explored fraud by payment mode, transaction type, device, hour, international vs domestic, and created category bands (amount, account age, failed attempts, IP risk, login attempts). Exported `Digital_Payment_Fraud_Analytics_Cleaned.csv`.
2. **SQL (`sql/`)**: loaded the cleaned data into MySQL, ran data quality checks, built the `transaction_clean` view, answered business questions, and built a points-based risk score (`transaction_risk_scored`, `transaction_risk_final`) plus a `powerbi_risk_dataset` view.
3. **Power BI (`dashboard/`)**: built an executive overview page and a risk scoring page with slicers for location, payment mode, transaction type and device.

## Dashboard

**Page 1: Executive Overview**

![Executive Overview](images/Executive_Overview_.png)

**Page 2: Risk Scoring**

![Risk Scoring](images/Risk_Scoring.png)

## Key Findings

**Overall:** 489 of 7,500 transactions are fraudulent (**6.52%**), worth about **11.86M** in total.

| Dimension | Highest fraud rate | Lowest fraud rate |
|---|---|---|
| Payment mode | Card (7.06%) | Wallet (6.16%) |
| Transaction type | Withdrawal (6.80%) | Payment (6.33%) |
| Device | Android (6.94%) | Web (5.99%) |
| Location | Mumbai (7.31%) | Delhi (5.78%) |
| Hour of day | 19:00 (9.3%), 14:00 (9.1%) | n/a |
| Scope | Domestic (6.64%) | International (5.43%) |

**Risk score validation (an honest result):**

| Calculated risk level | Transactions | Fraud rate |
|---|---|---|
| Low | 2,745 | 6.5% |
| Medium | 4,168 | 6.5% |
| High | 561 | 6.8% |
| Critical | 26 | 7.7% |

- Fraud is spread almost evenly across every segment: most differences are about 1 percentage point, and correlations between the numeric risk signals and `fraud_label` are all close to zero (below 0.03).
- My rule-based score **does not meaningfully separate fraud from legitimate transactions** on this dataset. Fraud rates are about the same from Low to Critical, and the Critical band has only 26 rows.
- International transactions do not show higher fraud than domestic ones here, which goes against the usual assumption.
- This is likely a limitation of the synthetic data, which has little real fraud signal built in. I'm reporting it rather than forcing a story the data doesn't support.

## Limitations

- Synthetic data, so findings do not reflect real-world fraud behaviour.
- Fraud is only about 6.5% of transactions, and several segment differences are small enough to be random variation. I did not run formal significance tests.
- The score weights were chosen by hand (domain assumptions), not learned from data.
- `risk_level` in the cleaned CSV and the dashboard is based on IP-risk quantiles (named `source_risk_level` in SQL). The points-based `calculated_risk_level` lives in the SQL views.

## Known Issues

- On the dashboard, the *Total Transactions Value* card shows 113.47M, but the total from the cleaned CSV is **186.10M** (average transaction 24,813.53). The Fraud Count, Fraud Amount and Fraud Rate cards match the data.
- The *Fraud Level* donut and the *IP Risk Category* table on the dashboard cover 1,000 records rather than all 7,500, so treat them as illustrative.

## Next Steps

- Run significance tests (chi-square) on the segment differences.
- Train a classification model (e.g. logistic regression) and compare it with the rule-based score using precision, recall and ROC-AUC.
- Handle class imbalance and calibrate score thresholds on real labelled data.

## Repository Structure

```
├── data/
│   ├── Digital_Payment_Fraud_Detection_Dataset.csv      # raw data
│   └── Digital_Payment_Fraud_Analytics_Cleaned.csv      # cleaned data with category columns
├── notebook/
│   └── Digital_Payment_Risk_and_Fraud_Analysis.ipynb
├── sql/
│   └── Digital_Payment_Risk_and_Fraud_Analysis.sql
├── dashboard/
│   └── Digital_Payment_Risk_and_Fraud_Analysis.pbix
├── images/
│   ├── Executive_Overview.png
│   └── Risk_Scoring.png
└── README.md
```

## How to Run

1. Open the notebook and run all cells (the raw CSV is read from `data/`).
2. In MySQL, run the SQL script: it creates the database and `transactions` table. Import `Digital_Payment_Fraud_Analytics_Cleaned.csv` into `transactions` (for example with the Table Data Import Wizard), then run the rest of the script.
3. Open the `.pbix` file in Power BI Desktop. If it asks for the data source, point it to the cleaned CSV or the `powerbi_risk_dataset` view.

> **Note:** the cleaned CSV stores "None" (zero failed attempts) as text in `failed_attempt_category`. Pandas and MySQL import can read it as NULL; in pandas use `keep_default_na=False`. The SQL view `transaction_clean` already handles this.

## About Me

**Jerry A. Yonith Spenser**: B.Com graduate (2026) with a Data Analytics certification from FITA Academy, based in Chennai and looking for junior analyst roles.

- LinkedIn: [linkedin.com/in/jerry-a-yonith-spenser](https://linkedin.com/in/jerry-a-yonith-spenser)
- GitHub: [github.com/Jerry171-hue](https://github.com/Jerry171-hue)
- Email: yonithj@gmail.com
