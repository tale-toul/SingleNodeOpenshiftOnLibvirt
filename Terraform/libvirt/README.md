# Libvirt/KVM based infrastructure with terraform

This directory contains the terraform templates and support files required to deploy the KVM/libvirt based infrastructure components required to deploy the baremetal IPI OCP cluster.

## Module initialization

Before running terraform for the first time, the modules used by the template must be downloaded and initialized, this requires an active Internet connection.  

Run the following command in the directory where the terraform templates reside.  The command can be safely run many times, it will not trampled previous executions:
```
$ cd libvirt
$ terraform init

Initializing the backend...

Initializing provider plugins...
- terraform.io/builtin/terraform is built in to Terraform
- Reusing previous version of dmacvicar/libvirt from the dependency lock file
- Reusing previous version of hashicorp/template from the dependency lock file
- Using previously-installed dmacvicar/libvirt v0.6.14
- Using previously-installed hashicorp/template v2.2.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
## Input variables

Many aspects of the infrastructure created by terraform can be modified by assigning different values to the variables defined in the file **input-vars.tf**

All variables contain default values so it is not neccessary to modify them in order to create a funtioning infrastructure. 

Most of the input variables used to configure the infrastructure are defined in the inpu-vars.tf file to simplify and organize the information, even if they are not used by terraform.  For example the variable **ocp_version** is not used by terraform however is defined here.  Most of the input variables are also defined as output variables so they can be used later by the ansible playbooks.

The list of variables its purpose and default value are:

* **rhel8_image_location**.- Path and filename to the qcow2 image to be used as the base for the operating system in the support and provision VMs

     Default value: rhel8.qcow2

* **support_resources**.-  Object variable with two fields:

     memory.- The ammount of memory in MB to be assigned to the support VM

     vcpu.- The number of CPUS to be assigned to the support VM

     Default values: memory = 24576    vcpu = 4

* **sno_resources**.-  Object variable with two fields:

     memory.- The ammount of memory in MB to be assigned to the sno VM

     vcpu.- The number of CPUS to be assigned to the sno VM

     Default values: memory = 32768 (32GB)   vcpu = 8

* **chucky_net_addr**.- Network address for the routable network where all VMs are connected

     Default value: 192.168.30.0/24

* **support_net_config_nameserver**.- IP address for the external DNS server used by the support host.  This name server is initialy used to resolve host names so the support host can register and install packages.

     Default value: 8.8.8.8

* **sno_mac**.- MAC address for the SNO VM NIC in the routable (chucky) network.  This is used in the DHCP server to assign a known IP to the provision VM in the chucky network.  The letters in the MACs should be in lowercase.

     Default value: 52:54:00:9d:41:3c

### Assigning values to input variables

There are 3 different ways in which to assign new values to the input variables describe above:

* Modify the default value in the input-vars.tf file.- All variables have a defalt line, so it is possible to just edit the file and assign the desired value by editing the **default =** line.
```
variable "chucky_net_addr" {
  description = "Network address for the routable chucky network"
  type = string
  default = "10.0.4.0/24"
}
```
* Assing the values in the command line.- Values assigned in the command line overwrite the default values in the input-vars.tf file.
```
$ terraform apply -var='number_of_workers=6'  -var='cluster_name="monaco"' -var='worker_resources={"memory":"16384","vcpu":6}' \
  -var='chucky_net_addr=192.168.55.0/24' -var='support_net_config_nameserver=169.254.169.253' -var='dns_zone=benaka.cc'
