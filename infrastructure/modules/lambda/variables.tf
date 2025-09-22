variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Runtime for Lambda function"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Timeout for Lambda function in seconds"
  type        = number
  default     = 30
}

variable "source_path" {
  description = "Path to Lambda function source code"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Lambda will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda function"
  type        = list(string)
}

variable "environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
}

variable "enable_msk_trigger" {
  description = "Enable MSK trigger for Lambda function"
  type        = bool
  default     = false
}

variable "msk_cluster_arn" {
  description = "ARN of the MSK cluster"
  type        = string
  default     = ""
}

variable "kafka_topics" {
  description = "Kafka topics to subscribe to"
  type        = list(string)
  default     = []
}

variable "starting_position" {
  description = "Starting position for Lambda MSK event source mapping"
  type        = string
  default     = "TRIM_HORIZON"
  validation {
    condition     = contains(["TRIM_HORIZON", "LATEST"], var.starting_position)
    error_message = "Lambda starting position must be TRIM_HORIZON or LATEST."
  }
}

variable "tags" {
  description = "Tags to apply to Lambda resources"
  type        = map(string)
  default     = {}
}