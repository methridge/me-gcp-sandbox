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
| [google_compute_firewall.allow_inbound_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_intracluster_vault](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_vault_health_checks](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_health_check.vault_hc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance_template.vault_private](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [google_compute_region_instance_group_manager.vault](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager) | resource |
| [google_project_iam_member.other_sa_view_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.vault_cluster_admin_sa_view_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.vault_cluster_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_key.vault](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | The name of the Vault cluster (e.g. vault-stage). This variable is used to namespace all resources created by this module. | `string` | n/a | yes |
| cluster\_size | The number of nodes to have in the Vault cluster. We strongly recommended that you use either 3 or 5. | `number` | n/a | yes |
| cluster\_tag\_name | The tag name the Compute Instances will look for to automatically discover each other and form a cluster. TIP: If running more than one Vault cluster, each cluster should have its own unique tag name. | `string` | n/a | yes |
| gcp\_project\_id | The ID of the GCP project to deploy the vault cluster to. | `string` | n/a | yes |
| gcp\_region | All GCP resources will be launched in this Region. | `string` | n/a | yes |
| machine\_type | The machine type of the Compute Instance to run for each node in the cluster (e.g. n1-standard-1). | `string` | n/a | yes |
| source\_image | The source image used to create the boot disk for a Vault node. Only images based on Ubuntu 16.04 LTS are supported at this time. | `string` | n/a | yes |
| startup\_script | A Startup Script to execute when the server first boots. We recommend passing in a bash script that executes the run-vault script, which should have been installed in the Vault Google Image by the install-vault module. | `string` | n/a | yes |
| allowed\_inbound\_cidr\_blocks\_api | A list of CIDR-formatted IP address ranges from which the Compute Instances will allow connections to Vault on the configured TCP Listener (see https://goo.gl/Equ4xP) | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| allowed\_inbound\_tags\_api | A list of tags from which the Compute Instances will allow connections to Vault on the configured TCP Listener (see https://goo.gl/Equ4xP) | `list(string)` | `[]` | no |
| api\_port | The port used by Vault to handle incoming API requests. | `number` | `8200` | no |
| cluster\_description | A description of the Vault cluster; it will be added to the Compute Instance Template. | `string` | `null` | no |
| cluster\_port | The port used by Vault for server-to-server communication. | `number` | `8201` | no |
| cooldown\_period | n/a | `string` | `"480"` | no |
| create\_service\_account | Creates a service account to operate Vault. If set to false and service\_account\_email is not provided, the default google cloud provider project service account is used | `bool` | `false` | no |
| custom\_metadata | A map of metadata key value pairs to assign to the Compute Instance metadata. | `map(string)` | `{}` | no |
| custom\_tags | A list of tags that will be added to the Compute Instance Template in addition to the tags automatically added by this module. | `list(string)` | `[]` | no |
| enable\_web\_proxy | If true, a Firewall Rule will be created that allows inbound Health Check traffic on var.web\_proxy\_port. | `bool` | `false` | no |
| gcp\_health\_check\_cidr | n/a | `list(string)` | <pre>[<br>  "35.191.0.0/16",<br>  "130.211.0.0/22",<br>  "209.85.152.0/22",<br>  "209.85.204.0/22"<br>]</pre> | no |
| health\_check\_delay | n/a | `string` | `"150"` | no |
| image\_project\_id | The name of the GCP Project where the image is located. Useful when using a separate project for custom images. If null, var.gcp\_project\_id will be used. | `string` | `null` | no |
| instance\_group\_target\_pools | To use a Load Balancer with the Consul cluster, you must populate this value. Specifically, this is the list of Target Pool URLs to which new Compute Instances in the Instance Group created by this module will be added. Note that updating the Target Pools attribute does not affect existing Compute Instances. | `list(string)` | `[]` | no |
| instance\_group\_update\_strategy | The update strategy to be used by the Instance Group. IMPORTANT! When you update almost any cluster setting, under the hood, this module creates a new Instance Group Template. Once that Instance Group Template is created, the value of this variable determines how the new Template will be rolled out across the Instance Group. Unfortunately, as of August 2017, Google only supports the options 'RESTART' (instantly restart all Compute Instances and launch new ones from the new Template) or 'NONE' (do nothing; updates should be handled manually). Google does offer a rolling updates feature that perfectly meets our needs, but this is in Alpha (https://goo.gl/MC3mfc). Therefore, until this module supports a built-in rolling update strategy, we recommend using `NONE` and either using the alpha rolling updates strategy to roll out new Vault versions, or to script this using GCE API calls. If using the alpha feature, be sure you are comfortable with the level of risk you are taking on. For additional detail, see https://goo.gl/hGH6dd. | `string` | `"NONE"` | no |
| metadata\_key\_name\_for\_cluster\_size | The key name to be used for the custom metadata attribute that represents the size of the Vault cluster. | `string` | `"cluster-size"` | no |
| network\_name | The name of the VPC Network where all resources should be created. | `string` | `"default"` | no |
| network\_project\_id | The name of the GCP Project where the network is located. Useful when using networks shared between projects. If null, var.gcp\_project\_id will be used. | `string` | `null` | no |
| root\_volume\_disk\_size\_gb | The size, in GB, of the root disk volume on each Consul node. | `number` | `30` | no |
| root\_volume\_disk\_type | The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard | `string` | `"pd-standard"` | no |
| service\_account\_email | The email of a service account for the instance template. use\_external\_service\_account must be set to true. If none is provided and create\_service\_account is set to false, the default google cloud provider project service account is used. | `string` | `null` | no |
| service\_account\_scopes | A list of service account scopes that will be added to the Compute Instance Template in addition to the scopes automatically added by this module. | `list(string)` | `[]` | no |
| storage\_access\_scope | Used to set the access permissions for Google Cloud Storage. As of September 2018, this must be one of ['', 'storage-ro', 'storage-rw', 'storage-full'] | `string` | `"storage-ro"` | no |
| subnetwork\_name | The name of the VPC Subnetwork where all resources should be created. Defaults to the default subnetwork for the network and region. | `string` | `null` | no |
| use\_external\_service\_account | Allows using a pre-defined service account for the instance template. | `bool` | `false` | no |
| vault\_cluster\_version | Custom Version Tag for Upgrade Migrations | `string` | `"0-0-1"` | no |
| vault\_health\_check\_path | Health check for Vault servers | `string` | `"/v1/sys/health?perfstandbyok=true&sealedcode=200&uninitcode=200&drsecondarycode=200"` | no |
| web\_proxy\_port | The port at which the HTTP proxy server will listen for incoming HTTP requests that will be forwarded to the Vault Health Check URL. We must have an HTTP proxy server to work around the limitation that GCP only permits Health Checks via HTTP, not HTTPS. This value is originally set in the Startup Script that runs Nginx and passes the port value there. | `number` | `8000` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_health\_check | n/a |
| cluster\_service\_account | n/a |
| cluster\_tag\_name | n/a |
| firewall\_rule\_allow\_inbound\_api\_id | n/a |
| firewall\_rule\_allow\_inbound\_api\_url | n/a |
| firewall\_rule\_allow\_intracluster\_vault\_id | n/a |
| firewall\_rule\_allow\_intracluster\_vault\_url | n/a |
| instance\_group\_id | n/a |
| instance\_group\_instance\_group | n/a |
| instance\_group\_name | n/a |
| instance\_group\_url | n/a |
<!-- END_TF_DOCS -->
