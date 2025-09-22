variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "target_port" {
  description = "Port for the target group"
  type        = number
  default     = 5000
}

variable "enable_ssl" {
  description = "Enable SSL/TLS certificate and HTTPS"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for ACM certificate (e.g., example.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation of ACM certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject alternative names for ACM certificate (e.g., [\"*.example.com\", \"api.example.com\"])"
  type        = list(string)
  default     = []
}

variable "wait_for_ssl_validation" {
  description = "Wait for ACM certificate validation to complete before proceeding"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health checks before marking healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health checks before marking unhealthy"
  type        = number
  default     = 3
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 10
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to ALB resources"
  type        = map(string)
  default     = {}
}