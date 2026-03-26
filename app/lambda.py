from io import StringIO
import pandas as pd
import boto3
import urllib
import json
import logging

import orders_analytics

#Represents an s3 instance
s3 = boto3.client("s3")

#Hardcoded output bucket name
output_bucket = "nmd-assignment-waleed-output-bucket"

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
                )
            
            logger.info(f"Processing file: {bucket}/{key}")

            #Get file from the S3 input bucket
            obj = s3.get_object(Bucket=bucket, Key=key)
            csv_data = obj['Body'].read().decode('utf-8')

            #Read the csv with pandas and StringIO (string -> file)
            data = pd.read_csv(StringIO(csv_data))

            logger.info(f"CSV loading success")

            #Analytical Calls
            orderProfits = orders_analytics.calculate_profit_by_order(data)
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
                s3.put_object(
                    Bucket = output_bucket,
                    Key = f"{name}.csv",
                    Body = file.to_csv(index=False),
                    ContentType = "text/csv"
                )

                logger.info(f"Uploaded {name}.csv")
        
        return {
            "statusCode": 200,
            "body": json.dumps("Processing complete")
        }
    
    except Exception as e:
        logger.error(f"Error processing file: {str(e)}")
        raise e
