variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID"
  type        = string
}

variable "enable_logging" {
  description = "Enable logging"
  type        = bool
}

variable "log_bucket_name" {
  description = "S3 bucket name for logs"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}