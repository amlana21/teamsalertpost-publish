module "alarm_lambda-s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  bucket= var.src_file_bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy = true
}

resource "aws_s3_object" "alarm_lambda" {
  key        = "lambda-builds/alarm_lambda.zip"
  bucket     = module.alarm_lambda-s3-bucket.s3_bucket_id
  source     = "${path.module}/alarm_lambda.zip"
  etag       = filemd5("${path.module}/alarm_lambda.zip")
}

module "lambda_function_local" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "alarm_lambda"
  description   = "Lambda for triggering alert api"
  handler       = "app.lambda_handler"
  runtime       = "python3.9"
  publish       = true
  store_on_s3 = true
  s3_bucket   = module.alarm_lambda-s3-bucket.s3_bucket_id

  create_package         = false
   s3_existing_package = {
     bucket = module.alarm_lambda-s3-bucket.s3_bucket_id
     key = "lambda-builds/alarm_lambda.zip"
     version_id = null
   }

   environment_variables = {
    API_URL      = var.api_url
    ERR_KEYWORD      = var.error_keyword
    LOG_DURATION      = var.log_duration_hrs
   }
  timeout = 15
  create_role = true

  depends_on = [resource.aws_s3_object.alarm_lambda]

   allowed_triggers = {
    snstopic = {
      principal  = "sns.amazonaws.com"
      source_arn = var.err_sns_arn
    }
  }

}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecuteFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_local.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.err_sns_arn
}


resource "aws_dynamodb_table" "errortrackingdb" {
  name           = "errordb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }


  tags = {
    Name        = "errordb"
    application = "apierroralerts"
  }
}