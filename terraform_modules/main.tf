terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.9.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "3.4.0"
    }
  }

  

  backend "s3" {
    bucket = "bucket_name"
    key    = "lambdastate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "security_module" {
    source = "./security_module"
}


module "alarm_lambda" {
    source = "./alarmlambda"
    err_sns_arn= module.sns_module.teams_sns_topic
    api_url=module.apigw_module.apigw_id
}

module "cloudwatch_components" {
    source = "./cloudwatch_components"
    actions_arn=module.sns_module.teams_sns_topic
}

module "error_lambda" {
    source = "./errorlambda"
}

module "sns_module" {
    source = "./sns_module"
    sns_lambda = module.alarm_lambda.lamba_arn
}

module "networking_module" {
    source = "./networking_module"
}

module "eks_module" {
    source = "./eks_module"
    vpc_id = module.networking_module.cluster_vpc_id
    subnet_ids = module.networking_module.cluster_private_subnets
    depends_on=[module.networking_module,module.security_module]
    ec2noderole=module.security_module.ec2node_role
    eksrole=module.security_module.eks_role
    fargatenoderole=module.security_module.fargatenode_role
}

module "apigw_module" {
    source = "./apigw_module"
}
