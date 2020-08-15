variable enable_acls {
  description = "Enable Consul ACLs"
  default     = false
}

variable default_acl_policy {
  description = "Default ACL policy"
  default     = "allow"
}

variable enable_acl_token_persistence {
  description = "Enable Consul Agent token persistence"
  default     = false
}

variable enable_acl_tokens {
  description = "Put ACL tokens in config"
  default     = false
}

variable master_token {
  description = ""
  default     = ""
}

variable agent_token {
  description = ""
  default     = ""
}

variable replication_token {
  description = ""
  default     = ""
}

variable enable_audit {
  description = ""
  default     = false
}

variable audit_file {
  description = ""
  default     = "data/audit/audit.json"
}

variable configure_autopilot {
  description = ""
  default     = false
}

variable autopilot_cleanup_dead_servers {
  description = ""
  default     = true
}

variable autopilot_last_contact_threshold {
  description = ""
  default     = ""
}

variable autopilot_max_trailing_logs {
  description = ""
  default     = ""
}

variable autopilot_server_stabilization_time {
  description = ""
  default     = ""
}

variable autopilot_redundancy_zone_tag {
  description = ""
  default     = ""
}

variable autopilot_disable_upgrade_migration {
  description = ""
  default     = false
}

variable autopilot_upgrade_version_tag {
  description = ""
  default     = ""
}

variable enable_auto_encrypt {
  description = ""
  default     = false
}

variable enable_auto_encrypt_allow_tls {
  description = ""
  default     = false
}

variable enable_auto_encrypt_tls {
  description = ""
  default     = false
}

variable enable_tls {
  description = ""
  default     = false
}

variable consul_ca_file {
  description = ""
  default     = ""
}

variable consul_ca_key_file {
  description = ""
  default     = ""
}

variable consul_cert_file {
  description = ""
  default     = ""
}

variable consul_key_file {
  description = ""
  default     = ""
}

variable enable_tls_verify_incoming {
  description = ""
  default     = false
}

variable enable_tls_verify_outgoing {
  description = ""
  default     = false
}

variable enable_tls_verify_server_hostname {
  description = ""
  default     = false
}

variable enable_connect {
  description = ""
  default     = false
}

variable enable_mesh_gateway_wan_federation {
  description = ""
  default     = false
}

variable data_dir {
  description = ""
  default     = "/opt/consul/data"
}

variable encrypt_key {
  description = ""
  default     = ""
}

variable enable_node_metadata {
  description = ""
  default     = false
}

variable enable_performance_config {
  description = ""
  default     = false
}

variable raft_multiplier {
  description = ""
  default     = 1
}

variable enable_ports_config {
  description = ""
  default     = false
}

variable dns_port {
  description = ""
  default     = 8600
}

variable http_port {
  description = ""
  default     = 8500
}

variable https_port {
  description = ""
  default     = 8501
}

variable grpc_port {
  description = ""
  default     = 8502
}

variable primary_consul_datacenter {
  description = ""
  default     = ""
}

variable primary_consul_gateway {
  description = ""
  default     = ""
}

variable consul_wan_join {
  description = ""
  default     = false
}

variable server {
  description = ""
  default     = false
}

variable raft_protocol_version {
  description = ""
  default     = 3
}

variable ui {
  description = ""
  default     = true
}

variable consul_domain {
  description = ""
  default     = ""
}
