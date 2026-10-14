# Olist Delivery Performance & Customer Satisfaction

A business-analytics case study on 96,476 delivered orders from Olist,
Brazil's largest e-commerce marketplace.

**Simulated portfolio project.** No real client. All figures derived from
the public Brazilian E-Commerce Public Dataset by Olist (Kaggle).

---

## Business questions

1. What is the overall on-time delivery rate?
2. Which states have the worst delivery performance?
3. Which product categories suffer the longest delivery times?
4. How much does a late delivery cost us in review score?
5. Which stage of the fulfillment pipeline causes the most delay?

## Headline findings

| # | Finding |
|---|---|
| 1 | Overall on-time rate is 91.89% (7,827 late out of 96,476 delivered). |
| 2 | On-time performance varies 5x by state. AL 23.9% late vs PR 5.0%. |
| 3 | office_furniture takes 20.6 days on average vs 12-day median. |
| 4 | Late orders average 2.57 review stars vs 4.30 on-time. 7x more 1-star. |
| 5 | Last-mile is 74% of delivery time. Handoff and approval are minor. |
| 6 | Three months show dips: Nov 2017, Feb 2018, Mar 2018 (78.6%). |

---

## Deliverables

| File | What it is |
|---|---|
| notebooks/olist_delivery_analysis.ipynb | Full pipeline (audit to charts) |
| data/processed/project.db | SQLite database - 7 cleaned tables |
| outputs/reports/olist_delivery_report.xlsx | 6-sheet Excel workbook |
| outputs/reports/olist_dashboard.html | Interactive HTML dashboard |
| outputs/figures/ | 5 chart PNGs (300 DPI) |
| docs/DECISIONS.md | Dictionary, KPIs, cleaning log, assumptions |

---

## Method

**Pipeline:** Load, Audit, Client checkpoint, Clean, Derive fields,
SQL handoff, SQL analysis, Reconcile, Charts, Document.

**Key decisions:**

- Universe = order_status delivered AND delivery date not null (96,476 orders).
- Window = Jan 2017 - Aug 2018.
- Customer identity = customer_unique_id (not customer_id).
- Derived fields computed once in Pandas.
- Anomalies flagged, not deleted: sequence_anomaly (738), sequence_anomaly_severe (14),
  impossible_delivery (23), migration_artifact (71).
- Review duplicates resolved with a source-of-truth rule (1,128 quarantined to CSV).

**Sacred rules applied:**

- Raw data never edited.
- No silent fixes - every change in the cleaning log.
- Grain checked before every join.
- Every headline KPI computed twice (SQL + Pandas).
- Valid extremes kept; anomalies flagged.

---

## How to run

Install dependencies:

    pip install -r requirements.txt

Then open the notebook and run all cells top to bottom.
Expected runtime: ~2 minutes.

The notebook is idempotent: it deletes and recreates project.db,
quarantine files, and outputs on each run.

---

## Data quality summary

| Issue | Rows | Action |
|---|---|---|
| Missing delivery date | 2,965 | Filtered by universe |
| Duplicate review_ids | 814 | Deduplicated (kept 1) |
| Duplicate order_ids in reviews | 314 | Deduplicated (kept latest) |
| Missing product category | 610 | Relabelled unknown_category |
| Carrier/approval anomalies | 1,359 | Flagged, kept |
| Impossible deliveries | 23 | Flagged, excluded from time KPIs |
| Migration artifacts | 71 | Flagged, excluded from averages |

---

## Limitations

- No cost data. Cannot compute profit or margin.
- No carrier or route data. Cannot prove WHY Northeast is slower.
- Simulated case study. Real data, no paying client.
- Review-score correlation is not causation.
- Analysis window excludes Sep-Dec 2016 and Sep-Oct 2018.
- Review dedup kept latest; sensitivity check would test alternatives.

## Tools

Python 3.11, pandas, numpy, matplotlib, plotly, openpyxl, sqlite3.
Built in Google Colab with Drive persistence.

## License

MIT for the code. Data license follows the original Kaggle dataset.
