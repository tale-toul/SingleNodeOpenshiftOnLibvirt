terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}
data "terraform_remote_state" "ec2_instance" {
  backend = "local"

  config = {
    path = "../terraform.tfstate"
  }
}

provider "libvirt" {
  uri = "qemu+ssh://ec2-user@${data.terraform_remote_state.ec2_instance.outputs.baremetal_public_ip}/system?keyfile=../${data.terraform_remote_state.ec2_instance.outputs.ssh_certificate}"
}

#Default storage pool
resource "libvirt_pool" "pool_default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"
}

#Networks
resource "libvirt_network" "chucky" {
  name = "chucky"
  mode = "nat"
  addresses = [var.chucky_net_addr]
  bridge = "chucky"
  autostart = true

  dhcp {
    enabled = false
  }
}

#RHEL base image
resource "libvirt_volume" "rhel_volume" {
  name = "rhel8_base.qcow2"
  source = "${var.rhel8_image_location}"
  format = "qcow2"
  depends_on = [libvirt_pool.pool_default]
}

##WORKER NODES
##Worker volumes
#resource "libvirt_volume" "worker_volumes" {
#  count = var.number_of_workers
#  name = "worker${count.index}.qcow2"
#  pool = "default"
#  format = "qcow2"
#  #120GB
#  size = 128849018880
#  depends_on = [libvirt_pool.pool_default]
#}
#
##Worker VMs
#resource "libvirt_domain" "worker_domains" {
#  count = var.number_of_workers
#  name = "sno-worker${count.index}"
#  running = false
#  autostart = false
#
#  memory = var.worker_resources.memory
#  vcpu   = var.worker_resources.vcpu
#
#  disk {
#    volume_id = libvirt_volume.worker_volumes[count.index].id
#  }
#
#  dynamic "network_interface" {
#    for_each = toset(libvirt_network.provision[*].id)
#    content {
#      network_id = network_interface.key
#      mac        = format("${var.worker_provision_mac_base}%x",count.index)
#    }
#  }
#
#  network_interface {
#    network_id = libvirt_network.chucky.id
#    mac        = format("${var.worker_chucky_mac_base}%x",count.index)
#  }
#
#  boot_device {
#    dev = ["hd","network"]
#  }
#
#  graphics {
#    type = "vnc"
#    listen_type = "address"
#    listen_address = "0.0.0.0"
#  }
#
#  console {
#    type        = "pty"
#    target_port = "0"
#    target_type = "virtio"
#  }
#}

#Support VM
#Support volume
resource "libvirt_volume" "support_volume" {
  name = "support.qcow2"
  base_volume_id = libvirt_volume.rhel_volume.id
  #50GB
  size = 53687091200
}

resource "libvirt_cloudinit_disk" "support_cloudinit" {
  name = "support.iso"
  pool = libvirt_pool.pool_default.name
  user_data = templatefile("${path.module}/support_cloud_init.tmpl", { auth_key = file("${path.module}/../${data.terraform_remote_state.ec2_instance.outputs.ssh_certificate}") })
  network_config = templatefile("${path.module}/support_network_config.tmpl", { address = "${local.support_host_ip}/24", nameserver = var.support_net_config_nameserver, gateway = local.chucky_gateway })
}

#Support VM
resource "libvirt_domain" "support_domain" {
  name = "support"
  running = true
  autostart = false

  memory = var.support_resources.memory
  vcpu   = var.support_resources.vcpu
  cloudinit = libvirt_cloudinit_disk.support_cloudinit.id

  disk {
    volume_id = libvirt_volume.support_volume.id
  }

  network_interface {
    network_id = libvirt_network.chucky.id
  }

  graphics {
    type = "vnc"
    listen_type = "address"
    listen_address = "0.0.0.0"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "virtio"
  }
}