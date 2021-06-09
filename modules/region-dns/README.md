# Doc Stub

This repository contains

## Auto Gen

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.15.0 |
| google | >= 3.5 |

## Providers

| Name | Version |
|------|---------|
| google | >= 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_dns_record_set.region-bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.region-consul](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.region-lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.region-nomad](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.region-vault](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion-ip | IP of Bastion Host | `string` | n/a | yes |
| dnszone | DNS Zone name for LB | `string` | n/a | yes |
| glb-ip | IP of glboal LB | `string` | n/a | yes |
| lb-ip | IP of regional LB | `string` | n/a | yes |
| project | GCP Project name | `string` | n/a | yes |
| region | GCP Region for Hashistack deployment | `string` | n/a | yes |
| zone-name | GCP Zone name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| region-bastion-dns | n/a |
| region-consul-dns | n/a |
| region-lb-dns | n/a |
| region-nomad-dns | n/a |
| region-vault-dns | n/a |
<!-- END_TF_DOCS -->
