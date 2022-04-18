#OUTPUT
output "chucky_net_addr" {
  value       = var.chucky_net_addr
  description = "Network address for the routable chucky network"
}

output "worker_chucky_mac_base" {
  value       = var.worker_chucky_mac_base
  description = "MAC address common part for the worker NICs in the chucky network"
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

#output "worker_names" {
#  value     = libvirt_domain.worker_domains[*].name
#  description = "List of worker node names"
#}

#output "number_of_workers" {
#  value     = var.number_of_workers
#  description = "How many worker nodes have been created"
#}

output "dns_zone" {
  value     = var.dns_zone
  description = "DNS base zone for the Openshift cluster"
}

output "ocp_version" {
  value = var.ocp_version
  description = "Openshift version number to be deployed"
}
