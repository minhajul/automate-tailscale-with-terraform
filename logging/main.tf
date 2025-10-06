resource "aws_s3_bucket" "tailscale_logs" {
  bucket = var.log_bucket_name

  tags = {
    Name    = "tailscale-logs"
    Purpose = "Tailscale log storage"
  }
}

resource "aws_s3_bucket_versioning" "tailscale_logs" {
  bucket = aws_s3_bucket.tailscale_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tailscale_logs" {
  count  = var.enable_log_encryption ? 1 : 0
  bucket = aws_s3_bucket.tailscale_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tailscale_logs" {
  bucket = aws_s3_bucket.tailscale_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tailscale_logs" {
  bucket = aws_s3_bucket.tailscale_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "tailscale_logging_role" {
  name = "tailscale-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "tailscale-logging-role"
  }
}

resource "aws_iam_policy" "tailscale_s3_logging_policy" {
  name        = "tailscale-s3-logging-policy"
  description = "Policy for Tailscale S3 logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.tailscale_logs.arn}",
          "${aws_s3_bucket.tailscale_logs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tailscale_logging_attach" {
  role       = aws_iam_role.tailscale_logging_role.name
  policy_arn = aws_iam_policy.tailscale_s3_logging_policy.arn
}

resource "aws_cloudwatch_log_group" "tailscale_logs" {
  name              = "/aws/ec2/tailscale"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "tailscale-logs"
  }
}

resource "aws_iam_policy" "tailscale_cloudwatch_policy" {
  name        = "tailscale-cloudwatch-policy"
  description = "Policy for Tailscale CloudWatch logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.tailscale_logs.arn}",
          "${aws_cloudwatch_log_group.tailscale_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tailscale_cloudwatch_attach" {
  role       = aws_iam_role.tailscale_logging_role.name
  policy_arn = aws_iam_policy.tailscale_cloudwatch_policy.arn
}

resource "aws_iam_instance_profile" "tailscale_logging_profile" {
  name = "tailscale-logging-profile"
  role = aws_iam_role.tailscale_logging_role.name
}