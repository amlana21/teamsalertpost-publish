resource "aws_sns_topic" "teamsnotiftopic" {
  name = "teams-notification"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.teamsnotiftopic.arn
  protocol  = "lambda"
  endpoint  = var.sns_lambda
}