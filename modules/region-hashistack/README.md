# GCP Regional Hashistack Module

## Variables

### Required

| name         | type   | description                          |
| ------------ | ------ | ------------------------------------ |
| project      | string | GCP Project name                     |
| region       | string | GCP Region for Hashistack deployment |
| image        | string | Hashistack machine image name        |
| machine_type | string | Instance machine type                |
| network      | string | VPC Network self_link                |
| subnetwork   | string | VPC subnetwork self_link             |
| dnszone      | string | DNS Zone name for LB                 |

### Optional

| name                      | type         | description                                                                      | default       |
| ------------------------- | ------------ | -------------------------------------------------------------------------------- | ------------- |
| allowed_ips               | list(string) | The IP address ranges which can access the load balancer.                        | ["0.0.0.0/0"] |
| consul_cluster_size       | number       | Number of nodes to deploy for the Consul cluster                                 | 3             |
| consul_ent                | bool         | Install Consul Enterprise binary - true/false - Defaults to false                | false         |
| consul_mode               | string       | Consul mode - client/server - Defaults to client                                 | "client"      |
| consul_prem               | bool         | Install Consul Premium binary - true/false - Defaults to false                   | false         |
| consul_template_ver       | string       | Consul Template version to install - Default to latest                           | ""            |
| consul_version            | string       | Consul Version - Default to latest                                               | ""            |
| consul_wan_tag            | string       | Cluster tag to WAN join with this cluster                                        | ""            |
| custom_tags               | list(string) | A list of additional tags that will be applied to the Compute Instance Template. | []            |
| envconsul_ver             | string       | EnvConsul version to install - Default to latest                                 | ""            |
| nomad_acl_enabled         | bool         | Enable Nomad ACLs                                                                | false         |
| nomad_client_cluster_size | number       | Number of nodes to deploy for the Nomad client cluster                           | 3             |
| nomad_cluster_tag_name    | string       | Network tag used to join Nomad regions                                           | ""            |
| nomad_ent                 | bool         | Install Nomad Enterprise - bool                                                  | false         |
| nomad_mode                | string       | Nomad mode none/client/server - Default blank for none                           | ""            |
| nomad_prem                | bool         | Install Nomad premium - bool                                                     | false         |
| nomad_server_cluster_size | number       | Number of nodes to deploy for the Nomad server cluster                           | 3             |
| nomad_server_join_tag     | string       | Cluster tag to WAN join Nomad servers                                            | ""            |
| nomad_version             | string       | Nomad version to install - Default to latest                                     | ""            |
| prem_bucket               | string       | Name of bucket with Premium binaries                                             | ""            |
| terraform_ver             | string       | Terraform version to install - Default to latest                                 | ""            |
| vault_cluster_size        | number       | Number of nodes to deploy for the Vault cluster                                  | 3             |
| vault_ent                 | bool         | Install Vault Enterprise binary - true/false - Defaults to false                 | false         |
| vault_mode                | string       | Vault mode - server/agent - Default to blank or none to not start vault          | ""            |
| vault_prem                | bool         | Install Vault premium binary - true/false - Defaults to false                    | false         |
| vault_storage             | string       | Vault storage to use - raft/consul - Defaults to blank for raft                  | ""            |
| vault_version             | string       | Vault version to install - Defaults to blank for latest                          | ""            |
