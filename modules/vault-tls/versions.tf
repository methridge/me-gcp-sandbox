terraform {
  required_version = ">= 0.15.0"
  required_providers {
    google = {
      version = ">= 3.5"
    }
    tls = {
      version = ">= 3.0"
    }
  }
}
