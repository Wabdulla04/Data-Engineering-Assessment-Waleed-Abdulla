resource "aws_s3_bucket" "input_s3" {
  bucket = "${local.app_name}-input-bucket"

  tags = merge({
    Name        = "${local.app_name}-input-bucket"
    Environment = var.env
  }, local.default_tags)

  force_destroy = true
}

resource "aws_s3_bucket" "output_s3" {
  bucket = "${local.app_name}-output-bucket"

  tags = merge({
    Name        = "${local.app_name}-output-bucket"
    Environment = var.env
  }, local.default_tags)

  force_destroy = true
}

data "aws_lambda_function" "existing_lambda" {
  function_name = "${local.app_name}-file-processor"
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.existing_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_s3.arn
}

resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.input_s3.id

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.existing_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}