output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.tailscale_logs.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.tailscale_logs.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.tailscale_logs.name
}

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.tailscale_logging_role.arn
}

output "instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.tailscale_logging_profile.name
}