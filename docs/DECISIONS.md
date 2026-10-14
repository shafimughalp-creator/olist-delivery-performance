# Decisions log

## 0. Project Overview

**Project:** Olist Delivery Performance & Customer Satisfaction
**Domain:** Brazilian e-commerce marketplace
**Client:** Simulated case study for portfolio (no real client)
**Intended user:** Olist's operations / logistics team
**Business problem:** Late deliveries damage customer satisfaction. We need to
find where the fulfillment pipeline fails, quantify the cost in review scores,
and identify the worst-performing regions, categories, and sellers.

**Main questions:**
1. What is the overall on-time delivery rate?
2. Which states/regions have the worst delivery performance?
3. Which product categories suffer the longest delivery times?
4. How much does a late delivery cost in review score?
5. Which stage of the pipeline causes the most delay?

**Deliverables:**
- Cleaned CSV + SQLite database
- SQL queries (sql/ folder)
- Excel workbook (KPI overview, detail, data-quality log, definitions)
- Plotly HTML dashboard (KPI cards + bar/line/pie charts)

**Definition of done:**
- Every headline KPI computed in SQL AND Pandas, reconciled
- Every cleaning decision logged
- README + DECISIONS.md complete
- Notebook reruns from raw CSVs to final outputs

**Optional stages:**
- Step 7 (Outliers): YES - delivery times likely have extremes
- Step 8 (Derived fields): YES - delivery_days, is_late, stage_durations
- Step 13 (Automation): NO - one-time portfolio piece

---

## 1. Data dictionary

### Tables in scope

| Table | Grain (one row = ?) | Primary key | Rows |
|---|---|---|---|
| orders | one order | order_id | 99,441 |
| customers | one customer identity per order | customer_id | 99,441 |
| order_items | one product line within an order | (order_id, order_item_id) | 112,650 |
| order_reviews | one review per (review_id, order_id) | (review_id, order_id) | 99,224 |
| products | one product | product_id | 32,951 |
| sellers | one seller | seller_id | 3,095 |
| category_translation | one PT->EN category mapping | product_category_name | 71 |

### Tables out of scope (documented reason)

| Table | Reason |
|---|---|
| order_payments | Payment method does not affect delivery timing |
| geolocation | 1M rows, 53 per zip prefix; customers.customer_state already answers geographic questions |

### Key columns in orders

| Column | Meaning | Nulls |
|---|---|---|
| order_id | order identifier | 0 (unique) |
| customer_id | per-order customer key | 0 |
| order_status | one of 8 statuses | 0 |
| order_purchase_timestamp | when order was placed | 0 |
| order_approved_at | payment approved | 160 |
| order_delivered_carrier_date | handed to carrier | 1,783 |
| order_delivered_customer_date | delivered to customer | 2,965 (= non-delivered orders) |
| order_estimated_delivery_date | promised delivery date | 0 |

### Critical warning: customer keys

customers.customer_id = unique per order (99,441 unique values).
customers.customer_unique_id = persistent identity across orders (96,096 unique; 3,345 duplicates).

Use customer_unique_id for per-customer aggregation.

### Date coverage

- order_purchase_timestamp: 2016-09-04 -> 2018-10-17
- Analysis window chosen: 2017-01-01 -> 2018-08-31
  Reason: Sep-Dec 2016 has <400 orders; Oct 2018 incomplete.

### Order status distribution

| Status | Count |
|---|---|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

### Review score distribution

| Score | Count | % |
|---|---|---|
| 1 | 11,424 | 11.5% |
| 2 | 3,151 | 3.2% |
| 3 | 8,179 | 8.2% |
| 4 | 19,142 | 19.3% |
| 5 | 57,328 | 57.8% |

Note: bimodal (U-shaped), not normal.

### Pipeline stage definitions

Four measurable stages between the 5 order timestamps:

| Stage | Formula | What it measures |
|---|---|---|
| 1. Approval | approved_at - purchase_timestamp | Payment confirmation time |
| 2. Handoff to carrier | delivered_carrier_date - approved_at | Seller packing + dispatch time |
| 3. Last-mile delivery | delivered_customer_date - delivered_carrier_date | Carrier delivery time |
| 4. End-to-end | delivered_customer_date - purchase_timestamp | Total fulfillment time |

The 5th timestamp (estimated_delivery_date) is a PROMISE, not a stage.
- On-time delivery = delivered_customer_date <= estimated_delivery_date
- Lateness (days) = delivered_customer_date - estimated_delivery_date

---

## 2. KPI definitions

### Order population
Analysis universe = orders with order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL.

