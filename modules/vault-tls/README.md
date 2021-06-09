# Doc Stub

This repository contains

## Auto Gen

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.15.0 |
| google | >= 3.5 |
| tls | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 3.5 |
| tls | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_storage_bucket_object.vault-ca-file](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.vault-ca-key-file](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.vault-server-file](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.vault-server-key-file](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [tls_cert_request.vault-server-csr](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.vault-server-cert](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.vault-server-key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| config\_bucket | Storage Bucket name for Config files | `string` | n/a | yes |
| dnszone | DNS Zone Name for Vault certs | `string` | n/a | yes |
| region | Vault region name | `string` | n/a | yes |
| sandbox\_ca\_key | Sandbox TLS CA Key | `string` | n/a | yes |
| sandbox\_ca\_pem | Sandbox TLS CA | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vault\_server\_key\_pem | n/a |
| vault\_server\_pem | n/a |
<!-- END_TF_DOCS -->
