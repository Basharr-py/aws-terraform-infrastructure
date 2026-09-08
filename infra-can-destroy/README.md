# Terraform AWS Infrastructure

Infrastructure-as-Code project for provisioning a secure, highly structured AWS environment using **Terraform**.

This project provisions the AWS infrastructure required to host a containerized web application on private EC2 instances behind an **Application Load Balancer**, with **Route 53**, **ACM**, **NAT Gateway**, and **AWS Systems Manager** for secure instance management.

The project is designed as a practical DevOps learning project, focusing on AWS networking, Infrastructure as Code, security, DNS, HTTPS, load balancing, and private-server architecture.

---

## Architecture

```text
                         Internet
                            │
                            ▼
                     Route 53 DNS
                            │
                            ▼
                ┌─────────────────────┐
                │ Application Load    │
                │ Balancer            │
                │ HTTPS :443          │
                └──────────┬──────────┘
                           │
                    Target Group
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       Private EC2 #1            Private EC2 #2
       192.168.200.0/24          192.168.201.0/24
              │                         │
              └────────────┬────────────┘
                           │
                         Nginx
                           │
                     Application
                           
                    ─────────────────
                         Outbound
                    ─────────────────
                           │
                           ▼
                     NAT Gateway
                           │
                           ▼
                    Internet Gateway
                           │
                           ▼
                        Internet


AWS Systems Manager (SSM)
             │
             ├──────────────► EC2 #1
             │
             └──────────────► EC2 #2
```

---

## AWS Resources

Terraform provisions and manages the following infrastructure:

### Networking

* VPC
* Internet Gateway
* Two public subnets across separate Availability Zones
* Two private subnets across separate Availability Zones
* Public route table
* Private route tables
* NAT Gateway
* Elastic IP for NAT Gateway

### Compute

* Two EC2 instances
* EC2 instances deployed in private subnets
* No public IP addresses
* IAM instance profile for Systems Manager

### Load Balancing

* Application Load Balancer
* ALB security group
* Target group
* EC2 target attachments
* HTTP listener
* HTTPS listener
* Health checks

### Security

* Separate security groups for the ALB and EC2 instances
* ALB allows HTTP/HTTPS from the internet
* EC2 allows HTTP only from the ALB security group
* No inbound SSH access required
* AWS Systems Manager used for administrative access

### DNS & TLS

* Route 53 hosted zone
* Route 53 A Alias record pointing to the ALB
* AWS Certificate Manager certificate
* DNS-based ACM certificate validation

---

## Network Design

The VPC uses the following CIDR:

```text
VPC: 192.168.0.0/16
```

### Public Subnets

```text
Public Subnet 1
192.168.100.0/24

Public Subnet 2
192.168.101.0/24
```

The public subnets have a default route to the Internet Gateway.

They host internet-facing resources such as:

* Application Load Balancer
* NAT Gateway

### Private Subnets

```text
Private Subnet 1
192.168.200.0/24

Private Subnet 2
192.168.201.0/24
```

The EC2 instances are deployed here.

They do not have public IP addresses and cannot be directly accessed from the internet.

Outbound internet traffic is routed through the NAT Gateway.

```text
Private EC2
     │
     ▼
Private Route Table
     │
     ▼
NAT Gateway
     │
     ▼
Internet Gateway
     │
     ▼
Internet
```

The project currently uses **one NAT Gateway** to reduce cost. A production high-availability architecture would typically use a NAT Gateway per Availability Zone.

---

## Security Model

The infrastructure follows a layered security model.

### Internet → ALB

The ALB accepts:

```text
HTTP  :80
HTTPS :443
```

from the internet.

HTTP traffic is redirected to HTTPS.

### ALB → EC2

The EC2 security group allows:

```text
HTTP :80
Source: ALB Security Group
```

The EC2 instances do not expose port 80 directly to the internet.

### SSH

SSH is intentionally not exposed.

Instead, EC2 instances are managed using **AWS Systems Manager Session Manager**.

This eliminates the need for:

* Public IP addresses
* Bastion hosts
* Internet-accessible SSH
* Opening port 22

---

## Systems Manager

The EC2 instances receive the IAM policy:

```text
AmazonSSMManagedInstanceCore
```

This allows Systems Manager to manage the instances without requiring inbound SSH access.

A session can be started using:

```bash
aws ssm start-session --target <instance-id>
```

This provides administrative access to the private EC2 instance through AWS Systems Manager.

---

## Load Balancing

The Application Load Balancer distributes incoming requests between the two EC2 instances.

```text
                    ALB
                     │
              Target Group
                ┌────┴────┐
                ▼         ▼
             EC2 #1    EC2 #2
```

