output "cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = module.msk.arn
}

output "bootstrap_brokers" {
  description = "Bootstrap brokers for the MSK cluster"
  value       = module.msk.bootstrap_brokers_plaintext
}

output "bootstrap_brokers_tls" {
  description = "TLS bootstrap brokers for the MSK cluster"
  value       = module.msk.bootstrap_brokers_tls
}

output "security_group_id" {
  description = "Security group ID for MSK cluster"
  value       = module.msk_sg.security_group_id
}