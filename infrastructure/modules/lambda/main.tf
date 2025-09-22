module "lambda_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.function_name}-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  egress_rules = ["all-all"]

  tags = var.tags
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = var.function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout

  source_path = var.source_path

  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = [module.lambda_sg.security_group_id]

  environment_variables = var.environment_variables

  cloudwatch_logs_retention_in_days = var.log_retention_days

  allowed_triggers = var.enable_msk_trigger ? {
    msk = {
      service    = "kafka"
      source_arn = var.msk_cluster_arn
    }
  } : {}

  event_source_mapping = var.enable_msk_trigger ? {
    msk = {
      event_source_arn  = var.msk_cluster_arn
      topics            = var.kafka_topics
      starting_position = var.starting_position
    }
  } : {}

  tags = var.tags
}