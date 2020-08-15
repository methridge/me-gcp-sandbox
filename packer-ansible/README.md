# Packer Manifests

- Update variables `sandbox.json`:

  - Set `username`
  - Set `gcp_account_file` to your GCP `json` service key file
  - Set `project_id` to your GCP project name
  - Set `zone` to the zone to build the image in. Does not have to be the same
    as where you will deploy.

- Update `vars/main.yml`:

  - Set HashiCorp product versions
  - Set `true/false` for Premium versions

- Validate packer manifest

  - `packer validate sandbox.json`
  - `packer build sandbox.json`
