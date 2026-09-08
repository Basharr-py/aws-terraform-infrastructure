# ============================================================
# AWS PROVIDER
# ============================================================

provider "aws" {
  region = "us-east-1"
}


# ============================================================
# AVAILABILITY ZONES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# ROUTE 53 HOSTED ZONE
# ============================================================

resource "aws_route53_zone" "main" {
  name = "basharr.indevs.in"

  lifecycle {
    prevent_destroy = true
  }
}

output "aws_name_servers" {
  value = aws_route53_zone.main.name_servers

  description = "Route 53 name servers to configure at the domain registrar"
}




