# My HashiCorp Google Cloud Sandbox

This repository contains a series of Terraform configurations that can be used
to build a "HashiStack" in a single or multiple regions

## Auto Gen

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.15.0 |
| tls | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| tls | 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [tls_private_key.sandbox-ca-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.sandbox-ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| sandbox\_ca\_key\_pem | n/a |
| sandbox\_ca\_pem | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
