from io import StringIO
import pandas as pd
import boto3
import urllib
import json
import logging

import orders_analytics

"""
Modify this lambda function to perform the following questions

1. Find the most profitable Region, and its profit
2. What shipping method is most common for each Category
3. Output a glue table containing the number of orders for each Category and Sub Category
"""

s3 = boto3.client("s3")
output_bucket = "nmd-assignment-waleed-abdulla-output-bucket"

# Initialize the logger per https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
    try:
        #Loop through each record
        for record in event['Records']:

            #Get the bucket and key string
            bucket = record['s3']['bucket']['name']
            key = urllib.parse.unquote_plus(
                record['s3']['object']['key'],
                encoding='utf-8'
                )
            
            #Csv file name for clarity
            baseName = key.split("/")[-1].replace(".csv", "")

            logger.info(f"Processing file: {bucket}/{key}")

            #Get file from S3 input bucket
            obj = s3.get_object(Bucket=bucket, Key=key)
            csv_data = obj['Body'].read().decode('utf-8')

            data = pd.read_csv(StringIO(csv_data))

            logger.info(f"CSV loading success")

            #Analytics functions
            orderProfits = orders_analytics.calculate_profit_by_order(data)[['Order Id', 'Profit']]
            mostProfitableRegion = orders_analytics.calculate_most_profitable_region(data)
            mostCommonShipMethod = orders_analytics.find_most_common_ship_method(data)
            ordersPerCategory = orders_analytics.find_number_of_order_per_category(data)

            analytics = {
                "orderProfits":orderProfits,
                "mostProfitableRegion":mostProfitableRegion,
                "mostCommonShipMethod":mostCommonShipMethod,
                "ordersPerCategory":ordersPerCategory
                }
            
            #Upload Analysis
            for name, file in analytics.items():
                csvBuffer = StringIO()
                file.to_csv(csvBuffer, index=False)

                outputKey = f"reports/{name}/{baseName}.csv"

                s3.put_object(
                    Bucket = output_bucket,
                    Key = outputKey,
                    Body = csvBuffer.getvalue(),
                    ContentType = "text/csv"
                )

                logger.info(f"Uploaded {outputKey}")
        
        return {
            "statusCode": 200,
            "body": json.dumps("Processing complete")
        }
    
    except Exception as e:
        logger.error(f"Error processing file: {str(e)}")
        raise e


