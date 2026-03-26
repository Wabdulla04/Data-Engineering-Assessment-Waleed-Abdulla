#Input bucket that receives the CSV file
resource "aws_s3_bucket" "input_s3" {
  bucket = "${local.app_name}-input-bucket"
  tags = merge({
        Name        = "${local.app_name}-input-bucket"
        Environment = "${var.env}"
        Owner       = "waleed"
    }, local.default_tags
  )
  force_destroy = true
}

#Output bucket that holds the analytical CSV files
resource "aws_s3_bucket" "output_s3" {
  bucket = "${local.app_name}-output-bucket"
  tags = merge({
        Name        = "${local.app_name}-output-bucket"
        Environment = "${var.env}"
        Owner       = "waleed"
    }, local.default_tags
  )
  force_destroy = true
}

#Connects main.tf and passes variables to the Lambda module
module "lambda_function" {
  source                  = "../modules/lambda"
  lambda_name             = "${local.app_name}-file-processor"
  role_name               = "${local.app_name}-file-processor-role"
  log_retention_in_days   = 14
  image_uri               = "${module.ecr_repo.repository_url}:latest"
  timeout                 = 15
  memory_size             = 256
  environment_variables   = {
    EXAMPLE_VAR = "value"
  }
  default_tags = merge(local.default_tags, {Owner = "waleed"})

}

#Connects main.tf and passes variables to the ECR module
module "ecr_repo" {
  source    = "../modules/ecr-repo"
  repo_name = "${local.app_name}-ecr"
  default_tags = merge(local.default_tags, {Owner = "waleed"})
}

#Manages the input bucket's notification to trigger on the creation of a CSV file
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.input_s3.id
  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }
}

#Provides the input bucket permission to trigger the lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = "${local.app_name}-file-processor"
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::nmd-assignment-waleed-input-bucket"
}