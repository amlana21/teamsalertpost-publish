

resource "aws_cloudwatch_log_group" "errorlambda_group" {
  name = "/aws/lambda/errorlambda"
  retention_in_days = 14

  tags = {
    Application = "errorlambda"
  }
}

resource "aws_cloudwatch_log_metric_filter" "errorlambda_metric" {
  name           = "errorlambda_metric"
  pattern        = "error"
  log_group_name = aws_cloudwatch_log_group.errorlambda_group.name

  metric_transformation {
    name      = "ErrCount"
    namespace = "LambdaCustomMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "errorlambda" {
  alarm_name                = "errorlambda"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "ErrCount"
  namespace                 = "LambdaCustomMetrics"
  period                    = "10"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "alarm for errors"
  insufficient_data_actions = []
  alarm_actions = [var.actions_arn]
}