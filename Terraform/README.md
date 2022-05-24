# AWS infrastructure 

The terraform template in this directory creates an EC2 metal instance in AWS to be used as a base to deploy the libvirt/KVM resources required to deploy the SNO host.

## Module initialization

Before running terraform for the first time, the modules used by the template must be downloaded and initialized, this requires an active Internet connection.

Run the following command in the directory where the terraform templates reside. The command can be safely run many times, it will not trampled previous executions:
``` 
$ cd libvirt
$ terraform init

Initializing the backend...
``` 

Terraform needs access to credentials for an AWS user with privileges to create resources, these can be defined in a file containing the access key ID and the access key secret with the following format. Put this file in ~/.aws/credentials:
``` 
[default]
aws_access_key_id=xxxx
aws_secret_access_key=xxxx
``` 
## Configuration variables

Some variables are defined in the **Terraform/input-vars.tf** that can be used to modify some configuration parameters. The most relevan of these are:

* **region_name**.- AWS Region where the EC2 instance and other resources are created. Keep in mind that the same infrastructure may incur different costs depending on the region.

     Default value: us-east-1

* **ssh-keyfile**.- Name of the file with the public part of the SSH key to transfer to the EC2 instance. This public ssh keyfile will be injected into the EC2 instance so the ec2-user can later connect via ssh using the corresponding private part.

     Default value: ssh.pub

* **instance_type**.- AWS instance type for the hypervisor machine. This must be a metal instance.

     Default value: c5n.metal

* **spot_instance**.- Determines if the AWS EC2 metal instance created is an spot instance or not.  Using a spot instance reduces cost but is not guaranteed to be available at creation time or for long periods after it has been allocated.  Another limitation of these instances is that they cannot be rebooted.

     Default = false

* **ebs_disk_size**.- Size, in Megabytes, of the additional EBS disk attached to the metal instance.  This disk is used to store the libvirt/KVM Virtual Machine disks.

     Default value: 1000

## Applying the terraform template

Copy a public ssh key file to the Terraform directory, the default expected name for the file is **ssh.pub**, if a different name is used, the variable **ssh-keyfile** must be updated accordingly.

Apply the template with a command like:

``` 
$ terraform apply -var region_name=us-east-1 -var ssh-keyfile=baremetal-ssh.pub -var instance_type=c5.metal -var spot_instance=true
``` 
Or add the variable assignments to a file and call that file in the command line. For example, the following content is added to the file sno_aws.vars
``` 
region_name = "us-east-1"
ssh-keyfile = "baremetal-ssh.pub"
instance_type = "c5.metal"
``` 
And call it in with the option **-var-file**, for example:

``` 
$ terraform apply -var-file sno_aws.vars
``` 

## Connecting to the EC2 instance
It may take a few minutes after creation for the EC2 instance to be ready and accept connections.

Ssh is used to connect to the EC2 instance created by terraform.

The elements required are:

* The private part of the ssh key injected earlier
* The user to connect is **ec2-user**
* The public IP of the EC2 instance, can be obtained in the AWS web console, or with the command:
``` 
$ terraform output baremetal_public_ip
"4.83.45.254"
``` 
The command to connect looks something like:

``` 
$ ssh -i baremetal-ssh.priv ec2-user@4.83.45.254
``` 

## Destroying the resources
When the resources are not required anymore they can be easily removed using terraform, just run a command similar to the one used to create them, but using the **destroy** subcommand.

Destroying the AWS resources will also remove any Openshift or libvirt resources created in the EC2 instance.

``` 
$ terraform destroy -var="region_name=us-east-1" -var="ssh-keyfile=baremetal-ssh.pub" -var="instance_type=c5.metal"
``` 
or 
``` 
$ terraform destroy -var-file sno_aws.vars
``` 
