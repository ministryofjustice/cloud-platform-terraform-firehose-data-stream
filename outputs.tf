output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.firehose.name
}

output "data_stream" {
  value = aws_kinesis_firehose_delivery_stream.firehose.id
}

output "firehose_server_side_encryption_key_arn" {
  value = aws_kinesis_firehose_delivery_stream.firehose.server_side_encryption[0].key_arn
}

output "iam_roles" {
  value = {
    "cloudwatch-to-firehose" = aws_iam_role.cloudwatch-to-firehose,
    "firehose-to-s3"         = aws_iam_role.firehose
  }
}

output "iam_policy_arns" {
  value = {
    "cloudwatch-to-firehose" = aws_iam_policy.cloudwatch-to-firehose.arn,
    "firehose-to-s3"         = aws_iam_policy.firehose.arn,
    "eks-to-firehose"        = aws_iam_policy.eks-to-firehose.arn
  }
}

output "kms_key_arn" {
  value = aws_kms_key.firehose.arn
}

output "log_subscriptions" {
  value = aws_cloudwatch_log_subscription_filter.cloudwatch-to-firehose
}

output "secretsmanager_secret_arn" {
  value = aws_secretsmanager_secret.firehose.arn
}