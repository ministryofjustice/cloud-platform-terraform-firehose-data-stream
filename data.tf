data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "cloudwatch-logs-trust-policy" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["logs.eu-west-2.amazonaws.com", ]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch-logs-role-policy" {
  version = "2012-10-17"

  statement {
    sid    = "FirehoseToDeliveryStream"
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.firehose.arn
    ]
  }
}

data "aws_iam_policy_document" "irsa-role-policy" {
  version = "2012-10-17"

  statement {
    sid    = "FirehoseToDeliveryStream"
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.firehose.arn
    ]
  }
}

data "aws_iam_policy_document" "firehose-trust-policy" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com", ]
    }
  }
}

data "aws_iam_policy_document" "firehose-role-policy" {
  version = "2012-10-17"

  statement {
    sid    = "FirehoseToS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = concat(
      [for arn in [var.destination_bucket_arn] : arn if arn != ""],
      [for arn in [var.destination_bucket_arn] : "${arn}/*" if arn != ""],
      [aws_s3_bucket.firehose-errors.arn,
      "${aws_s3_bucket.firehose-errors.arn}/*"]
    )
  }
  statement {
    sid    = "FirehoseUseKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.firehose.arn
    ]
  }
  statement {
    sid    = "FirehosePutLogs"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.firehose.arn}:log-stream:DestinationDelivery"
    ]
  }
  statement {
    sid    = "FirehoseReadSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.firehose.arn
    ]
  }
}

data "aws_iam_policy_document" "firehose-key-policy" {
  statement {
    sid    = "KeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowFirehoseRole"
    effect = "Allow"

    principals {
      identifiers = [
        aws_iam_role.cloudwatch-to-firehose.arn,
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
      type = "AWS"
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}
