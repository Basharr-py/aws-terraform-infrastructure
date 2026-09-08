
# ============================================================
# ACM CERTIFICATE
# ============================================================

resource "aws_acm_certificate" "terraform_cert" {
  domain_name       = "basharr.indevs.in"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "terraform-cert"
  }
}


# ============================================================
# ACM DNS VALIDATION RECORD
# ============================================================

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.terraform_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true

  name = each.value.name

  records = [
    each.value.record
  ]

  ttl = 60

  type = each.value.type

  zone_id = data.aws_route53_zone.main.zone_id
}


# ============================================================
# ACM CERTIFICATE VALIDATION
# ============================================================

resource "aws_acm_certificate_validation" "terraform_cert" {
  certificate_arn = aws_acm_certificate.terraform_cert.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation :
    record.fqdn
  ]
}