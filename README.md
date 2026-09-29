# Global Electronics Retailer: Sales & Business Analysis

I analyzed the 2016–2021 sales history of a global electronics retailer in four parts: sales performance, geographic performance, product performance, and customer segmentation. I first built it as a set of Power BI dashboards, then rebuilt it in Python so anyone can rerun it. I spent a lot of the time checking the data itself, so each part ends with something I verified against the raw data, not just a list of totals.

## Highlight findings

- Every year from 2016 to 2020 there is a gap of about 37 days with zero orders. It looks like a data collection problem, not real seasonality, so I left it out when reading trends. (Module 1)
- The 2020 revenue drop is real. It doesn't recover before the data ends in Feb 2021, which fits what COVID did to in-store retail. (Module 1)
- US stores make about 2.8x more revenue per square meter than Australian stores. This says more than ranking countries by total revenue. (Module 2)
- 9 of the 66 physical stores (14%) have no recorded sales at all across the 5 years, even though they opened years ago. I treated this as a data quality issue and confirmed it in SQL. (Module 2)
- Games and Toys is the only category that is weak on both revenue and margin. Home Appliances started declining in 2019, before COVID, so that one is a category problem and not a pandemic effect. (Module 3)
- The top 10% of customers bring in 36% of revenue. Age and gender barely relate to customer value, so behavior-based segments work better than demographic ones here. (Module 4)

## Dashboard Previews

<table>
  <tr>
    <td width="33%"><img src="https://raw.githubusercontent.com/ParnazAli/global-electronics-retailer-analysis/refs/heads/main/reports/figures/G1.png" alt="Dashboard 1"></td>
    <td width="33%"><img src="https://raw.githubusercontent.com/ParnazAli/global-electronics-retailer-analysis/refs/heads/main/reports/figures/G2.png" alt="Dashboard 2"></td>
    <td width="33%"><img src="https://raw.githubusercontent.com/ParnazAli/global-electronics-retailer-analysis/refs/heads/main/reports/figures/G3.png" alt="Dashboard 3"></td>
  </tr>
  <tr>
    <td align="center">Dashboard 1</td>
    <td align="center">Dashboard 2</td>
    <td align="center">Dashboard 3</td>
  </tr>
</table>

## Data & revenue methodology

The data is the [Global Electronics Retailer](https://mavenanalytics.io/data-playground/global-electronics-retailer) dataset from Maven Analytics: 5 related CSVs (Sales, Customers, Products, Stores, Exchange Rates).

Revenue is `Quantity × Unit Price USD`, using the USD list price from `Products.csv`. The `Currency Code` on an order only tells you which currency the sale was settled in, so the USD figures don't need to be converted again. I checked this by reproducing the totals from my original dashboards exactly before going further. I only use the `Exchange_Rates` table where I say so, to show USD figures in local currency for regional reporting.

## Approach

Each module follows the same steps: research question, method, findings, business conclusions. I only report a finding after checking it against the raw data. For example, what looked like a yearly seasonal dip turned out to be an export bug once I looked at the daily order counts (see Module 1).

## SQL layer

I also rebuilt every major metric in plain SQL, on a SQLite database made from the same raw CSVs:

- `src/build_database.py` loads the 5 CSVs into `data/global_electronics.db`
- `sql/queries.sql` has one `sales_fact` view and about 15 commented queries (JOINs, window functions, CTEs) that reproduce each module's key metrics
- `notebooks/00_sql_validation.ipynb` runs the pandas pipeline and the SQL queries side by side and checks that the results match exactly (they do)

So the analysis can be reproduced or audited from either the Python side or the SQL side.

## Repository structure

```
├── data/
│   ├── raw/                Original CSV extracts (Sales, Customers, Products, Stores, Exchange Rates)
│   └── global_electronics.db   SQLite database built from the raw CSVs
├── sql/
│   └── queries.sql         Pure-SQL version of every module's key metrics
├── notebooks/
│   ├── 00_sql_validation.ipynb
│   ├── 01_sales_performance.ipynb
│   ├── 02_geographic_performance.ipynb
│   ├── 03_product_performance.ipynb
│   └── 04_customer_segmentation.ipynb
├── src/
│   ├── data_prep.py         Shared data loading, cleaning, and the fact-table builder
│   ├── build_database.py    Builds the SQLite database from the raw CSVs
│   └── viz_style.py         Shared chart styling (colors, fonts, formatters)
├── reports/figures/         Exported PNG charts used in each notebook
└── requirements.txt
```

## How to run

```bash
pip install -r requirements.txt
jupyter notebook notebooks/01_sales_performance.ipynb
```

Each notebook runs on its own, and all four import shared code from `src/`.

## Tech stack

Python · pandas · matplotlib · seaborn · Jupyter · SQL (SQLite)

## Author

Hi, I'm Parnaz Ali, a data analyst and BI specialist. I did this project from start to finish. If you have questions or want to talk about it, send me an email.

[![Email](https://img.shields.io/badge/Email-parnazali1383%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:parnazali1383@gmail.com)
