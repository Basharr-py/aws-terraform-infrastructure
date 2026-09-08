# ============================================================
# IAM ROLE FOR AWS SYSTEMS MANAGER
# ============================================================

resource "aws_iam_role" "ec2_ssm" {
  name = "ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"

        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ec2-ssm-role"
  }
}


# ============================================================
# SSM POLICY ATTACHMENT
# ============================================================

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ============================================================
# EC2 INSTANCE PROFILE
# ============================================================

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2_ssm_instance_profile"
  role = aws_iam_role.ec2_ssm.name
}

