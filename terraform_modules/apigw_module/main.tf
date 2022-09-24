

resource "aws_api_gateway_rest_api" "teamsalertapi" {
 name = "teamsalertapi-gateway"
 description = "Proxy for teamsalertapi"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = "${aws_api_gateway_rest_api.teamsalertapi.id}"
  parent_id   = "${aws_api_gateway_rest_api.teamsalertapi.root_resource_id}"
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.teamsalertapi.id}"
  resource_id   = "${aws_api_gateway_resource.resource.id}"
  http_method   = "ANY"
  authorization = "NONE"
  api_key_required = true
  request_parameters = {
    "method.request.path.proxy" = true
  }
}
resource "aws_api_gateway_integration" "integration" {
  rest_api_id = "${aws_api_gateway_rest_api.teamsalertapi.id}"
  resource_id = "${aws_api_gateway_resource.resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "<url_for_api>/{proxy}"
 
  request_parameters =  {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_api_key" "teamsapikey" {
  name = "teamsapikey"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.teamsalertapi.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.teamsalertapi.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on=[aws_api_gateway_resource.resource,aws_api_gateway_method.method,aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_stage" "development" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.teamsalertapi.id
  stage_name    = "dev"
}

resource "aws_api_gateway_usage_plan" "teamsapi_usage" {
  name         = "teams-api-usage-plan"
  

  api_stages {
    api_id = aws_api_gateway_rest_api.teamsalertapi.id
    stage  = aws_api_gateway_stage.development.stage_name
  }

  quota_settings {
    limit  = 20
    offset = 2
    period = "WEEK"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }
}

resource "aws_api_gateway_usage_plan_key" "teams_api_key" {
  key_id        = aws_api_gateway_api_key.teamsapikey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.teamsapi_usage.id
}