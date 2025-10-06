variable "log_bucket_name" {
  description = "S3 bucket name for logs"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
}

variable "enable_log_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
}
