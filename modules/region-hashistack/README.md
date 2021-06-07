# Doc Stub

This repository contains

## Auto Gen

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.15.0 |
| google | ~> 3.0 |
| random | ~> 3.0 |
| tls | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| google | 3.71.0 |
| random | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| global-https-lb | ../region-glb | n/a |
| region-consul-lb | github.com/GoogleCloudPlatform/terraform-google-lb | n/a |
| region-dns | ../region-dns | n/a |
| region-nomad-lb | github.com/GoogleCloudPlatform/terraform-google-lb | n/a |
| region-vault-lb | github.com/GoogleCloudPlatform/terraform-google-lb | n/a |
| region\_consul\_cluster | ../consul-cluster | n/a |
| region\_consul\_tls | ../consul-tls | n/a |
| region\_nomad\_clients | ../nomad-cluster | n/a |
| region\_nomad\_servers | ../nomad-cluster | n/a |
| region\_vault\_cluster | ../vault-cluster | n/a |
| region\_vault\_tls | ../vault-tls | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_address.region-pub-ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_instance.region_bastion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_kms_crypto_key.region_crypto_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_binding.region_crypto_key_iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_binding) | resource |
| [google_kms_key_ring.region_vault_key_ring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_storage_bucket.config_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_object.consul-gossip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.consul-master-token](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [random_id.bucket_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.vault_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [google_compute_default_service_account.vault_test](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |
| [google_compute_zones.zones](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| consul\_gossip\_key | Consul Gossip Encryption Key | `string` | n/a | yes |
| consul\_token | Consul Master Token | `string` | n/a | yes |
| dnszone | DNS Zone name for LB | `string` | n/a | yes |
| image | Hashistack machine image name | `string` | n/a | yes |
| network | VPC Network self\_link | `string` | n/a | yes |
| project | GCP Project name | `string` | n/a | yes |
| region | GCP Region for Hashistack deployment | `string` | n/a | yes |
| region\_tls\_cert\_chain | TLS Public Cert Chain | `string` | n/a | yes |
| region\_tls\_priv\_key | TLS Private Key | `string` | n/a | yes |
| sandbox\_ca\_key | Sandbox TLS CA Key | `string` | n/a | yes |
| sandbox\_ca\_pem | Sandbox TLS CA | `string` | n/a | yes |
| subnetwork | VPC subnetwork self\_link | `string` | n/a | yes |
| zone\_link | GCP Zone Object Self-link | `string` | n/a | yes |
| allowed\_ips | The IP address ranges which can access the load balancer. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| bastion\_machine\_type | Instance machine type for the Bastion host - May be larger when running ELK and Grafana | `string` | `"n1-standard-1"` | no |
| consul\_cluster\_size | Number of nodes to deploy for the Consul cluster | `number` | `3` | no |
| consul\_enable\_non\_voting | Enable Non-voting servers in cluster | `bool` | `false` | no |
| consul\_mode | Consul mode - client/server - Defaults to client | `string` | `"client"` | no |
| consul\_primary\_dc | Primary Consul Datacenter | `string` | `""` | no |
| consul\_wan\_tag | Cluster tag to WAN join with this cluster | `string` | `""` | no |
| custom\_tags | A list of tags that will be added to the Compute Instance Template in addition to the tags automatically added by this module. | `list(string)` | `[]` | no |
| elk\_stack | Install the ELK and Grafana logging and monitoring on the Bastion | `bool` | `false` | no |
| machine\_type | Instance machine type | `string` | `"n1-standard-1"` | no |
| nomad\_acl\_enabled | Enable Nomad ACLs | `bool` | `false` | no |
| nomad\_client\_cluster\_size | Number of nodes to deploy for the Nomad client cluster | `number` | `3` | no |
| nomad\_cluster\_tag\_name | Network tag used to join Nomad regions | `string` | `""` | no |
| nomad\_mode | Nomad mode none/client/server - Default blank for none | `string` | `""` | no |
| nomad\_server\_cluster\_size | Number of nodes to deploy for the Nomad server cluster | `number` | `3` | no |
| nomad\_server\_join\_tag | Cluster tag to WAN join Nomad servers | `string` | `""` | no |
| vault\_cluster\_size | Number of nodes to deploy for the Vault cluster | `number` | `3` | no |
| vault\_storage | Vault storage to use - raft/consul - Defaults to blank for raft | `string` | `""` | no |
| worker\_machine\_type | Instance machine type for the Bastion host - May be larger when running ELK and Grafana | `string` | `"n1-standard-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| consul\_client\_key\_pem | n/a |
| consul\_client\_pem | n/a |
| consul\_server\_key\_pem | n/a |
| consul\_server\_pem | n/a |
| region-bastion-dns | n/a |
| region-bastion-ip | n/a |
| region-consul-dns | n/a |
| region-lb-dns | n/a |
| region-lb-global-ip | n/a |
| region-lb-ip | n/a |
| region-nomad-dns | n/a |
| region-vault-dns | n/a |
| vault\_server\_key\_pem | n/a |
| vault\_server\_pem | n/a |
<!-- END_TF_DOCS -->
