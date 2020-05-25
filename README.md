# EA Google Cloud Sandbox

This repository contains a series of Terraform configurations that can be used
to build the following

1. An instance of Terraform Enterprise using external services
1. A "HashiStack" in a single or multiple regions
   1. Each "HashiStack" consists of the following:
      - 1 Bastion host
      - 3 Consul servers
      - 3 Vault server using the above Consul servers for storage
      - 3 Nomad servers
      - 3 Nomad clients

## Requirements

To use these Terraform configs you will need to setup the following.

1. A GCP project
1. A
   [service account key file](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
   to use with Terraform
1. (Optional) A domain name or subdomain
1. (Optional) The above domain name setup in
   [Cloud DNS](https://cloud.google.com/dns) in the project

## Sandbox Setup

Setup of our sandbox is done in two phases. The first phase is the base network
and DNS creation. These components will rarely be changed and are needed by the
other modules as inputs.

The second phase will be the setup of our various testing environments.

### Setup Network Foundation

We need to create the VPC and subnets that will be used by all the systems
first. The Terraform config for this is in the `Network` folder.

### Setup DNS Zone

Create subdomain for services. The Terraform config for this is in the
`DNS-Zone` folder.

### Vault TLS Certificate

We use `cfssl` to generate self-signed TLS certificates for Vault.

Update the vaules in the `tls/vault-csr.json` file. Then run `make` or
`make vault` to generate your TLS certificates.

All of the produced `*.pem` files need to be copied from the `tls` folder to the
`packer/files` folder.

## Sandbox Image

### Premium Binaries

If you are going to use the HashiCorp premium (pre-licensed) binaries, these
will need to be uploaded to a storage bucket.

:TODO: change storage bucket to variable

### Image login

Setup
[OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access)

Login to OS will be <username>\_hashicorp_com (as in your e-mail
username@hashicorp.com)

### Building Image

We use a custom Ubuntu 20.04 image for all the "HashiStack" systems. This image
is built with Packer.

Update at least the following variables at the top of the file
`packer/sandbox.json`

```
"username":
"gcp_account_file":
"project_id":
"zone":
```

Build image with `packer build -force sandbox.json`
