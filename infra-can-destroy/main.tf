data "aws_route53_zone" "main" {
  name = "basharr.indevs.in"
}

# ============================================================
# ROUTE 53 → ALB
# ============================================================

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id

  name = "basharr.indevs.in"

  type = "A"

  alias {
    name                   = aws_lb.terraform_lb.dns_name
    zone_id                = aws_lb.terraform_lb.zone_id
    evaluate_target_health = true
  }
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

resource "aws_lb" "terraform_lb" {
  name               = "terraform-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.load_balancer.id
  ]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "terraform-lb"
  }
}


# ============================================================
# TARGET GROUP
# ============================================================

resource "aws_lb_target_group" "terraform_tg" {
  name     = "terraform-tg"
  port     = 80
  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
    enabled             = true
  }

  tags = {
    Name = "terraform-tg"
  }
}


# ============================================================
# TARGET GROUP ATTACHMENT - EC2 1
# ============================================================

resource "aws_lb_target_group_attachment" "tg_attachment_1" {
  target_group_arn = aws_lb_target_group.terraform_tg.arn

  target_id = aws_instance.terraform_ec2_1.id

  port = 80
}


# ============================================================
# TARGET GROUP ATTACHMENT - EC2 2
# ============================================================

resource "aws_lb_target_group_attachment" "tg_attachment_2" {
  target_group_arn = aws_lb_target_group.terraform_tg.arn

  target_id = aws_instance.terraform_ec2_2.id

  port = 80
}


# ============================================================
# HTTPS LISTENER
# ============================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.terraform_lb.arn

  port     = 443
  protocol = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.terraform_cert.certificate_arn

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.terraform_tg.arn
  }
}


# ============================================================
# HTTP → HTTPS REDIRECT
# ============================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.terraform_lb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


