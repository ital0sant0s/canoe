# Core Configuration
project_name = "event-processing-service"
aws_region   = "us-east-1"

# SSL/TLS Configuration
enable_ssl      = true
domain_name     = "api.canoeintelligence.com"
route53_zone_id = "Z1234567890ABC"

subject_alternative_names = [
  "*.canoeintelligence.com"
]

# VPC Configuration
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidr   = "10.1.1.0/24"
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
single_nat_gateway   = false

# ECS Configuration
ecs_task_cpu      = 512
ecs_task_memory   = 512
ecs_desired_count = 2

fargate_weight      = 100
fargate_spot_weight = 0

# Container Configuration
container_image_tag = "v1.0.0"

additional_environment_variables = [
  {
    name  = "ENVIRONMENT"
    value = "production"
  },
  {
    name  = "LOG_LEVEL"
    value = "INFO"
  },
  {
    name  = "DEBUG"
    value = "false"
  }
]

# MSK Configuration
msk_instance_type         = "kafka.m5.xlarge"
msk_ebs_volume_size       = 50
msk_encryption_in_transit = "TLS"

# Lambda Configuration
lambda_timeout           = 120
lambda_log_level         = "INFO"
lambda_starting_position = "LATEST"

lambda_additional_environment_variables = {
  ENVIRONMENT = "production"
  DEBUG       = "false"
}

# CloudWatch Configuration
cloudwatch_log_retention_days = 7

# ECR Configuration
ecr_image_retention_count   = 7
ecr_untagged_retention_days = 2