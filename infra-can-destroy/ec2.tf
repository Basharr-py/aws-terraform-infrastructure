# ============================================================
# EC2 INSTANCE 1
# ============================================================

resource "aws_instance" "terraform_ec2_1" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"

  # IMPORTANT:
  # EC2 is now in the PRIVATE subnet
  subnet_id = aws_subnet.private_1.id

  vpc_security_group_ids = [
    aws_security_group.ec2_instance.id
  ]

  # Optional if the key pair already exists in AWS
  key_name = "LinOps_pkey"

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  # No public IP
  associate_public_ip_address = false

  tags = {
    Name = "terraform-EC2-1"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ec2_ssm_attach,
    aws_nat_gateway.nat
  ]
}


# ============================================================
# EC2 INSTANCE 2
# ============================================================

resource "aws_instance" "terraform_ec2_2" {
  ami           = "ami-0b6d9d3d33ba97d99"
  instance_type = "t3.micro"

  # IMPORTANT:
  # EC2 is now in the PRIVATE subnet
  subnet_id = aws_subnet.private_2.id

  vpc_security_group_ids = [
    aws_security_group.ec2_instance.id
  ]

  # Optional if the key pair already exists in AWS
  key_name = "LinOps_pkey"

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name

  # No public IP
  associate_public_ip_address = false

  tags = {
    Name = "terraform-EC2-2"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ec2_ssm_attach,
    aws_nat_gateway.nat
  ]
}
