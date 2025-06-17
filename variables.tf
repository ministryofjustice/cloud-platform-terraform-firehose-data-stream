#################
# Configuration #
#################

variable "cloudwatch_filter_pattern" {
  type        = string
  description = "A valid CloudWatch Logs filter pattern for subscribing to a filtered stream of log events."
  default     = ""
}

variable "cloudwatch_log_group_names" {
  type        = list(string)
  description = "List of CloudWatch Log Group names to stream logs from."
  default     = []
}

variable "destination_bucket_arn" {
  type        = string
  description = "ARN of the bucket for CloudWatch filters."
  default     = ""
}

variable "destination_http_endpoint" {
  type        = string
  description = "HTTP endpoint for CloudWatch filters."
  default     = ""
}

variable "s3_compression_format" {
  type        = string
  description = "Allow optional configuration of AWS Data Stream compression. Log Group subscription filters compress logs by default."
  default     = "UNCOMPRESSED"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to be applied to resources."
  default     = {}
}

variable "eks_cluster_name" {
  description = "The name of the eks cluster to retrieve the OIDC information"
  type        = string
}