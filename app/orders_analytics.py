import pandas as pd

def calculate_profit_by_order(orders_df):
    "Calculate profit for each order in the DataFrame"
    df = orders_df.copy()
    discount_factor = (1 - df["Discount Percent"] / 100)
    df["Profit"] = (
        (df["List Price"] * discount_factor - df["cost price"]) * df["Quantity"]
    )
    return df[["Order Id", "Profit"]]

def calculate_most_profitable_region(orders_df):
    "Calculate the most profitable region and its profit"
    df = orders_df.copy()
    discount_factor = (1 - df["Discount Percent"] / 100)
    df["Profit"] = (
        (df["List Price"] * discount_factor - df["cost price"]) * df["Quantity"]
    )
    profits = df.groupby("Region", as_index=False)["Profit"].sum()
    return profits.loc[[profits["Profit"].idxmax()]]

def find_most_common_ship_method(orders_df):
    "Find the most common shipping method for each Category"
    counts = (
        orders_df
        .groupby(["Category", "Ship Mode"])
        .size()
        .reset_index(name="count")
    )
    return counts.loc[counts.groupby("Category")["count"].idxmax()]

def find_number_of_order_per_category(orders_df):
    "Find the number of orders for each Category and Sub Category"
    return (
        orders_df
        .groupby(["Category", "Sub Category"])
        .size()
        .reset_index(name="order_count")
    )