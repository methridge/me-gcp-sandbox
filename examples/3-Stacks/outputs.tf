output "region-bastion-dns" {
  value = {
    for k, v in module.region-stack : k => trimsuffix(v.region-bastion-dns, ".")
  }
}

output "region-bastion-ips" {
  value = {
    for k, v in module.region-stack : k => v.region-bastion-ip
  }
}

output "region-lb-dns" {
  value = {
    for k, v in module.region-stack : k => trimsuffix(v.region-lb-dns, ".")
  }
}

output "region-lb-ips" {
  value = {
    for k, v in module.region-stack : k => v.region-lb-ip
  }
}

output "region-glb-ips" {
  value = {
    for k, v in module.region-stack : k => v.region-lb-global-ip
  }
}

output "region-consul" {
  value = {
    for k, v in module.region-stack : k => trimsuffix("https://${v.region-consul-dns}", ".")
  }
}

output "region-nomad" {
  value = {
    for k, v in module.region-stack : k => trimsuffix("https://${v.region-nomad-dns}", ".")
  }
}

output "region-vault" {
  value = {
    for k, v in module.region-stack : k => trimsuffix("https://${v.region-vault-dns}", ".")
  }
}
