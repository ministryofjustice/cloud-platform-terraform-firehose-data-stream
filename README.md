# cloud-platform-terraform-firehose-data-stream

[![Releases](https://img.shields.io/github/v/release/ministryofjustice/cloud-platform-terraform-template.svg)](https://github.com/ministryofjustice/cloud-platform-terraform-template/releases)

This module creates an [Amazon Data Firehose](https://aws.amazon.com/firehose/) to be used by a set of AWS CloudWatch Log Groups.
Data is streamed from the Log Groups to either a target S3 bucket or HTTP endpoint using a Cloudwatch Log Subscription Filter.

When a HTTP endpoint is specified, an `aws_secretsmanager_secret` resource is created that is polled at 10 minute intervals for credentials.

The `aws_secretsmanager_secret` **value** must be populated independently of this module.

Included in this module are the necessary IAM policy documents and roles for these actions, as well as a KMS key to encrypt the Data Stream.

This terraform module was inspired by [modernisation-platform-terraform-aws-data-firehose](https://github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose) module.

## Usage

```hcl

module "example-s3" {
  source                     = "github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose"
  cloudwatch_log_group_names = ["example-1", "example-2", "example-3"]
  destination_bucket_arn     = aws_s3_bucket.example.arn
  tags                       = local.tags
}

module "example-http" {
  source                     = "github.com/ministryofjustice/modernisation-platform-terraform-aws-data-firehose"
  cloudwatch_log_group_names = ["example-1", "example-2", "example-3"]
  destination_http_endpoint  = "https://example-url.com/endpoint"
  tags                       = local.tags
}

```

See the [examples/](examples/) folder for more information.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application name | `string` | n/a | yes |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Area of the MOJ responsible for the service | `string` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name | `string` | n/a | yes |
| <a name="input_infrastructure_support"></a> [infrastructure\_support](#input\_infrastructure\_support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Whether this is used for production or not | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace name | `string` | n/a | yes |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | Team name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Tags

Some of the inputs for this module are tags. All infrastructure resources must be tagged to meet the MOJ Technical Guidance on [Documenting owners of infrastructure](https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html).

You should use your namespace variables to populate these. See the [Usage](#usage) section for more information.

## Reading Material

<!-- Add links to useful documentation -->

- [Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide)
