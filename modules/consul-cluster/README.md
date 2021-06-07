# My HashiCorp Google Cloud Sandbox

This repository contains a series of Terraform configurations that can be used
to build a "HashiStack" in a single or multiple regions

## Auto Gen

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.15.0 |
| google | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| google | 3.70.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allow_consul_health_checks](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_inbound_dns](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_inbound_http_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.allow_intracluster_consul](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_health_check.consul_hc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance_template.consul_server_private](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template) | resource |
| [google_compute_region_instance_group_manager.consul_server](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | The name of the Consul cluster (e.g. consul-stage). This variable is used to namespace all resources created by this module. | `string` | n/a | yes |
| cluster\_size | The number of nodes to have in the Consul cluster. We strongly recommended that you use either 3 or 5. | `number` | n/a | yes |
| cluster\_tag\_name | The tag name the Compute Instances will look for to automatically discover each other and form a cluster. TIP: If running more than one Consul Server cluster, each cluster should have its own unique tag name. | `string` | n/a | yes |
| gcp\_project\_id | The project to deploy the cluster in | `string` | n/a | yes |
| gcp\_region | All GCP resources will be launched in this Region. | `string` | n/a | yes |
| machine\_type | The machine type of the Compute Instance to run for each node in the cluster (e.g. n1-standard-1). | `string` | n/a | yes |
| source\_image | The source image used to create the boot disk for a Consul Server node. Only images based on Ubuntu 16.04 or 18.04 LTS are supported at this time. | `string` | n/a | yes |
| startup\_script | A Startup Script to execute when the server first boots. We remmend passing in a bash script that executes the run-consul script, which should have been installed in the Consul Google Image by the install-consul module. | `string` | n/a | yes |
| allowed\_inbound\_cidr\_blocks\_dns | A list of CIDR-formatted IP address ranges from which the Compute Instances will allow TCP DNS and UDP DNS connections to Consul. | `list(string)` | `[]` | no |
| allowed\_inbound\_cidr\_blocks\_http\_api | A list of CIDR-formatted IP address ranges from which the Compute Instances will allow API connections to Consul. | `list(string)` | `[]` | no |
| allowed\_inbound\_tags\_dns | A list of tags from which the Compute Instances will allow TCP DNS and UDP DNS connections to Consul. | `list(string)` | `[]` | no |
| allowed\_inbound\_tags\_http\_api | A list of tags from which the Compute Instances will allow API connections to Consul. | `list(string)` | `[]` | no |
| cli\_rpc\_port | The port used by all agents to handle RPC from the CLI. | `number` | `8400` | no |
| cluster\_description | A description of the Consul cluster; it will be added to the Compute Instance Template. | `string` | `null` | no |
| consul\_cluster\_version | Custom Version Tag for Upgrade Migrations | `string` | `"0-0-1"` | no |
| consul\_health\_check\_path | Consul Health Check | `string` | `"/v1/operator/autopilot/health"` | no |
| cooldown\_period | Node Cooldown time | `string` | `"480"` | no |
| custom\_metadata | A map of metadata key value pairs to assign to the Compute Instance metadata. | `map(string)` | `{}` | no |
| custom\_tags | A list of tags that will be added to the Compute Instance Template in addition to the tags automatically added by this module. | `list(string)` | `[]` | no |
| dns\_port | The port used to resolve DNS queries. | `number` | `8600` | no |
| enable\_non\_voting | Enable Non-voting servers in cluster | `bool` | `false` | no |
| gcp\_health\_check\_cidr | Google Healthcheck IP Ranges | `list(string)` | <pre>[<br>  "35.191.0.0/16",<br>  "130.211.0.0/22",<br>  "209.85.152.0/22",<br>  "209.85.204.0/22"<br>]</pre> | no |
| health\_check\_delay | Health check delay | `string` | `"150"` | no |
| http\_api\_port | The port used by clients to talk to the HTTP API | `number` | `8500` | no |
| image\_project\_id | The name of the GCP Project where the image is located. Useful when using a separate project for custom images. If empty, var.gcp\_project\_id will be used. | `string` | `null` | no |
| instance\_group\_target\_pools | To use a Load Balancer with the Consul cluster, you must populate this value. Specifically, this is the list of Target Pool URLs to which new Compute Instances in the Instance Group created by this module will be added. Note that updating the Target Pools attribute does not affect existing Compute Instances. Note also that use of a Load Balancer with Consul is generally discouraged; client should instead prefer to talk directly to the server where possible. | `list(string)` | `[]` | no |
| instance\_group\_update\_strategy | The update strategy to be used by the Instance Group. IMPORTANT! When you update almost any cluster setting, under the hood, this module creates a new Instance Group Template. Once that Instance Group Template is created, the value of this variable determines how the new Template will be rolled out across the Instance Group. Unfortunately, as of August 2017, Google only supports the options 'RESTART' (instantly restart all Compute Instances and launch new ones from the new Template) or 'NONE' (do nothing; updates should be handled manually). Google does offer a rolling updates feature that perfectly meets our needs, but this is in Alpha (https://goo.gl/MC3mfc). Therefore, until this module supports a built-in rolling update strategy, we recommend using `NONE` and using the alpha rolling updates strategy to roll out new Consul versions. As an alpha feature, be sure you are comfortable with the level of risk you are taking on. For additional detail, see https://goo.gl/hGH6dd. | `string` | `"NONE"` | no |
| metadata\_key\_name\_for\_cluster\_size | The key name to be used for the custom metadata attribute that represents the size of the Consul cluster. | `string` | `"cluster-size"` | no |
| network\_name | The name of the VPC Network where all resources should be created. | `string` | `"default"` | no |
| network\_project\_id | The name of the GCP Project where the network is located. Useful when using networks shared between projects. If empty, var.gcp\_project\_id will be used. | `string` | `null` | no |
| root\_volume\_disk\_size\_gb | The size, in GB, of the root disk volume on each Consul node. | `number` | `30` | no |
| root\_volume\_disk\_type | The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard | `string` | `"pd-standard"` | no |
| serf\_lan\_port | The port used to handle gossip in the LAN. Required by all agents. | `number` | `8301` | no |
| serf\_wan\_port | The port used by servers to gossip over the WAN to other servers. | `number` | `8302` | no |
| server\_rpc\_port | The port used by servers to handle incoming requests from other agents. | `number` | `8300` | no |
| service\_account\_email | The email of the service account for the instance template. If none is provided the google cloud provider project service account is used. | `string` | `null` | no |
| service\_account\_scopes | A list of service account scopes that will be added to the Compute Instance Template in addition to the scopes automatically added by this module. | `list(string)` | `[]` | no |
| storage\_access\_scope | Used to set the access permissions for Google Cloud Storage. As of September 2018, this must be one of ['', 'storage-ro', 'storage-rw', 'storage-full'] | `string` | `"storage-ro"` | no |
| subnetwork\_name | The name of the VPC Subnetwork where all resources should be created. Defaults to the default subnetwork for the network and region. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_health\_check | n/a |
| cluster\_name | n/a |
| cluster\_tag\_name | n/a |
| firewall\_rule\_inbound\_dns\_name | n/a |
| firewall\_rule\_inbound\_dns\_url | n/a |
| firewall\_rule\_inbound\_http\_name | n/a |
| firewall\_rule\_inbound\_http\_url | n/a |
| firewall\_rule\_intracluster\_name | n/a |
| firewall\_rule\_intracluster\_url | n/a |
| gcp\_region | n/a |
| instance\_group\_full\_url | n/a |
| instance\_group\_instance\_group | n/a |
| instance\_group\_name | n/a |
| instance\_group\_url | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
