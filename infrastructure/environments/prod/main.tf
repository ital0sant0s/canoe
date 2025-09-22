locals {
  common_tags = {
    Project     = var.project_name
    Environment = "prod"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name             = "${var.project_name}-vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway

  tags = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name         = "${var.project_name}-api-service"
  image_retention_count   = var.ecr_image_retention_count
  untagged_retention_days = var.ecr_untagged_retention_days

  tags = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  alb_name    = "${var.project_name}-alb"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = concat([module.vpc.public_subnet_ids[0]], [module.vpc.private_subnet_ids[0]])
  target_port = var.api_service_port

  enable_ssl                = var.enable_ssl
  domain_name              = var.domain_name
  route53_zone_id          = var.route53_zone_id
  subject_alternative_names = var.subject_alternative_names
  wait_for_ssl_validation  = var.wait_for_ssl_validation

  health_check_path               = var.alb_health_check_path
  health_check_healthy_threshold  = var.alb_health_check_healthy_threshold
  health_check_unhealthy_threshold = var.alb_health_check_unhealthy_threshold
  health_check_timeout            = var.alb_health_check_timeout
  health_check_interval           = var.alb_health_check_interval

  tags = local.common_tags
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = "${var.project_name}-event-processor"
  description   = "Process events from MSK"
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  source_path   = var.lambda_source_path

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  environment_variables = merge({
    LOG_LEVEL = var.lambda_log_level
  }, var.lambda_additional_environment_variables)

  log_retention_days = var.cloudwatch_log_retention_days

  enable_msk_trigger = var.enable_msk_trigger
  msk_cluster_arn    = var.enable_msk_trigger ? module.msk.cluster_arn : ""
  kafka_topics       = var.enable_msk_trigger ? [var.kafka_topic_name] : []
  starting_position  = var.lambda_starting_position

  tags = local.common_tags
}

module "msk" {
  source = "../../modules/msk"

  cluster_name               = "${var.project_name}-msk"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  ecs_security_group_id      = module.ecs.service_security_group_id
  lambda_security_group_id   = module.lambda.security_group_id

  kafka_version           = var.msk_kafka_version
  instance_type           = var.msk_instance_type
  ebs_volume_size         = var.msk_ebs_volume_size
  encryption_in_transit   = var.msk_encryption_in_transit
  encryption_in_cluster   = var.msk_encryption_in_cluster
  cloudwatch_logs_enabled = var.msk_cloudwatch_logs_enabled
  server_properties       = var.msk_server_properties

  tags = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  cluster_name          = "${var.project_name}-cluster"
  service_name          = "${var.project_name}-api-service"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn

  ecr_repository_url = module.ecr.repository_url
  image_tag          = var.container_image_tag
  aws_region         = var.aws_region

  task_cpu           = var.ecs_task_cpu
  task_memory        = var.ecs_task_memory
  desired_count      = var.ecs_desired_count
  container_port     = var.api_service_port
  fargate_weight     = var.fargate_weight
  fargate_spot_weight = var.fargate_spot_weight

  environment_variables = concat([
    {
      name  = "KAFKA_BOOTSTRAP_SERVERS"
      value = module.msk.bootstrap_brokers
    },
    {
      name  = "KAFKA_TOPIC"
      value = var.kafka_topic_name
    },
    {
      name  = "PORT"
      value = tostring(var.api_service_port)
    }
  ], var.additional_environment_variables)

  log_retention_days = var.cloudwatch_log_retention_days

  alb_listener_dependency = module.alb.listeners

  tags = local.common_tags
}