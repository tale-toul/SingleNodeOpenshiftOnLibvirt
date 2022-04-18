#VARIABLES
variable "rhel8_image_location" {
 description = "Path and name to the RHEL 8 qcow2 image to be used as base image for VMs"
  type = string
  default = "rhel8.qcow2"
}

variable "support_resources" {
  description = "Ammount of CPU and memory resources assigned to the support VM"
  type = object({
    memory = string
    vcpu = number
  })
  default = {
    memory = "24576"
    vcpu = 4
  }
}

variable "worker_resources" {
  description = "Ammount of CPU and memory resources assigned to the worker VMs"
  type = object({
    memory = string
    vcpu = number
  })
  default = {
    memory = "16384"
    vcpu = 4
  }
}

variable "number_of_workers" {
  description = "How many worker VMs to create"
  type = number
  default = 3

  validation {
    condition = var.number_of_workers > 0 && var.number_of_workers <= 16
    error_message = "The number of workers that can be created with terraform must be between 1 and 16."
  }
}

variable "chucky_net_addr" {
  description = "Network address for the routable chucky network"
  type = string
  default = "192.168.30.0/24"
}

variable "support_net_config_nameserver" {
  description = "DNS server IP for the support VM's network configuration"
  type = string
  default = "8.8.8.8"
}

variable "dns_zone" {
  description = "Internal DNS base zone for the Openshift cluster"
  type = string
  default = "tale.net"
}

variable "cluster_name" {
  description = "Cluster name which is part of the internal DNS domain"
  type = string
  default = "ocp4"
}

variable "ocp_version" {
  description = "Openshift version number to be deployed"
  type = string
  default = "4.9.5"
}

#MAC ADDRESSES
#The letters in the MACs should be in lowercase
variable "worker_chucky_mac_base" {
  description = "MAC address common part for the worker NICs in the chucky network"
  type = string
  default = "52:54:00:a9:6d:9"
}

locals {

  #IP address for the support VM in the chucky network
  support_host_ip =            replace(var.chucky_net_addr,".0/24",".3")

  #Gateway IP for the routable chucky network
  chucky_gateway = replace(var.chucky_net_addr,".0/24",".1")

  #IP address for the OCP API VIP, in routable chucky network
  api_vip = replace(var.chucky_net_addr,".0/24",".100")

  #IP address for the OCP ingress VIP, in routable chucky network
  ingress_vip = replace(var.chucky_net_addr,".0/24",".100")
}
