#OUTPUT
output "chucky_net_addr" {
  value       = var.chucky_net_addr
  description = "Network address for the routable chucky network"
}

output "support_host_ip" {  
 value       = local.support_host_ip
 description = "The support host IP address in the routable network"
}

output "api_vip" {
  value      = local.api_vip
  description = "IP address for the OCP API VIP, in routable chucky network"
}

output "ingress_vip" {
  value      = local.ingress_vip
  description = "IP address for the OCP ingress VIP, in routable chucky network"
}

output "chucky_gateway" {
  value       = local.chucky_gateway
  description = "Gateway IP for the routable chucky network"
}

output "dns_zone" {
  value     = var.dns_zone
  description = "DNS base zone for the Openshift cluster"
}

output "cluster_name" {
  value = var.cluster_name
  description = "Cluster name that is part of the DNS domain"
}

output "ocp_version" {
  value = var.ocp_version
  description = "Openshift version number to be deployed"
}

output "sno_mac" {
  value       = var.sno_mac
  description = "MAC address for the SNO VM NIC"
}
