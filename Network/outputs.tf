output sandbox-network {
  value = module.vpc.network_self_link
}

output sandbox-subnet-region-1 {
  value = module.vpc.subnets["${var.region-name-1}/${var.username}-sandbox-subnet-region-1"].self_link
}

output sandbox-subnet-region-1-cidr {
  value = module.vpc.subnets["${var.region-name-1}/${var.username}-sandbox-subnet-region-1"].ip_cidr_range
}

output sandbox-subnet-region-2 {
  value = module.vpc.subnets["${var.region-name-2}/${var.username}-sandbox-subnet-region-2"].self_link
}

output sandbox-subnet-region-2-cidr {
  value = module.vpc.subnets["${var.region-name-2}/${var.username}-sandbox-subnet-region-2"].ip_cidr_range
}

output sandbox-subnet-region-3 {
  value = module.vpc.subnets["${var.region-name-3}/${var.username}-sandbox-subnet-region-3"].self_link
}

output sandbox-subnet-region-3-cidr {
  value = module.vpc.subnets["${var.region-name-3}/${var.username}-sandbox-subnet-region-3"].ip_cidr_range
}
