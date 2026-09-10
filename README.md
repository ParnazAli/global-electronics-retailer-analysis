# Global Electronics Retailer — End-to-End Sales & Business Analysis

A four-part data analysis of a global electronics retailer's 2016–2021 sales history, covering **Sales Performance**, **Geographic Performance**, **Product Performance**, and **Customer Segmentation**. Originally built as a Power BI dashboard set; rebuilt here as a reproducible Python analysis with an emphasis on data-quality rigor — every module surfaces at least one non-obvious, verified finding rather than just restating totals.

## Why this project is structured the way it is

Rather than a single dashboard of metrics, each module follows the same discipline:
**Research Question → Methodology → Findings → Business Conclusions.** Findings are only reported after being checked against the raw data (e.g., a recurring "seasonal dip" turned out to be a data-export bug once the daily order counts were inspected — see Module 1).

## Highlight findings

- **A ~37-day zero-order gap recurs every year (2016–2020)** — a data-collection artifact, not real seasonality. Flagged and excluded from trend interpretation. (Module 1)
- **The 2020 revenue decline is real** and does not recover by the end of the dataset (Feb 2021), consistent with COVID-19's impact on in-store retail. (Module 1)
- **US stores are ~2.8x more revenue-productive per square meter than Australian stores** — a much more useful lens than raw country revenue rankings. (Module 2)
- **9 of 66 physical stores (14%) show zero recorded sales** across the entire 5-year window despite opening years ago — flagged as a data-quality issue. (Module 2)
- **Games and Toys is the only category weak on both revenue and margin.** Home Appliances began declining in 2019, *before* COVID — a category-specific problem, not a pandemic effect. (Module 3)
- **The top 10% of customers generate 36% of revenue**, while age and gender show almost no relationship to customer value — behavioral segmentation beats demographic segmentation here. (Module 4)

## Repository structure

```
├── data/raw/               Original CSV extracts (Sales, Customers, Products, Stores, Exchange Rates)
├── notebooks/
│   ├── 01_sales_performance.ipynb
│   ├── 02_geographic_performance.ipynb
│   ├── 03_product_performance.ipynb
│   └── 04_customer_segmentation.ipynb
├── src/
│   ├── data_prep.py        Shared data loading, cleaning, and the fact-table builder
│   └── viz_style.py        Shared chart styling (colors, fonts, formatters)
├── reports/figures/        Exported PNG charts used in each notebook
└── requirements.txt
```

## Data & revenue methodology

Data: [Global Electronics Retailer](https://mavenanalytics.io/data-playground/global-electronics-retailer) (Maven Analytics) — 5 relational CSVs (Sales, Customers, Products, Stores, Exchange Rates).

**Revenue is computed as `Quantity × Unit Price USD`** using the retailer's USD list price from `Products.csv`. The `Currency Code` field on each order records only which currency the transaction was locally settled in — it is not a signal that the USD figures need further conversion. This was verified by reproducing the original dashboards' totals exactly before doing any further analysis. The `Exchange_Rates` table is used only where explicitly noted, to restate USD figures in local currency for regional reporting.

## How to run

```bash
pip install -r requirements.txt
jupyter notebook notebooks/01_sales_performance.ipynb
```

Each notebook is self-contained and can be run independently; all four import shared logic from `src/`.

## Tech stack

Python · pandas · matplotlib · seaborn · Jupyter
