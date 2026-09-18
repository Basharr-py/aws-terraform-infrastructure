provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
    id = "vpc-04eaf397e03414437"
}

data "aws_security_group" "default" {
    id = "sg-039513002ae5e724b"
}

resource "aws_eip" "example" {
  domain = "vpc"
  instance = aws_instance.example.id

  tags = {
    Name = "For-Ansible"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"
  key_name = "LinOps_pkey"
  

  vpc_security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "For-Ansible"
  }
}

output "instance_id" {
  description = "The value of the EC2 public eip"
  value = aws_eip.example.public_ip
}
