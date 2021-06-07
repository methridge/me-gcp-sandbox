# My HashiCorp Google Cloud Sandbox

This repository contains a series of Terraform configurations that can be used
to build a "HashiStack" in a single or multiple regions

## Auto Gen

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.15.0 |
| local | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| local | 2.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [local_file.consul_client_pem](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.consul_client_pem_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.consul_server_pem](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.consul_server_pem_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.consul_token](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sandbox_ca](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sandbox_ca_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.vault_server_pem](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.vault_server_pem_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| consul\_client\_pem | (optional) describe your variable | `string` | n/a | yes |
| consul\_client\_pem\_key | (optional) describe your variable | `string` | n/a | yes |
| consul\_server\_pem | (optional) describe your variable | `string` | n/a | yes |
| consul\_server\_pem\_key | (optional) describe your variable | `string` | n/a | yes |
| consul\_token | (optional) describe your variable | `string` | n/a | yes |
| region\_output | (optional) describe your variable | `string` | n/a | yes |
| sandbox\_ca | (optional) describe your variable | `string` | n/a | yes |
| sandbox\_ca\_key | (optional) describe your variable | `string` | n/a | yes |
| vault\_server\_pem | (optional) describe your variable | `string` | n/a | yes |
| vault\_server\_pem\_key | (optional) describe your variable | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
