output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_groups["ex-instance"].arn
}

output "security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.alb_sg.security_group_id
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.acm.acm_certificate_arn
}

output "certificate_domain_validation_options" {
  description = "Domain validation options for the ACM certificate"
  value       = module.acm.acm_certificate_domain_validation_options
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = module.acm.acm_certificate_status
}

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = module.alb.listeners
}