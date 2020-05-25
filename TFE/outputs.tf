output "tfe" {
  description = "TFE access values."
  value = {
    app_url          = "https://${var.subdomain}.${var.hostname}"
    console_url      = "https://${var.subdomain}.${var.hostname}:8800"
    lb_public_ip     = module.load-balancer.load_balancer_ip
    console_password = module.configs.console_password
  }
}
