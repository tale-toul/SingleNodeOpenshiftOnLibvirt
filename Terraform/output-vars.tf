##OUTPUT
output "baremetal_public_ip" {  
 value       = var.spot_instance ? aws_eip.baremetal_eip_spot[0].public_ip : aws_eip.baremetal_eip[0].public_ip
 description = "The public IP address of EC2 metal instance"
}
output "bastion_private_ip" {
  value     = var.spot_instance ? aws_spot_instance_request.baremetal[0].private_ip : aws_instance.baremetal[0].private_ip
  description = "The private IP address of the EC2 metal instance"
}
output "region_name" {
 value = var.region_name
 description = "AWS region where the cluster and its components will be deployed"
}
output "vpc_cidr" {
  value = var.vpc_cidr
  description = "Network segment for the VPC"
}
output "public_subnet_cidr_block" {
  value = aws_subnet.subnet_pub.cidr_block
  description = "Network segments for the public subnets"
}
output "ssh_certificate" {
  value = var.ssh-keyfile
  description = "Public key for the certificate injected in the EC2 instance"
}
