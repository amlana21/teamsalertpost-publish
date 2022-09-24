module "error_lambda-s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  bucket= var.src_file_bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy = true
}

resource "aws_s3_object" "error_lambda" {
  key        = "lambda-builds/error_lambda.zip"
  bucket     = module.error_lambda-s3-bucket.s3_bucket_id
  source     = "${path.module}/error_lambda.zip"
  etag       = filemd5("${path.module}/error_lambda.zip")
}

module "lambda_function_local" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "errorlambda"
  use_existing_cloudwatch_log_group  = true
  description   = "Lambda for testing error"
  handler       = "app.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  store_on_s3 = true
  s3_bucket   = module.error_lambda-s3-bucket.s3_bucket_id

  create_package         = false
   s3_existing_package = {
     bucket = module.error_lambda-s3-bucket.s3_bucket_id
     key = "lambda-builds/error_lambda.zip"
     version_id = null
   }
  timeout = 15
  create_role = true


  depends_on = [resource.aws_s3_object.error_lambda]
}
