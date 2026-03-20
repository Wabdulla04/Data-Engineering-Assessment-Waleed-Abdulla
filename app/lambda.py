import sys
import json
import os
import pandas as pd
import boto3
import awswrangler as wr
import logging

import orders_analytics

"""
Modify this lambda function to perform the following questions

1. Find the most profitable Region, and its profit
2. What shipping method is most common for each Category
3. Output a glue table containing the number of orders for each Category and Sub Category
"""

s3 = boto3.Session

# Initialize the logger per https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
logger = logging.getLogger()
logger.setLevel("INFO")

#partial code from: https://aws.plainenglish.io/aws-lambda-retrieving-s3-bucket-folders-and-reading-data-with-python-013526d58e99
def get_s3_path_from_event(event : dict) -> str:
    "Returns the S3 path from the lambda event record"

    records = event.get("Records", [])
    if not records:
        raise ValueError("No S3 Records in the event")
    
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    return (f"s3://{bucket}/{key}")

def lambda_handler(event, context):
    s3Path = get_s3_path_from_event(event)
    s3

