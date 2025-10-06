output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.networking.security_group_id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.compute.instance_id
}

output "public_ip" {
  description = "Public IP address"
  value       = module.compute.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = module.compute.private_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = module.compute.ssh_command
}

output "s3_bucket_name" {
  description = "S3 bucket name for logs"
  value       = var.enable_logging ? module.logging[0].s3_bucket_name : "Logging disabled"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group"
  value       = var.enable_logging ? module.logging[0].cloudwatch_log_group : "Logging disabled"
}
