# Set up the baremetal host and the support VM

The baremetal host is prepared and configured so that the SNO host and other libvirt KVM resources can be created, and Openshift can be installed inside the SNO host.

## Subscribe hosts with Red Hat
The EC2 metal host and the support VM run on RHEL 8 and are subscribed with RH using an activation key, for instructions on how to create the activation key check [Creating Red Hat Customer Portal Activation Keys](https://access.redhat.com/articles/1378093)

The activation key data is stored in the file **Ansible/group_vars/all/subscription.data**.  The variables defined in this file are used by the ansible playbook.
```
subscription_activationkey: 1-234381329
subscription_org_id: 19704701
```
It is recommended to encrypt this file with ansible-vault, for example to encrypt the file with the password stored in the file vault-id use a command like:
```
$ ansible-vault encrypt --vault-id vault-id subscription.data
```

## Add the common ssh key

Ansible needs access to the _private ssh key_ authorized to connect to the different hosts controlled by these playbooks.  It is actually not the playbooks but the shell environment which has access to the ssh private key.

To simplify things the same ssh key is authorized in all hosts being managed by the ansible playbooks in this respository.

To make the ssh private key available to the shell, add it to an ssh-agent by running the following commands:

```
$ ssh-agent bash
$ ssh-add ~/.ssh/upi-ssh
```
Verify that the key is available with the following commands, both public keys must match:
```
$ ssh-add -L
ssh-rsa AAAAB3NzaC1...jBI0mJf/kTbahNNmytsPOqotr8XR+VQ== jjerezro@jjerezro.remote.csb

$ cat ~/.ssh/upi-ssh.pub 
ssh-rsa AAAAB3NzaC1...jBI0mJf/kTbahNNmytsPOqotr8XR+VQ== jjerezro@jjerezro.remote.csb
```
## Running the playbook to configure the baremetal instance

The playbook **setup_metal.yaml** prepares the baremetal EC2 instance to create the KVM VMs and install the SNO host.

Check the variables in the following section to adapt some of the configuration properties, the variables **subscription_activationkey** and **subscription_org_id** need to be defined, then run the playbook with a command like:

```
$ ansible-playbook -i inventory -vvv setup_metal.yaml --vault-id vault-id
```

### Variables interface for setup_metal.yaml

The following list contains variables that can be defined by the user:

* **subscription_activationkey** and **subscription_org_id**.- Contain the activation key and organiaztion ID required to subscribe the RHEL host as explained in section [Subscribe hosts with Red Hat](#subscribe-hosts-with-red-hat).  These variables must be assigned by the user.

* **update_OS**.- Whether to update the Operating system and reboot the host (true) or not (false).  Rebooting the EC2 instance is time consuming and may take between 10 and 20 minutes.  This variable is defined in the file **Ansible/group_vars/all/general.var**. Default value: **false**

* **cluster_name**.- Cluster name, used as the first part of the whole DNS domain name used by the SNO host.  Defined in **Ansible/group_vars/all/general.var**.  Default value: **ocp4**

* **dns_zone**.- DNS domain name used by the cluster, the whole DNS domain will be \<cluster_name\>.\<dns_zone\>. Defined in **Ansible/group_vars/all/general.var**.  Default value: **tale.net**

* **ocp_version**.- Openshift version to be deployed.  Defined in **Ansible/group_vars/all/general.var**.  Default value: **4.9.5**

The following list contains variables that are automatically assigned:

* **baremetal_public_ip**.- Contains the public Internet facing IP address of the EC2 instance.  This variable is automatically assigned a value by terraform template **Terraform/main.tf** as an output variable

* **ssh_certificate**.- Filename containing the public ssh key for the certificate injected in the EC2 instance.  This variable is defined in **Terraform/output-vars.tf**

## Setting up the DNS and DHCP services

A separate ansible playbook file (support_setup.yaml) is used to install and set up the DHCP and DNS services in the support VM

This playbook has the following requirements:

* An [activation key](#subscribe-the-host-with-red-hat) is required to register the VMs with Red Hat.  
* An [ssh private key](#add-the-ec2-user-ssh-key) to connect to the VMs. This ssh key is the same used by the EC2 metal instance, the terraform template injects the same ssh key in all KVM VMs and EC2 instance.
* A [pull secret](https://console.redhat.com/openshift/install/metal/user-provisioned) for the Openshift installation.  Download the pull secret and copy it to **Ansible/pull-secret**.  

### Running the playbook for the support VM

The playbook is run with a command like the following, similar to the one used to set up the EC2 instance:

```
$ ansible-playbook -i inventory -vvv support_setup.yaml --vault-id vault-id 
```
