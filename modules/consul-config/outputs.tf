output "config" {
  value = replace(data.template_file.consul_config_template.rendered, "/\n{2,}/", "\n")
}
