# Doc Stub

This repository contains

## Auto Gen

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.15.0 |
| google | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| google | 3.71.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_backend_service.consul_be](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_backend_service.nomad_be](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_backend_service.vault_be](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_global_address.region-global-pub-ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.https-app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_security_policy.security-policy-1](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_security_policy) | resource |
| [google_compute_ssl_certificate.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_certificate) | resource |
| [google_compute_ssl_policy.ssl](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_policy) | resource |
| [google_compute_target_https_proxy.region_proxy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.region-url-map](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_email | Email address for admin of domain name | `string` | n/a | yes |
| consul\_hc | Consul Health Check Self Link | `string` | n/a | yes |
| consul\_ig | Consul instance group | `string` | n/a | yes |
| dnszone | DNS Zone Name for Vault certs | `string` | n/a | yes |
| nomad\_hc | Nomad Health Check Self Link | `string` | n/a | yes |
| nomad\_ig | Nomad instance group | `string` | n/a | yes |
| project | GCP Project name | `string` | n/a | yes |
| region | GCP Region for Hashistack deployment | `string` | n/a | yes |
| region\_tls\_cert\_chain | TLS Public Cert Chain | `string` | n/a | yes |
| region\_tls\_priv\_key | TLS Private Key | `string` | n/a | yes |
| vault\_hc | Vault Health Check Self Link | `string` | n/a | yes |
| vault\_ig | Vault instance group | `string` | n/a | yes |
| ip\_allow\_list | IP CIDRs to alow. Defaults to the entire world. | `list(any)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| region-lb-global-ip | n/a |
<!-- END_TF_DOCS -->
