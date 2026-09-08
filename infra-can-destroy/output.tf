# ============================================================
# OUTPUTS
# ============================================================

output "alb_dns_name" {
  value = aws_lb.terraform_lb.dns_name

  description = "The DNS name of the Application Load Balancer"
}


output "domain_name" {
  value = "basharr.indevs.in"

  description = "The application domain name"
}


output "vpc_id" {
  value = aws_vpc.main.id

  description = "The ID of the VPC"
}


output "private_ec2_instance_1_id" {
  value = aws_instance.terraform_ec2_1.id

  description = "The ID of EC2 instance 1"
}


output "private_ec2_instance_2_id" {
  value = aws_instance.terraform_ec2_2.id

  description = "The ID of EC2 instance 2"
}


output "private_ec2_instance_1_ip" {
  value = aws_instance.terraform_ec2_1.private_ip

  description = "The private IP address of EC2 instance 1"
}


output "private_ec2_instance_2_ip" {
  value = aws_instance.terraform_ec2_2.private_ip

  description = "The private IP address of EC2 instance 2"
}


output "nat_gateway_public_ip" {
  value = aws_eip.terraform_eip.public_ip

  description = "The public IP address of the NAT Gateway"
}



output "ssm_connect_command_1" {
  value = "aws ssm start-session --target ${aws_instance.terraform_ec2_1.id}"

  description = "Command to connect to EC2 instance 1 using SSM"
}


output "ssm_connect_command_2" {
  value = "aws ssm start-session --target ${aws_instance.terraform_ec2_2.id}"

  description = "Command to connect to EC2 instance 2 using SSM"
}

output "quickie" {
  value = aws_lb_target_group.terraform_tg.arn

  description = "The ARN of the ALB target group"
}