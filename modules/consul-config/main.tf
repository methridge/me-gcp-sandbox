data "template_file" "consul_config_template" {
  template = "${file("${path.module}/consul.tmpl")}"
  vars = {
    enable_acls                         = var.enable_acls
    default_acl_policy                  = var.default_acl_policy
    enable_acl_token_persistence        = var.enable_acl_token_persistence
    enable_acl_tokens                   = var.enable_acl_tokens
    master_token                        = var.master_token
    agent_token                         = var.agent_token
    replication_token                   = var.replication_token
    enable_audit                        = var.enable_audit
    audit_file                          = var.audit_file
    configure_autopilot                 = var.configure_autopilot
    autopilot_cleanup_dead_servers      = var.autopilot_cleanup_dead_servers
    autopilot_last_contact_threshold    = var.autopilot_last_contact_threshold
    autopilot_max_trailing_logs         = var.autopilot_max_trailing_logs
    autopilot_server_stabilization_time = var.autopilot_server_stabilization_time
    autopilot_redundancy_zone_tag       = var.autopilot_redundancy_zone_tag
    autopilot_disable_upgrade_migration = var.autopilot_disable_upgrade_migration
    autopilot_upgrade_version_tag       = var.autopilot_upgrade_version_tag
    enable_auto_encrypt                 = var.enable_auto_encrypt
    enable_auto_encrypt_allow_tls       = var.enable_auto_encrypt_allow_tls
    enable_auto_encrypt_tls             = var.enable_auto_encrypt_tls
    enable_tls                          = var.enable_tls
    consul_ca_file                      = var.consul_ca_file
    consul_ca_key_file                  = var.consul_ca_key_file
    consul_cert_file                    = var.consul_cert_file
    consul_key_file                     = var.consul_key_file
    enable_tls_verify_incoming          = var.enable_tls_verify_incoming
    enable_tls_verify_outgoing          = var.enable_tls_verify_outgoing
    enable_tls_verify_server_hostname   = var.enable_tls_verify_server_hostname
    enable_connect                      = var.enable_connect
    enable_mesh_gateway_wan_federation  = var.enable_mesh_gateway_wan_federation
    data_dir                            = var.data_dir
    encrypt_key                         = var.encrypt_key
    enable_node_metadata                = var.enable_node_metadata
    enable_performance_config           = var.enable_performance_config
    raft_multiplier                     = var.raft_multiplier
    enable_ports_config                 = var.enable_ports_config
    dns_port                            = var.dns_port
    http_port                           = var.http_port
    https_port                          = var.https_port
    grpc_port                           = var.grpc_port
    primary_consul_datacenter           = var.primary_consul_datacenter
    primary_consul_gateway              = var.primary_consul_gateway
    consul_wan_join                     = var.consul_wan_join
    server                              = var.server
    raft_protocol_version               = var.raft_protocol_version
    ui                                  = var.ui
    consul_domain                       = var.consul_domain
  }
}