### Analysis window
purchase date: 2017-01-01 to 2018-08-31

| KPI | Formula | Exclusions | Grain |
|---|---|---|---|
| On-Time Delivery Rate | on-time / delivered | non-delivered, NULL | order |
| Avg Lateness (Late) | avg(delivered - estimated) where late | on-time orders | order |
| Avg Days to Deliver | avg(delivered - purchased) | non-delivered | order |
| Review: Late vs On-Time | avg review_score split by lateness | no review | order |
| Stage Durations | diff between 5 timestamps | missing timestamps | order |
| Worst Sellers | bottom 10% on-time, min 20 orders | <20 orders | seller |

---

## 3. Cleaning log

### Action 1 - Review deduplication (order_reviews)

**Issue:** 814 duplicate review_ids + 551 duplicate order_ids in reviews.

**Investigation:** Two distinct patterns:
- Case B (same review_id, different order_id): 789 groups, ALL with identical scores. System artifact.
- Case A (same order_id, different review_id): 547 orders, 202 with differing scores. Legitimate re-reviews.

**Rule 1 (Case B):** Keep one row per review_id (deterministic — scores identical).
**Rule 2 (Case A):** Keep the LATEST review by review_creation_date. Reason: customer's final
opinion. Examples show escalation (5->4, 3->1), so keeping latest preserves the honest settled view.

**Rule 3:** Removed rows saved to reviews_quarantine.csv. No deletions.

**Reconciliation:**

| Metric | Before | After | Change |
|---|---|---|---|
| Rows | 99,224 | 98,096 | -1,128 (-1.14%) |
| Unique review_id | 98,410 | 98,096 | -314 |
| Unique order_id  | 98,673 | 98,096 | -577 |
| Mean score | 4.0864 | 4.0888 | +0.0024 (+0.06%) |

**Files:**
- data/processed/reviews_clean.csv (98,096 rows)
- data/processed/reviews_quarantine.csv (1,128 rows)

**Impact:** Negligible on score distribution. No material distortion.

---

### Actions 2-5 - Audit findings, no data change

| # | Issue | Decision | Reason |
|---|---|---|---|
| 2 | 610 products with no category | KEEP as null; label as unknown_category in charts | Deleting products would drop orders; imputation not justified |
| 3 | 1,359 carrier/approval anomalies | KEEP with sequence_anomaly flag | Timezone + backdating artifacts, not errors |
| 4 | 23 impossible deliveries | KEEP, exclude from time KPIs | 0.02% of data |
| 5 | All other Step 4 flags | KEEP as-is | Audited, no action |

## 4. Client answers and assumptions
(simulated project - all answers are analyst decisions, logged as assumptions)

| # | Question | Decision | Reason |
|---|---|---|---|
| 1 | 1,359 rows: carrier_date < approved_at | Investigate; if gap clusters <6h, treat as timezone artifact and KEEP rows | BRT (UTC-3) vs UTC mixing is likely |
| 2 | 23 rows: delivered_customer < delivered_carrier | Exclude from time-based KPIs, keep in count KPIs | Impossible sequence; 0.024% of data |
| 3 | 8 rows: status='delivered' but no delivery date | Auto-excluded by analysis universe filter | Universe requires delivery date NOT NULL |
| 4 | 6 rows: status='canceled' but has delivery date | Keep as canceled (status field wins) | Status is authoritative |
| 5 | 4 products: zero weight | Keep; log as likely free/digital items | Does not affect delivery analysis |

## 5. Skipped steps
- Skipped order_payments table: not relevant to delivery timing
- Skipped geolocation table: customers table already has state/city

## 6. Limitations

- No cost data. Revenue and margin cannot be computed.
- No carrier or route data. Northeast lateness is observed, not explained.
- Simulated case study. Real data, no real client.
- Review score is a correlation, not causation.
- Analysis window excludes Sep-Dec 2016 and Sep-Oct 2018.
- Review dedup rule (keep latest) is defensible but not the only valid rule.

## 7. Handoff checklist

- [x] README.md - problem, findings, method, how to run
- [x] requirements.txt - pinned library versions
- [x] .gitignore - protects raw data and generated outputs
- [x] docs/DECISIONS.md - dictionary, KPIs, cleaning log, assumptions, limitations
- [x] data/processed/project.db - 7 clean tables
- [x] outputs/reports/olist_delivery_report.xlsx
- [x] outputs/reports/olist_dashboard.html
- [x] outputs/figures/ - 5 print-quality PNGs
- [x] Notebook reruns end-to-end from raw data
