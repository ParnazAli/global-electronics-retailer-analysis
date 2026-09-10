"""
data_prep.py
------------
Shared data loading, cleaning, and enrichment utilities for the
Global Electronics Retailer analysis project.

Every analysis notebook in this project imports from this module so that
data cleaning logic lives in exactly one place and stays consistent
across the Sales, Geographic, Product, and Customer Segmentation modules.
"""

from pathlib import Path
import pandas as pd

DATA_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"


def _clean_money_column(series: pd.Series) -> pd.Series:
    """Convert a currency-formatted string column (e.g. '$1,234.56 ') to float."""
    return (
        series.astype(str)
        .str.replace(r"[\$,]", "", regex=True)
        .str.strip()
        .astype(float)
    )


def load_products() -> pd.DataFrame:
    """Load Products.csv with cleaned price/cost columns."""
    df = pd.read_csv(DATA_DIR / "Products.csv")
    df["Unit Cost USD"] = _clean_money_column(df["Unit Cost USD"])
    df["Unit Price USD"] = _clean_money_column(df["Unit Price USD"])
    return df


def load_customers() -> pd.DataFrame:
    """Load Customers.csv (latin-1 encoded) with parsed birthdays."""
    df = pd.read_csv(DATA_DIR / "Customers.csv", encoding="latin1")
    df["Birthday"] = pd.to_datetime(df["Birthday"], errors="coerce")
    return df


def load_stores() -> pd.DataFrame:
    """Load Stores.csv. StoreKey == 0 represents the online storefront."""
    df = pd.read_csv(DATA_DIR / "Stores.csv")
    df["Open Date"] = pd.to_datetime(df["Open Date"], errors="coerce")
    df["Store Type"] = df["StoreKey"].apply(lambda k: "Online" if k == 0 else "In-Store")
    return df


def load_exchange_rates() -> pd.DataFrame:
    """Load Exchange_Rates.csv. Rate = units of `Currency` per 1 USD."""
    df = pd.read_csv(DATA_DIR / "Exchange_Rates.csv")
    df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    return df


def load_sales(fillna_delivery=False) -> pd.DataFrame:
    """Load Sales.csv with parsed dates.

    Note: ~79% of orders have a missing Delivery Date. We keep these as
    NaT (not delivered / delivery not recorded) rather than imputing a
    value, since fabricating delivery dates would distort delivery-time
    analysis. Each notebook treats this explicitly.
    """
    df = pd.read_csv(DATA_DIR / "Sales.csv")
    df["Order Date"] = pd.to_datetime(df["Order Date"], errors="coerce")
    df["Delivery Date"] = pd.to_datetime(df["Delivery Date"], errors="coerce")
    return df


def build_sales_fact_table() -> pd.DataFrame:
    """Join Sales with Products, Stores, and Customers into one analysis-ready table.

    Revenue methodology
    --------------------
    Product prices in `Products.csv` (Unit Cost USD / Unit Price USD) are
    already denominated in USD -- this is the retailer's list price.
    `Currency Code` in the Sales table only records which currency the
    customer's local transaction was settled in; it does NOT mean the
    price itself needs converting. Therefore:

        Revenue (USD) = Quantity * Unit Price USD
        Cost    (USD) = Quantity * Unit Cost USD
        Profit  (USD) = Revenue (USD) - Cost (USD)

    No exchange-rate division/multiplication is applied to the USD
    revenue figures. The Exchange_Rates table is used separately (see
    `add_local_currency_revenue`) only when we explicitly want to restate
    USD revenue in local-currency terms for regional reporting -- that is
    an additional view, not a correction to the USD figures.
    """
    sales = load_sales()
    products = load_products()
    stores = load_stores()
    customers = load_customers()

    df = sales.merge(
        products[
            [
                "ProductKey",
                "Product Name",
                "Brand",
                "Color",
                "Unit Cost USD",
                "Unit Price USD",
                "Subcategory",
                "Category",
            ]
        ],
        on="ProductKey",
        how="left",
    )
    df = df.merge(
        stores[["StoreKey", "Country", "State", "Store Type", "Square Meters"]],
        on="StoreKey",
        how="left",
        suffixes=("", "_store"),
    )
    df = df.merge(
        customers[["CustomerKey", "Gender", "Birthday", "Country", "Continent"]],
        on="CustomerKey",
        how="left",
        suffixes=("_store", "_customer"),
    )

    df["Revenue_USD"] = df["Quantity"] * df["Unit Price USD"]
    df["Cost_USD"] = df["Quantity"] * df["Unit Cost USD"]
    df["Profit_USD"] = df["Revenue_USD"] - df["Cost_USD"]
    df["Profit_Margin"] = df["Profit_USD"] / df["Revenue_USD"]

    df["Is_Delivered"] = df["Delivery Date"].notna()
    df["Delivery_Lag_Days"] = (df["Delivery Date"] - df["Order Date"]).dt.days

    df["Order_Year"] = df["Order Date"].dt.year
    df["Order_Month"] = df["Order Date"].dt.month
    df["Order_YearMonth"] = df["Order Date"].dt.to_period("M").dt.to_timestamp()

    return df


def add_local_currency_revenue(df: pd.DataFrame) -> pd.DataFrame:
    """Restate USD revenue in the currency the order was settled in.

    Exchange_Rates stores `Exchange` as units of local currency per 1 USD
    on a given date, so:  Local amount = USD amount * Exchange rate.
    This is used only for local/regional reporting views, never to
    "correct" the USD figures.
    """
    fx = load_exchange_rates().rename(
        columns={"Currency": "Currency Code", "Exchange": "FX_Rate"}
    )
    out = df.merge(fx, left_on=["Order Date", "Currency Code"], right_on=["Date", "Currency Code"], how="left")
    out["Revenue_Local"] = out["Revenue_USD"] * out["FX_Rate"]
    return out.drop(columns=["Date"])
