provider "aws" {
  region = "eu-west-2"
}

module "firehose_data_stream" {
  source = "../"
  # source = "github.com/ministryofjustice/cloud-platform-terraform-firehose-data-stream?ref=version" # use the latest release

  # Configuration
  cloudwatch_log_group_names = []
  destination_http_endpoint  = ""
  destination_bucket_arn     = ""

  # Tags
  tags = {
    business_unit          = var.business_unit
    application            = var.application
    is_production          = var.is_production
    team_name              = var.team_name
    namespace              = var.namespace
    environment_name       = var.environment_name
    infrastructure_support = var.infrastructure_support
  }
}