The ALB performs health checks against the EC2 targets.

If an instance becomes unhealthy, the ALB stops routing normal traffic to that instance.

The target group currently forwards traffic to:

```text
HTTP :80
```

The EC2 instances run Nginx, which can then route requests to the application containers running on the server.

---

## HTTPS

TLS termination occurs at the Application Load Balancer.

The flow is:

```text
Client
  │
  │ HTTPS :443
  ▼
ALB
  │
  │ TLS termination
  ▼
HTTP :80
  │
  ▼
EC2 / Nginx
```

AWS Certificate Manager provides the certificate for:

```text
basharr.indevs.in
```

The certificate uses DNS validation through Route 53.

This means HTTPS does not need to be configured separately on every EC2 instance.

---

## DNS

Route 53 manages the DNS records for the application domain.

The domain resolves to the Application Load Balancer rather than directly to an EC2 instance.

```text
basharr.indevs.in
        │
        ▼
    Route 53
        │
        ▼
       ALB
        │
        ▼
      EC2
```

The infrastructure Terraform configuration accesses the Route 53 hosted zone using a data source rather than creating another hosted zone.

```hcl
data "aws_route53_zone" "main" {
  name = "basharr.indevs.in"
}
```

This allows the DNS infrastructure and application infrastructure to remain separated.

---

## Terraform Structure

The project is separated into two Terraform configurations:

```text
terraform-dir/
│
├── route_53(provider specified inside)
│   
│   
│
└── infra-can-destroy/
    ├── provider.tf
    ├── vpc.tf
    ├── security-groups.tf
    ├── iam.tf
    ├── ec2.tf
    ├── main.tf
    ├── acm.tf
    └── outputs.tf
```

Keeping them as separate Terraform configurations also means:

```bash
cd infra-can-destroy
terraform destroy
```

does not destroy the Route 53 hosted zone.

---

## Terraform Workflow

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Create an execution plan:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

Destroy the infrastructure when it is no longer needed:

```bash
terraform destroy
```

---

## AWS Authentication

Terraform uses the AWS CLI credential configuration rather than hard-coded credentials.

Configure AWS CLI:

```bash
aws configure
```

Verify the authenticated AWS identity:

```bash
aws sts get-caller-identity
```

The AWS provider only needs the region:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Credentials are resolved through the AWS credential chain.

---

## Deployment Flow

The intended infrastructure deployment process is:

```text
1. Create Route 53 hosted zone
             │
             ▼
2. Configure domain nameservers
             │
             ▼
3. Create VPC and networking
             │
             ▼
4. Create security groups
             │
             ▼
5. Create IAM / SSM configuration
             │
             ▼
6. Launch private EC2 instances
             │
             ▼
7. Create Application Load Balancer
             │
             ▼
8. Register EC2 instances with target group
             │
             ▼
9. Create ACM certificate
             │
             ▼
10. Validate certificate through Route 53
             │
             ▼
11. Configure HTTPS listener
             │
             ▼
12. Point Route 53 → ALB
```

---

## Why This Architecture?

The project intentionally avoids exposing application servers directly to the internet.

Instead of:

```text
Internet → EC2
```

the architecture uses:

```text
Internet
    │
    ▼
  ALB
    │
    ▼
Private EC2
```

This provides a clear separation between the public entry point and the application servers.

The architecture also demonstrates several important DevOps and cloud concepts:

* Infrastructure as Code
* AWS networking
* Public vs private subnets
* Route tables
* NAT Gateway
* Security groups
* IAM roles
* Systems Manager
* Application Load Balancing
* Health checks
* DNS
* TLS/HTTPS
* Terraform state separation
* Terraform data sources

---

## Cost Considerations

The infrastructure is designed primarily as a learning environment.

Some AWS resources incur ongoing charges, particularly:

* NAT Gateway
* Application Load Balancer
* Elastic IP/NAT resources depending on usage
* EC2 instances
* Route 53 hosted zone and DNS queries

The project intentionally uses a single NAT Gateway to reduce costs.

For a production environment, the NAT architecture could be improved by deploying one NAT Gateway per Availability Zone for better fault tolerance.


## What This Project Demonstrates

This project demonstrates the ability to design and provision AWS infrastructure using Terraform rather than manually creating resources through the AWS Console.

The resulting architecture provides:

**Public ALB → Private EC2 → Application**

while using:

**Route 53 → DNS**

**ACM → TLS**

**NAT Gateway → Private outbound connectivity**

**SSM → Secure server administration**

**Terraform → Infrastructure automation**

The goal is not simply to provision AWS resources, but to demonstrate an understanding of **how those resources work together to form a secure and maintainable cloud architecture.**
