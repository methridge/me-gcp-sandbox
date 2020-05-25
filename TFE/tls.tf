# Generate Let's Encrypt
# Need dns challenge ENV vars set
provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "acme" {
  algorithm = "RSA"
}

resource "acme_registration" "tls" {
  account_key_pem = tls_private_key.acme.private_key_pem
  email_address   = var.admin_email
}

resource "acme_certificate" "tls" {
  account_key_pem = acme_registration.tls.account_key_pem
  common_name     = "*.${var.hostname}"

  dns_challenge {
    provider = "gcloud"
    config = {
      GCE_PROJECT              = var.project
      GCE_SERVICE_ACCOUNT_FILE = var.credentials
    }
  }
}

resource "local_file" "pfx" {
  filename       = "./keys/acme.pfx"
  content_base64 = acme_certificate.tls.certificate_p12
}

resource "local_file" "tls-issuer" {
  filename = "./keys/issuer.cert"
  content  = acme_certificate.tls.issuer_pem
}

resource "local_file" "tls-certificate" {
  filename = "./keys/certificate.cert"
  content  = "${acme_certificate.tls.certificate_pem}\n${acme_certificate.tls.issuer_pem}"
}

resource "local_file" "tls-key" {
  filename = "./keys/private.key"
  content  = acme_certificate.tls.private_key_pem
}

resource "null_resource" "pfx-generation" {
  provisioner "local-exec" {
    command = "openssl pkcs12 -export -out ${var.certificate_path} -inkey ./keys/private.key -in ./keys/certificate.cert -certfile ./keys/issuer.cert -password pass:"
  }
  depends_on = [local_file.tls-issuer, local_file.tls-certificate, local_file.tls-key]
}

resource "google_compute_ssl_certificate" "default" {
  name_prefix = "tfegcp-cert"
  description = "ACME generated TLS for ${acme_certificate.tls.certificate_domain}"
  private_key = local_file.tls-key.content
  certificate = local_file.tls-certificate.content

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_dns_record_set" "tfe-a" {
  project      = var.project
  name         = "${var.subdomain}.${var.hostname}."
  type         = "A"
  ttl          = 60
  managed_zone = data.terraform_remote_state.dns.outputs.sandbox-dnszone-name
  rrdatas      = [module.load-balancer.load_balancer_ip]
}
