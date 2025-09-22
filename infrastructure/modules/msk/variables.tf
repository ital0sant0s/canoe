variable "cluster_name" {
  description = "Name of the MSK cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where MSK will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for MSK cluster"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of the ECS service"
  type        = string
}

variable "lambda_security_group_id" {
  description = "Security group ID of the Lambda function"
  type        = string
}

variable "kafka_version" {
  description = "Kafka version for MSK cluster"
  type        = string
  default     = "3.4.0"
}

variable "instance_type" {
  description = "Instance type for MSK brokers"
  type        = string
  default     = "kafka.t3.small"
}

variable "ebs_volume_size" {
  description = "EBS volume size for MSK brokers in GB"
  type        = number
  default     = 20
}

variable "encryption_in_transit" {
  description = "Encryption in transit setting for MSK"
  type        = string
  default     = "TLS_PLAINTEXT"
  validation {
    condition     = contains(["TLS", "TLS_PLAINTEXT", "PLAINTEXT"], var.encryption_in_transit)
    error_message = "MSK encryption in transit must be TLS, TLS_PLAINTEXT, or PLAINTEXT."
  }
}

variable "encryption_in_cluster" {
  description = "Enable encryption within MSK cluster"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_enabled" {
  description = "Enable CloudWatch logs for MSK cluster"
  type        = bool
  default     = true
}

variable "server_properties" {
  description = "Server properties for MSK configuration"
  type        = string
  default     = <<PROPERTIES
auto.create.topics.enable=true
default.replication.factor=2
min.insync.replicas=1
num.partitions=3
log.retention.hours=24
log.retention.bytes=1073741824
log.segment.bytes=104857600
PROPERTIES
}

variable "encryption_at_rest_kms_key_id" {
  description = "KMS key ID for encryption at rest (optional)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to MSK resources"
  type        = map(string)
  default     = {}
}