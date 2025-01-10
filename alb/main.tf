provider "aws" {
  region = "us-east-1" 
}


variable "domain_name" {
  default = "example.com" 
}


data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"] 
  }
}


data "aws_subnets" "existing_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }
}


data "aws_subnet" "existing" {
  count = length(data.aws_subnets.existing_subnets.ids)
  id    = data.aws_subnets.existing_subnets.ids[count.index]
}


locals {
  existing_cidrs = [for subnet in data.aws_subnet.existing : subnet.cidr_block]
  new_cidr_1     = cidrsubnet(data.aws_vpc.main_vpc.cidr_block, 8, 100) # Example new CIDR block
  new_cidr_2     = cidrsubnet(data.aws_vpc.main_vpc.cidr_block, 8, 101) # Example new CIDR block
}


resource "aws_subnet" "alb_subnet_1" {
  vpc_id                  = data.aws_vpc.main_vpc.id
  cidr_block              = local.new_cidr_1
  availability_zone       = "us-east-1a"  # Replace with your preferred AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "albsubnet1"
  }
}

resource "aws_subnet" "alb_subnet_2" {
  vpc_id                  = data.aws_vpc.main_vpc.id
  cidr_block              = local.new_cidr_2
  availability_zone       = "us-east-1b"  # Replace with your preferred AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "albsubnet2"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "alb" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.alb_subnet_1.id, aws_subnet.alb_subnet_2.id]

  enable_deletion_protection = false
}


resource "aws_acm_certificate" "ssl_cert" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
}


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  zone_id = "Z2ABCDEFGHIJKLM" # Replace with your Route53 Hosted Zone ID
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}


resource "aws_lb_target_group" "wordpress" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main_vpc.id
}

resource "aws_lb_target_group" "microservice" {
  name     = "microservice-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main_vpc.id
}


resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ssl_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "ALB is live!"
      status_code  = "200"
    }
  }
}


resource "aws_route53_record" "wordpress" {
  zone_id = "Z2ABCDEFGHIJKLM" 
  name    = "wordpress.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "microservice" {
  zone_id = "Z2ABCDEFGHIJKLM" 
  name    = "microservice.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
