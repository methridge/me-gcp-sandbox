# EA Google Cloud Sandbox

This repository contains a series of Terraform configurations that can be used
to build the following

1. A "HashiStack" in a single or multiple regions
   1. Each "HashiStack" consists of the following:
      - 1 Bastion host
      - 3 Consul servers
      - 3 Vault server
        - Using Integrated Storage (Raft) -or-
        - using the above Consul servers for storage
      - 3 Nomad servers
      - 3 Nomad clients

## Requirements

To use these Terraform configs you will need to setup the following.

1. A GCP project
1. A
   [OAuth2 token](https://jryancanty.medium.com/stop-downloading-google-cloud-service-account-keys-1811d44a97d9)
   to use with Terraform
1. (Optional) A domain name or subdomain
1. (Optional) The above domain name setup in
   [Cloud DNS](https://cloud.google.com/dns) in the project

## Sandbox Setup

Setup of our sandbox is done in two phases. The first phase is the base network
and DNS creation. These components will rarely be changed and are needed by the
other modules as inputs. It is recommended to store the state files for both of
these in cloud storage (Terraform Cloud, GCP Storage Bucket, etc.), as we use
these remote state files as data sources for all our sandbox deployments.

The second phase will be the setup of our various testing environments.

### Setup Network Foundation

We need to create the VPC and subnets that will be used by all the systems
first. The Terraform config for this is in the
[GCP Sandbox Network](https://github.com/methridge/me-gcp-sandbox-network) repo.

### Setup DNS Zone

Create subdomain for services. The Terraform config for this is in the
[GCP Sandbox DNS](https://github.com/methridge/me-gcp-sandbox-dns) repo.

## Sandbox Image

### Image login

Setup
[OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access)

Login to OS will be <username>\_hashicorp_com (as in your e-mail
username@hashicorp.com)

### Building Image

We use a custom Ubuntu 20.04 image for all the "HashiStack" systems. This image
is built with Packer.

Update at least the following variables in the file `packer/variables.pkr.hcl`

```
"username":
"project_id":
"zone":
```

Build image with `packer build -force .` while in the `packer` directory.
