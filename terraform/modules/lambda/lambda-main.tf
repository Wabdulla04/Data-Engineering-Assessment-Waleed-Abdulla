# Lambda IAM Role
resource "aws_iam_role" "lambda_exec_role" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.default_tags
}

# Attach the basic execution policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = var.log_retention_in_days
}

# Lambda Function
resource "aws_lambda_function" "lambda_function" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = var.image_uri
  
  image_config {
    command = ["lambda.lambda_handler" ]
  }
  
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = var.environment_variables
  }

  tags = var.default_tags
}

#Provides Lambda IAM permissions to ONLY get objects and put objects into S3 buckets
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.lambda_name}-s3-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = [
          "arn:aws:s3:::nmd-assignment-waleed-input-bucket/*",
          "arn:aws:s3:::nmd-assignment-waleed-output-bucket/*"
        ]
      }
    ]
  }
  )
}