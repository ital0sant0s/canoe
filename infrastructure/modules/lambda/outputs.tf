output "function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "security_group_id" {
  description = "Security group ID of the Lambda function"
  value       = module.lambda_sg.security_group_id
}