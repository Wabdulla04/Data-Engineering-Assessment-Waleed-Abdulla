import pandas as pd
import boto3

data = pd.read_csv("sample_orders.csv")


import orders_analytics

orderedDF = orders_analytics.calculate_profit_by_order(data)
print(orderedDF.groupby("Region", as_index= False)["Profit"].sum().max())
print(orders_analytics.calculate_most_profitable_region(data))


"find the number of orders for each Category and Sub Category"
Categories = data.groupby(["Category"], as_index= False).size()
Subcategories = data.groupby(["Sub Category"], as_index= False).size()

mapping = data[["Category", "Sub Category"]].drop_duplicates()

result = (
    mapping
    .merge(Categories, on="Category")
    .merge(Subcategories, on="Sub Category", suffixes=("_category", "_subcat"))
)

print(result)

print(boto3.client("sts").get_caller_identity())