```
* Add the variable assignments to a file and call that file in the command line.  For example, the following content is added to the file monaco.vars

```
cluster_name = "monaco"
support_resources = {"memory":"16384","vcpu":6}
chucky_net_addr = "192.168.55.0/24"
support_net_config_nameserver = "169.254.169.253"
dns_zone = "benaka.cc"
```
And the terraform command to use those definitions is:
```
$ terraform apply -var-file monaco.vars
```

## Deploying the infrastructure

* Add the RHEL 8 disk image 

     Get the qcow2 image for RHEL 8 from [https://access.redhat.com/downloads/](https://access.redhat.com/downloads/), click on Red Hat Enterprise Linux 8 and download Red Hat Enterprise Linux 8.5 KVM Guest Image.

     Keep in mind that the RHEL image is more than 700MB in size so a fast Internet connection is recommended.

     Copy the image to **Terraform/libvirt/rhel8.qcow2**.  This is the default location and name that the terraform template uses to locate the file, if the file is in a different location or has a different name, update the variable **rhel8_image_location** by defining the variable in the command line.
```
$ cp /home/user1/Downloads/rhel-8.5-x86_64-kvm.qcow2 Terraform/libvirt/rhel8.qcow2
```

* If this is a fresh deployment, delete any previous **terraform.tfstate** file that may be laying around from previous attempts.

* Use a command like the following to deploy the infrastructure.  
```
$ terraform apply -var-file monaco.vars
```

## Created resources
The template creates the following components:
* A storage pool.- This is the default storage pool, of type directory, using /var/lib/libvirt/images directory
* A network. Routable with DHCP disable 
* A base disk volume using a RHEL8 image, this will be used as the base image for all the VMs that are created later.
* A disk volume based on the RHEL8 base volume that will be the OS disk for the support VM.  
* A cloud init disk for the support VM, containing the user data and network configuration defined by two template files.
* A support VM.  This VM runs the DHCP and DNS services for the OCP cluster.  It is only connected to the routable (chucky) network.

## Dependencies 
This terraform template depends on the output variables from the main terraform template that creates the metal instance in AWS.  The output variables are obtained from a local backend:

```
data "terraform_remote_state" "ec2_instance" {
  backend = "local"

  config = {
    path = "../terraform.tfstate"
  }
}
```
Later in the template some of the output variables are used to define components.  In the following example the URI to connect to the libvirt service in the remote EC2 host gets the IP and the public ssh key from the output variables:
```
provider "libvirt" {
  uri = "qemu+ssh://ec2-user@${data.terraform_remote_state.ec2_instance.outputs.baremetal_public_ip}/system?keyfile=../${data.terraform_remote_state.ec2_instance.outputs.ssh_certificate}"
}
```
The result from applying the variables is something like:
```
  uri = "qemu+ssh://ec2-user@3.223.112.4/system?keyfile=../baremetal-ssh.pub"
```

## Troubleshooting

### Missing iptables chains

Sometimes during the creation of resources an error like the following appears:
```
 Error: error creating libvirt network: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface chucky --protocol tcp --destination-port 67 --jump ACCEPT: iptables: No chain/target/match by that name.
│ 
│ 
│   with libvirt_network.chucky,
│   on libvirt.tf line 28, in resource "libvirt_network" "chucky":
│   28: resource "libvirt_network" "chucky" {
```
Checking the firewall rules in the metal instance shows an empty list, which matches the error above that some table target or match is missing:
```
$ sudo iptables -L -nv
Chain INPUT (policy ACCEPT 252K packets, 794M bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 190K packets, 12M bytes)
 pkts bytes target     prot opt in     out     source               destination 
```
Checking the libvirtd service also shows the iptables error messages:
```
$ sudo systemctl status libvirtd
● libvirtd.service - Virtualization daemon
   Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2022-04-07 07:07:06 UTC; 11min ago
     Docs: man:libvirtd(8)
           https://libvirt.org
 Main PID: 42387 (libvirtd)
    Tasks: 19 (limit: 32768)
   Memory: 806.6M
   CGroup: /system.slice/libvirtd.service
           ├─42387 /usr/sbin/libvirtd --timeout 120
           ├─43705 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
           └─43707 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper

Apr 07 07:07:09 ip-172-20-8-165.ec2.internal libvirtd[42387]: libvirt version: 6.0.0, package: 37.1.module+el8.5.0+13858+39fdc467 (Red Hat, Inc. <http://bugzilla.redhat.com/bugzilla>, 2022->
Apr 07 07:07:09 ip-172-20-8-165.ec2.internal libvirtd[42387]: hostname: ip-172-20-8-165.ec2.internal
Apr 07 07:07:09 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface virbr0 >
Apr 07 07:09:30 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface chucky >
Apr 07 07:09:30 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface provisi>
Apr 07 07:12:00 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface chucky >
Apr 07 07:12:00 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface provisi>
Apr 07 07:13:51 ip-172-20-8-165.ec2.internal libvirtd[42387]: failed to remove pool '/var/lib/libvirt/images': Device or resource busy
Apr 07 07:14:43 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface provisi>
Apr 07 07:14:44 ip-172-20-8-165.ec2.internal libvirtd[42387]: internal error: Failed to apply firewall rules /usr/sbin/iptables -w --table filter --insert LIBVIRT_INP --in-interface chucky
```
To recreate the missing iptables rules, tables, etc. Restart the libvirtd service:
```
$ sudo systemctl restart libvirtd
```
If the service starts successfully a long list of iptables rules and chains are created, including several LIBVIRT\_<suffix> chains:
```
$ sudo iptables -L -nv
Chain INPUT (policy ACCEPT 537K packets, 1590M bytes)
 pkts bytes target     prot opt in     out     source               destination         
   66  4592 LIBVIRT_INP  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
...
Chain LIBVIRT_INP (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 ACCEPT     udp  --  virbr0 *       0.0.0.0/0            0.0.0.0/0            udp dpt:53
...
Chain LIBVIRT_OUT (1 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 ACCEPT     udp  --  *      virbr0  0.0.0.0/0            0.0.0.0/0            udp dpt:53
...
```


