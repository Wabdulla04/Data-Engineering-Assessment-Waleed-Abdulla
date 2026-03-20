resource "aws_s3_bucket" "input_s3" {
  bucket = "${local.app_name}-input-bucket"
  tags = merge({
        Name        = "${local.app_name}-input-bucket"
        Environment = "${var.env}"
    }, local.default_tags
  )
  force_destroy = true
}

resource "aws_s3_bucket" "output_s3" {
  bucket = "${local.app_name}-output-bucket"
  tags = merge({
        Name        = "${local.app_name}-output-bucket"
        Environment = "${var.env}"
    }, local.default_tags
  )
  force_destroy = true
}

#Per https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy,
#one "aws_s3_bucket_policy" should be defined per bucket, so one for input and one for output.

#Need to update/assign resource (s3 bucket) policy
resource "aws_s3_bucket_policy" "allow_access_input" {
  bucket = aws_s3_bucket.input_s3.id
  policy = data.aws_iam_policy_document.input_bucket_policy.json
}

#Need to update/assign resource (s3 bucket) policy (Cont'd)
resource "aws_s3_bucket_policy" "allow_access_output" {
  bucket = aws_s3_bucket.output_s3.id
  policy = data.aws_iam_policy_document.output_bucket_policy.json
}


#Need to *build* the policy using the data source
#Reference and data source code: https://oneuptime.com/blog/post/2026-02-23-configure-s3-bucket-policies-in-terraform/view

#When in doubt, split the data source. It's better to have one IAM policy for input and one for output.

data "aws_iam_policy_document" "input_bucket_policy" {
  # Allow the application role to read and write objects
  statement {
    sid    = "AllowAppAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::888577066340:user/waleed"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.input_s3.arn,
      "${aws_s3_bucket.input_s3.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "output_bucket_policy" {
  # Allow the application role to read and write objects
  statement {
    sid    = "AllowAppAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::888577066340:user/waleed"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.output_s3.arn,
      "${aws_s3_bucket.output_s3.arn}/*",
    ]
  }
}

/*
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

  default_tags = local.default_tags
}

module "ecr_repo" {
  source    = "../modules/ecr-repo"
  repo_name = "${local.app_name}-ecr"
  default_tags = local.default_tags
}


resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_s3.arn
}

resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = aws_s3_bucket.input_s3.id
  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "*"
    filter_suffix       = ".csv"
  }
}
*/
