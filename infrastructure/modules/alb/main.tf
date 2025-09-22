data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.alb_name}-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name               = var.domain_name
  zone_id                   = var.route53_zone_id
  subject_alternative_names = var.subject_alternative_names

  validation_method = "DNS"
  
  wait_for_validation = var.wait_for_ssl_validation

  tags = var.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = var.alb_name

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.subnet_ids
  security_groups = [module.alb_sg.security_group_id]

  target_groups = {
    ex-instance = {
      name               = "${var.alb_name}-tg"
      backend_protocol   = "HTTP"
      backend_port       = var.target_port
      target_type        = "ip"
      create_attachment  = false

      health_check = {
        enabled             = true
        healthy_threshold   = var.health_check_healthy_threshold
        interval            = var.health_check_interval
        matcher             = "200"
        path                = var.health_check_path
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = var.health_check_timeout
        unhealthy_threshold = var.health_check_unhealthy_threshold
      }
    }
  }

  listeners = {
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn
      forward = {
        target_group_key = "ex-instance"
      }
    }
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = var.tags
}