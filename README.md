# Single Node Openshift on libvirt KVM

## Introduction

This repository contains terraform templates and ansible playbooks to deploy a [Single Node Openshift](https://docs.openshift.com/container-platform/4.9/installing/installing_sno/install-sno-preparing-to-install-sno.html) (SNO) in a metal instance in AWS.

## Installation instructions

There are two main parts to complete the installation of the SNO host: 
* The creation of the infrastructure resources such as the AWS metal instance, the VPC, subnets, the libvirt virtual network, the support VM, the sno empty VM, etc.
* The Openshift installation in the sno VM.

### Creating the infrastructure resources

The creation of the infrastrucutre resources is divided in 4 parts, and each one must be completed in order using a different terraform template or ansible playbook

* **Creating the AWS resources**.- To create the AWS resources, the template in the **Terraform** directory is used.  Follow the instructions at [Terraform/README.md](Terraform/README.md)

* **Setting up the baremetal host**.- To configure the baremetal instance to support the creation of libvirt KVM resources, the ansible playbook **Ansible/setup_metal.yaml** is used.  Follow the instruction at [Ansible/README.md](Ansible/README.md)

* **Creating the libvirt KVM resources**.- To create the libvirt resources inside the baremetal instance, the template in the **Terraform/libvirt** directory is used.  Follow the instructions at [Terraform/libvirt/README.md](Terraform/libvirt/README.md)

* **Setting up the DNS and DHCP services**.- To create and configure the DHCP and DNS services, the ansible playbook **Ansible/support_setup.yaml** is used.  Follow the instructions at [Ansible/README.md](Ansible/README.md)

### Installing Openshift

Boot up the SNO VM, this can be done using virt-manager or the command line:

```
$ virsh -c qemu:///system sno start
```
The VM will boot from the CDROM that contains the ISO image prepared to start the installation, nothing else needs to be done, the installation should finish successfully after 40 minutes give or take.

To monitor the installation process, ssh into the baremetal host as the **kni** user.  Make sure to [add the ssh key to the shell](Ansible#add-the-common-ssh-key)

```
$ ssh kni@3.219.143.250
```

And run the following command:
```
./openshift-install --dir=ocp wait-for install-complete
```
