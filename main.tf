resource "random_id" "name" {
  byte_length = 8
}

# KMS key and alias for Firehose
resource "aws_kms_key" "firehose" {
  description             = "KMS key for Firehose delivery streams"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.firehose-key-policy.json
  tags                    = var.tags
}

resource "aws_kms_alias" "firehose" {
  name_prefix   = "alias/cloud-platform-firehose-log-delivery-${random_id.name.hex}"
  target_key_id = aws_kms_key.firehose.id
}

# IAM roles and policies for Firehose, KMS, S3 and CloudWatch Logs
resource "aws_iam_role" "firehose" {
  assume_role_policy = data.aws_iam_policy_document.firehose-trust-policy.json
  name_prefix        = "cloud-platform-firehose"
  tags               = var.tags
}

resource "aws_iam_policy" "firehose" {
  name_prefix = "cloud-plattform-firehose"
  policy      = data.aws_iam_policy_document.firehose-role-policy.json
  tags        = var.tags
}

resource "aws_iam_policy_attachment" "firehose" {
  name       = "${aws_iam_role.firehose.name}-policy"
  policy_arn = aws_iam_policy.firehose.arn
  roles      = [aws_iam_role.firehose.name]
}

resource "aws_iam_role" "cloudwatch-to-firehose" {
  assume_role_policy = data.aws_iam_policy_document.cloudwatch-logs-trust-policy.json
  name_prefix        = "cloud-platform-cloudwatch-to-firehose"
  tags               = var.tags
}

resource "aws_iam_policy" "cloudwatch-to-firehose" {
  name_prefix = "cloudwatch-to-firehose"
  policy      = data.aws_iam_policy_document.cloudwatch-logs-role-policy.json
  tags        = var.tags
}

resource "aws_iam_policy_attachment" "cloudwatch-to-firehose" {
  name       = "${aws_iam_role.cloudwatch-to-firehose.name}-policy"
  policy_arn = aws_iam_policy.cloudwatch-to-firehose.arn
  roles      = [aws_iam_role.cloudwatch-to-firehose.name]
}

# Firehose delivery stream configuration
resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  destination = length(var.destination_bucket_arn) > 0 ? "extended_s3" : "http_endpoint"
  name        = "cloud-platform-cloudwatch-export-${var.name_affix}-${random_id.name.hex}"

  dynamic "extended_s3_configuration" {
    for_each = var.destination_bucket_arn != "" ? [1] : []
    content {
      bucket_arn          = var.destination_bucket_arn
      buffering_size      = 64
      buffering_interval  = 60
      compression_format  = var.s3_compression_format
      role_arn            = aws_iam_role.firehose.arn
      prefix              = "logs/!{timestamp:yyyy/MM/dd}/"
      error_output_prefix = "errors/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose.name
        log_stream_name = aws_cloudwatch_log_stream.firehose.name
      }

      dynamic_partitioning_configuration {
        enabled = false
      }
    }
  }
  dynamic "http_endpoint_configuration" {
    for_each = var.destination_http_endpoint != "" ? [1] : []
    content {
      buffering_size     = 5
      buffering_interval = 60
      name               = var.destination_http_endpoint
      retry_duration     = 300
      role_arn           = aws_iam_role.firehose.arn
      s3_backup_mode     = "FailedDataOnly"
      url                = var.destination_http_endpoint

      s3_configuration {
        role_arn           = aws_iam_role.firehose.arn
        bucket_arn         = aws_s3_bucket.firehose-errors.arn
        buffering_size     = 10
        buffering_interval = 400
        compression_format = "GZIP"
      }

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose.name
        log_stream_name = aws_cloudwatch_log_stream.firehose.name
      }

      request_configuration {
        content_encoding = "GZIP"
      }

      secrets_manager_configuration {
        enabled    = true
        role_arn   = aws_iam_role.firehose.arn
        secret_arn = aws_secretsmanager_secret.firehose.arn
      }
    }
  }

  server_side_encryption {
    enabled  = true
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = aws_kms_key.firehose.arn
  }

  tags = var.tags
}

# Secrets Manager secret for authentication with HTTP endpoint
resource "aws_secretsmanager_secret" "firehose" {
  kms_key_id              = aws_kms_key.firehose.id
  name_prefix             = "cloud-platform-cloudwatch-export-${random_id.name.hex}-"
  recovery_window_in_days = 0
  tags                    = var.tags
}

# S3 bucket for Firehose failed attempts to deliver logs
# More details: https://docs.aws.amazon.com/firehose/latest/dev/retry.html
resource "aws_s3_bucket" "firehose-errors" {
  bucket_prefix = "cp-firehose-errors-${random_id.name.hex}-"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "firehose-errors" {
  bucket   = aws_s3_bucket.firehose-errors.id

  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    id = "rule-1"
    filter {}
    expiration {
      days = 14
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "firehose-errors" {
  bucket                  = aws_s3_bucket.firehose-errors.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firehose-errors" {
  bucket   = aws_s3_bucket.firehose-errors.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for Firehose delivery stream logging
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/cloudwatch-export-${random_id.name.hex}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# Cloudwatch Log Subscription Filters to stream logs from specified log groups to Firehose
resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-to-firehose" {
  count           = length(var.cloudwatch_log_group_names)
  destination_arn = aws_kinesis_firehose_delivery_stream.firehose.arn
  filter_pattern  = var.cloudwatch_filter_pattern
  log_group_name  = element(var.cloudwatch_log_group_names, count.index)
  name            = "firehose-delivery-${element(var.cloudwatch_log_group_names, count.index)}-${random_id.name.hex}"
  role_arn        = aws_iam_role.cloudwatch-to-firehose.arn
}
