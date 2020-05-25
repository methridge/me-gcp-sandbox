output sandbox-network {
  value = module.vpc.network_self_link
}

output sandbox-subnet-west1 {
  value = module.vpc.subnets["us-west1/${var.username}-sandbox-subnet-west1"].self_link
}

output sandbox-subnet-west1-cidr {
  value = module.vpc.subnets["us-west1/${var.username}-sandbox-subnet-west1"].ip_cidr_range
}

output sandbox-subnet-central1 {
  value = module.vpc.subnets["us-central1/${var.username}-sandbox-subnet-central1"].self_link
}

output sandbox-subnet-central1-cidr {
  value = module.vpc.subnets["us-central1/${var.username}-sandbox-subnet-central1"].ip_cidr_range
}

output sandbox-subnet-east1 {
  value = module.vpc.subnets["us-east1/${var.username}-sandbox-subnet-east1"].self_link
}

output sandbox-subnet-east1-cidr {
  value = module.vpc.subnets["us-east1/${var.username}-sandbox-subnet-east1"].ip_cidr_range
}
