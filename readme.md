# Data Engineering Assessment — Waleed Abdulla

A serverless data pipeline that automatically processes CSV order data uploaded to S3, runs sales analytics, and writes the results back to S3 as separate CSV reports.

The following ReadMe.md was created with Claude.ai
---

## Application Overview

When a CSV file is uploaded to the S3 input bucket, it automatically triggers a containerized AWS Lambda function. The function reads the file, runs four analytics queries against the order data, and uploads the results as separate CSV files to the S3 output bucket.

```
S3 Input Bucket
      │
      │  s3:ObjectCreated (*.csv)
      ▼
AWS Lambda (Container)
      │
      │  Runs analytics via orders_analytics.py
      ▼
S3 Output Bucket
  ├── orderProfits.csv
  ├── mostProfitableRegion.csv
  ├── mostCommonShipMethod.csv
  └── ordersPerCategory.csv
```

---

## Input Data

The pipeline expects a CSV file with the following columns:

| Column | Description |
|---|---|
| `Order Id` | Unique order identifier |
| `Order Date` | Date the order was placed |
| `Ship Mode` | Shipping method (e.g. Standard Class, First Class) |
| `Segment` | Customer segment (e.g. Consumer, Corporate) |
| `Country` | Country of the order |
| `City` | City of the order |
| `State` | State of the order |
| `Postal Code` | Postal code |
| `Region` | Sales region (e.g. West, East, Central) |
| `Category` | Product category (e.g. Furniture, Technology) |
| `Sub Category` | Product sub-category (e.g. Chairs, Phones) |
| `Product Id` | Unique product identifier |
| `cost price` | Cost price of the product |
| `List Price` | Listed sale price of the product |
| `Quantity` | Number of units ordered |
| `Discount Percent` | Discount applied as a percentage |

---

## Analytics

Profit is calculated per order using the formula:

```
Profit = (List Price × (1 - Discount% / 100) - Cost Price) × Quantity
```

The pipeline produces four output reports:

### 1. `orderProfits.csv`
Profit calculated for each individual order.


### 2. `mostProfitableRegion.csv`
The single most profitable region based on total profit across all orders.


### 3. `mostCommonShipMethod.csv`
The most frequently used shipping method for each product category.


### 4. `ordersPerCategory.csv`
Total number of orders broken down by category and sub-category.


---

## Project Structure

```
.
├── app/
│   ├── lambda.py              # Lambda handler — reads CSV from S3, runs analytics, uploads results
│   ├── orders_analytics.py    # Analytics logic — profit, region, shipping, category functions
│   └── requirements.txt       # Python dependencies (pandas, boto3)
├── terraform/
│   ├── main/
│   │   ├── main.tf            # Root module — S3 buckets, Lambda, ECR, S3 event trigger
│   │   ├── locals.tf          # Local values (app_name, default_tags)
│   │   └── vars.tfvars        # Variable values
│   └── modules/
│       ├── lambda/
│       │   ├── lambda-main.tf       # Lambda function, IAM role, CloudWatch log group, S3 policy
│       │   ├── lambda-variables.tf  # Input variables (lambda_name, role_name, image_uri, etc.)
│       │   └── lambda-outputs.tf    # Output: lambda_arn (used by main.tf for S3 trigger)
│       └── ecr-repo/
│           ├── ecr-main.tf          # ECR repository
│           ├── ecr-variables.tf     # Input variables (repo_name, default_tags)
│           └── ecr-outputs.tf       # Outputs: repository_arn, repository_url
├── Dockerfile                 # Container image definition for Lambda
└── sample_orders.csv          # Sample data for testing
```

---

## Deployment

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- [Docker](https://www.docker.com/products/docker-desktop/) installed and running
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured

Configure your AWS profile:
```bash
aws configure --profile waleed
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-west-2
# Default output format: json
```

Verify your identity before starting:
```bash
aws sts get-caller-identity --profile waleed
```

### Step 1 — Initialize and Apply Terraform

From the repo root:
```bash
cd terraform/assignment
terraform init -migrate-state
terraform plan -var-file="vars.tfvars"
terraform apply -var-file="vars.tfvars"
```

This provisions the S3 buckets, ECR repository, Lambda function, IAM role, CloudWatch log group, and S3 event trigger.

### Step 2 — Authenticate Docker to ECR

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 888577066340.dkr.ecr.us-west-2.amazonaws.com
```

### Step 3 — Build and Push the Docker Image

From the repo root:
```bash
cd ../..
docker buildx build --platform linux/amd64 --provenance=false --no-cache --output=type=docker -t waleed-lambda .
docker tag waleed-lambda:latest 888577066340.dkr.ecr.us-west-2.amazonaws.com/nmd-assignment-waleed-ecr:latest
docker push 888577066340.dkr.ecr.us-west-2.amazonaws.com/nmd-assignment-waleed-ecr:latest
```

### Step 4 — Deploy the Lambda Function

```bash
aws lambda update-function-code `
  --function-name nmd-assignment-waleed-file-processor `
  --image-uri 888577066340.dkr.ecr.us-west-2.amazonaws.com/nmd-assignment-waleed-ecr:latest `
  --profile waleed
```

---

## Testing

### Clear the Output Bucket Before Testing

To ensure you're seeing fresh results, clear the input and output bucket before each test run:
```bash
aws s3 rm s3://nmd-assignment-waleed-output-bucket --recursive --profile waleed
aws s3 rm s3://nmd-assignment-waleed-input-bucket/sample_orders.csv --profile waleed

```

### Trigger via S3 Upload

```bash
aws s3 cp sample_orders.csv s3://nmd-assignment-waleed-input-bucket/ --profile waleed
```

This automatically triggers the Lambda function via the S3 event notification.

### Verify Output Files

Check the output bucket for results:
```bash
aws s3 ls s3://nmd-assignment-waleed-output-bucket/ --recursive --profile waleed  
```

## Future Improvements

- **Remove hardcoded values** — the AWS account ID, ECR repository URI, and bucket names are currently hardcoded in several places. These should be replaced with Terraform variables or data sources so the project can be deployed to any AWS account or region without manual edits.
- **Glue catalog integration** — the `ordersPerCategory` report currently outputs a CSV. A future improvement would be to register it as an AWS Glue catalog table.
- **Input validation** — add validation on the incoming CSV to check for missing or malformed columns before running analytics, with a clear error message rather than a pandas KeyError.