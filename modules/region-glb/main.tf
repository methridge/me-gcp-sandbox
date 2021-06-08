locals {
  dnszone = trimsuffix(var.dnszone, ".")
}

# Generate SSL cert for LB
resource "google_compute_ssl_certificate" "default" {
  name_prefix = "${var.region}-glb-cert"
  project     = var.project
  description = "GLB TLS for *.${var.region}.${local.dnszone}"
  private_key = var.region_tls_priv_key
  certificate = var.region_tls_cert_chain

  lifecycle {
    create_before_destroy = true
  }
}

# resource "google_compute_managed_ssl_certificate" "default" {
#   name    = "${var.region}-glb-cert"
#   project = var.project

#   managed {
#     domains = [
#       "consul.${var.region}.${var.dnszone}",
#       "nomad.${var.region}.${var.dnszone}",
#       "vault.${var.region}.${var.dnszone}"
#     ]
#   }
# }

resource "google_compute_target_https_proxy" "region_proxy" {
  name             = "${var.region}-https-proxy"
  project          = var.project
  url_map          = google_compute_url_map.region-url-map.id
  ssl_policy       = google_compute_ssl_policy.ssl.self_link
  ssl_certificates = [google_compute_ssl_certificate.default.id]
  # ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_url_map" "region-url-map" {
  name        = "${var.region}-urlmap"
  project     = var.project
  description = "${var.region} HashiStack Enterprise"

  default_url_redirect {
    host_redirect = "https://hashicorp.com"
    strip_query   = true
  }

  host_rule {
    hosts        = ["consul.${var.region}.${local.dnszone}"]
    path_matcher = "consul"
  }

  host_rule {
    hosts        = ["nomad.${var.region}.${local.dnszone}"]
    path_matcher = "nomad"
  }

  host_rule {
    hosts        = ["vault.${var.region}.${local.dnszone}"]
    path_matcher = "vault"
  }

  path_matcher {
    name            = "consul"
    default_service = google_compute_backend_service.consul_be.id
  }

  path_matcher {
    name            = "nomad"
    default_service = google_compute_backend_service.nomad_be.id
  }

  path_matcher {
    name            = "vault"
    default_service = google_compute_backend_service.vault_be.id
  }
}

# Backend Services
resource "google_compute_backend_service" "consul_be" {
  name                  = "${var.region}-consul-be"
  project               = var.project
  port_name             = "consul"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 60

  backend {
    description    = "Consul Application"
    group          = var.consul_ig
    balancing_mode = "UTILIZATION"
  }

  health_checks   = [var.consul_hc]
  security_policy = google_compute_security_policy.security-policy-1.self_link
}

resource "google_compute_backend_service" "nomad_be" {
  name                  = "${var.region}-nomad-be"
  project               = var.project
  port_name             = "nomad"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 60

  backend {
    description    = "Nomad Application"
    group          = var.nomad_ig
    balancing_mode = "UTILIZATION"
  }

  health_checks   = [var.nomad_hc]
  security_policy = google_compute_security_policy.security-policy-1.self_link
}

resource "google_compute_backend_service" "vault_be" {
  name                  = "${var.region}-vault-be"
  project               = var.project
  port_name             = "vault"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 60

  backend {
    description    = "Vault Application"
    group          = var.vault_ig
    balancing_mode = "UTILIZATION"
  }

  health_checks   = [var.vault_hc]
  security_policy = google_compute_security_policy.security-policy-1.self_link
}

resource "google_compute_global_forwarding_rule" "https-app" {
  name       = "${var.region}-https-app"
  project    = var.project
  target     = google_compute_target_https_proxy.region_proxy.id
  port_range = "443"
}

# TLS Security Policy
resource "google_compute_security_policy" "security-policy-1" {
  name        = "${var.region}-cloudarmor-policy-1"
  project     = var.project
  description = "${var.region} Cloud Armor policy"

  # Whitelist traffic from certain ip address
  rule {
    action   = "allow"
    priority = "100"

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = var.ip_allow_list
      }
    }

    description = "allow traffic from "
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }

    description = "Default deny all rule."
  }
}

resource "google_compute_ssl_policy" "ssl" {
  name            = "${var.region}-ssl-pol"
  project         = var.project
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}
