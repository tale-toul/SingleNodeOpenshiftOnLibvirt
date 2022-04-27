# Single Node Openshift on libvirt KVM

## Introduction

This repository contains terraform templates and ansible playbooks to deploy a [Single Node Openshift](https://docs.openshift.com/container-platform/4.9/installing/installing_sno/install-sno-preparing-to-install-sno.html) (SNO) in a metal instance in AWS.

## Installation instructions

There are two main parts to complete the installation of the SNO host: 
* The creation of the infrastructure resources such as the AWS metal instance, the VPC, subnets, the libvirt virtual network, the support VM, the sno empty VM, etc.
* The Openshift installation in the SNO host.

### Creating the infrastructure resources

The creation of the infrastrucutre resources is divided in 4 parts, all must be completed in order so that the infrastructure components are ready for the Openshift installation.

* **Create the AWS resources**.- To create the AWS resources, the template in the **Terraform** directory is used.  Follow the instructions at [Terraform/README.md](Terraform/README.md)

* **Set up the baremetal host**.- To configure the baremetal instance to support the creation of libvirt KVM resources, the ansible playbook **Ansible/setup_metal.yaml** is used.  Follow the instruction at [Ansible/README.md](Ansible/README.md)

* **Optionally** get more insights about the libvirt resources, run [virt manager](https://virt-manager.org/) on the localhost to connect to the libvirt daemon on the baremetal host.  The command uses the public IP address of the EC2 instance and the _private_ part of the ssh key injected into the instance with terraform.  This command may take a couple minutes to stablish the connection before actually showing the virt-manager interface:
```
$ virt-manager -c 'qemu+ssh://ec2-user@44.200.144.12/system?keyfile=ssh.key'
```

* **Create the libvirt KVM resources**.- To create the libvirt resources inside the baremetal instance, the template in the **Terraform/libvirt** directory is used.  Follow the instructions at [Terraform/libvirt/README.md](Terraform/libvirt/README.md)

* **Set up the DNS and DHCP services**.- To create and configure the DHCP and DNS services, the ansible playbook **Ansible/support_setup.yaml** is used.  Follow the instructions at [Ansible/README.md](Ansible/README.md)

### Installing Openshift

To install Openshift in the SNO, simply boot up the SNO VM, this can be done using virt-manager or the command line.  

To use the CLI, connect to the baremetal instance as the kni user and run the following command:
```
$ ssh kni@34.202.253.44
$ virsh -c qemu:///system sno start
```
The VM will boot from the CDROM that contains the ISO image prepared by the setup_metal.yaml ansible playbook and will start the installation, no further manual intervention needs to be done, the installation should finish successfully after 40 minutes give or take.

To monitor the installation process, ssh into the baremetal host as the **kni** user.  Make sure to [add the ssh key to the shell](Ansible#add-the-common-ssh-key)

```
$ ssh kni@3.219.143.250
```

And run the following command:
```
./openshift-install --dir=ocp wait-for install-complete
```

## Install and set up NGINX

The playbook **rev_proxy.yaml** can be used to install and set up the NGINX reverse proxy automatically.

A specific variable is used in this playbook:

* **ext_dns_zone**.- The external DNS domain for the Openshift _SNO cluster_. This is the public domain used to access the cluster through the reverse proxy and must be resolvable from the clientes connecting to the cluster.

     No default value is defined for this variable.

Other variables are used in the playbook and the jinja2 template that generates the NGINX config file, but they are extracted from the terraform output variables:

* **baremetal_public_ip**.- The public IP address of EC2 metal instance
* **cluster_name**.- Cluster name that is part of the DNS domain. The complete cluster domain is <cluster_name>.<ext_dns_zone> for example (ocp4.redhat.com)
* **dns_zone**.- DNS base zone for the Openshift cluster

The playbook creates two self signed x509 certificates, one for the API endpoint and one for the default ingress controller. Both are valid for the external DNS domain.

Run the playbook with a command like:

```
$ ansible-playbook -i inventory -vvv rev_proxy.yaml -e ext_dns_zone=redhat.com
```

## Accessing the cluster
Accessing the cluster is done in the same way as for any other cluster, except that the DNS domain used is the external one defined in NGINX virtual servers:

* Using the __oc__ client

    To login using the __oc__ client use the external name defined in the virtual server and the 6443 port.  In the following example the certificate used in NGINX is extracted from the cluster, hence the warning message.
```
$ oc login -u kubeadmin -p fI...geI https://api.ocp4.redhat.com:6443
```

* Access to application routes

    For secure and non secure routes, the URL must contain the external DNS domain defined in the NGINX virtual servers.  In the following example the external domain is **redhat.com**:
```
$ curl http://httpd-example-bandido.redhat.com/
```
* Access to the web console and oauth service

    For the special case of the web console and oauth service, the URL must use the internal DNS domain (https://console-openshift-console.apps.ocp4.tale.net and  https://oauth-openshift.apps.ocp4.tale.net).  This can be achieved by adding this names to the hosts file in the local host.

## Destroying the infrastructure

There are two levels of infrastructure that can be eliminated: the libvirt resources and the AWS resouces.

To destroying the libivrt resources. go to the Terraform/libvirt directory in the controlling host and run a command with the same options that were used to create them, but using the destroy subcommand instead.

```
$ terraform destroy -var-file monaco.vars
```

Destroying the libvirt resources will also destroy the Openshift running in the SNO host, if it was already installed.

To destroy the AWS resources, go to the Terraform directory in the controlling host and run a command with the same options that were used to create them, but using the destroy subcommand:

```
$ terraform destroy -var="region_name=us-east-1" -var="ssh-keyfile=baremetal-ssh.pub" -var="instance_type=c5.metal"
```

Destroying the AWS resources will cause the destruction of the libvirt resources and the Openshift that may exist inside the EC2 instance.
