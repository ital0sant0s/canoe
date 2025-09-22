variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "event-processing-service"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for cost optimization"
  type        = bool
  default     = false
}

variable "enable_ssl" {
  description = "Enable SSL/TLS certificate and HTTPS"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for domain validation"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Subject alternative names for SSL certificate"
  type        = list(string)
  default     = []
}

variable "wait_for_ssl_validation" {
  description = "Wait for SSL certificate validation"
  type        = bool
  default     = true
}

variable "ecr_image_retention_count" {
  description = "Number of tagged images to retain in ECR"
  type        = number
  default     = 20
}

variable "ecr_untagged_retention_days" {
  description = "Days to retain untagged images in ECR"
  type        = number
  default     = 3
}

variable "alb_health_check_path" {
  description = "Health check path for ALB target group"
  type        = string
  default     = "/health"
}

variable "alb_health_check_healthy_threshold" {
  description = "Number of consecutive health checks before marking healthy"
  type        = number
  default     = 3
}

variable "alb_health_check_unhealthy_threshold" {
  description = "Number of consecutive health checks before marking unhealthy"
  type        = number
  default     = 5
}

variable "alb_health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 10
}

variable "alb_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 2048
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 4
}

variable "fargate_weight" {
  description = "Weight for FARGATE capacity provider"
  type        = number
  default     = 100
}

variable "fargate_spot_weight" {
  description = "Weight for FARGATE_SPOT capacity provider"
  type        = number
  default     = 0
}

variable "api_service_port" {
  description = "Port for API service container"
  type        = number
  default     = 5000
}

variable "container_image_tag" {
  description = "Docker image tag for API service"
  type        = string
  default     = "latest"
}

variable "additional_environment_variables" {
  description = "Additional environment variables for API service"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "ENVIRONMENT"
      value = "production"
    },
    {
      name  = "LOG_LEVEL"
      value = "INFO"
    }
  ]
}

variable "msk_kafka_version" {
  description = "Kafka version for MSK cluster"
  type        = string
  default     = "3.4.0"
}

variable "msk_instance_type" {
  description = "Instance type for MSK brokers"
  type        = string
  default     = "kafka.m5.large"
}

variable "msk_ebs_volume_size" {
  description = "EBS volume size for MSK brokers in GB"
  type        = number
  default     = 100
}

variable "msk_encryption_in_transit" {
  description = "Encryption in transit setting for MSK"
  type        = string
  default     = "TLS"
}

variable "msk_encryption_in_cluster" {
  description = "Enable encryption within MSK cluster"
  type        = bool
  default     = true
}

variable "msk_cloudwatch_logs_enabled" {
  description = "Enable CloudWatch logs for MSK cluster"
  type        = bool
  default     = true
}

variable "msk_server_properties" {
  description = "Server properties for MSK configuration"
  type        = string
  default     = <<PROPERTIES
auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
num.partitions=6
log.retention.hours=168
log.retention.bytes=10737418240
log.segment.bytes=1073741824
log.cleanup.policy=delete
compression.type=snappy
PROPERTIES
}

variable "kafka_topic_name" {
  description = "Name of the Kafka topic for events"
  type        = string
  default     = "events"
}

variable "lambda_runtime" {
  description = "Runtime for Lambda function"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 60
}

variable "lambda_source_path" {
  description = "Path to Lambda function source code"
  type        = string
  default     = "../../../src/event-processor"
}

variable "lambda_log_level" {
  description = "Log level for Lambda function"
  type        = string
  default     = "INFO"
}

variable "lambda_starting_position" {
  description = "Starting position for Lambda MSK event source mapping"
  type        = string
  default     = "LATEST"
}

variable "enable_msk_trigger" {
  description = "Enable MSK trigger for Lambda function"
  type        = bool
  default     = true
}

variable "lambda_additional_environment_variables" {
  description = "Additional environment variables for Lambda function"
  type        = map(string)
  default = {
    ENVIRONMENT = "production"
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
}