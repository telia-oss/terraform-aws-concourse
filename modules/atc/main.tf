# -------------------------------------------------------------------------------
# Resources
# -------------------------------------------------------------------------------
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "concourse" {
  id = var.vpc_id
}

resource "aws_security_group_rule" "lb_ingress_atc" {
  security_group_id        = module.atc.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.atc_port
  to_port                  = var.atc_port
  source_security_group_id = module.external_lb.security_group_id
}

resource "aws_security_group_rule" "workers_ingress_atc" {
  security_group_id = module.atc.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.atc_port
  to_port           = var.atc_port
  cidr_blocks       = [data.aws_vpc.concourse.cidr_block]
}

resource "aws_security_group_rule" "workers_ingress_tsa" {
  security_group_id = module.atc.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.tsa_port
  to_port           = var.tsa_port
  cidr_blocks       = [data.aws_vpc.concourse.cidr_block]
}

resource "aws_security_group_rule" "tsa_ingress_peers" {
  security_group_id = module.atc.security_group_id
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  self              = true
}

resource "aws_autoscaling_attachment" "external_lb" {
  autoscaling_group_name = module.atc.id
  alb_target_group_arn   = aws_lb_target_group.external.arn
}

resource "aws_autoscaling_attachment" "internal_lb" {
  autoscaling_group_name = module.atc.id
  alb_target_group_arn   = aws_lb_target_group.internal.arn
}

module "atc" {
  source  = "telia-oss/asg/aws"
  version = "3.2.0"

  name_prefix          = "${var.name_prefix}-atc"
  user_data_base64     = data.template_cloudinit_config.atc.rendered
  vpc_id               = var.vpc_id
  subnet_ids           = var.private_subnet_ids
  min_size             = var.min_size
  max_size             = var.max_size
  instance_type        = var.instance_type
  instance_ami         = var.instance_ami
  instance_key         = var.instance_key
  instance_policy      = data.aws_iam_policy_document.atc.json
  instance_volume_size = 8
  await_signal         = true
  pause_time           = "PT5M"
  health_check_type    = "ELB"
  tags                 = var.tags
}

locals {
  shared_cloud_init = templatefile("${path.module}/../cloud-init/shared.yml", {
    region               = data.aws_region.current.name
    cloudwatch_namespace = var.name_prefix
    log_group_name       = aws_cloudwatch_log_group.atc.name
    prometheus_enabled   = var.prometheus_enabled
  })

  atc_cloud_init = templatefile("${path.module}/../cloud-init/atc.yml", {
    region                 = data.aws_region.current.name
    stack_name             = "${var.name_prefix}-atc-asg"
    target_group           = aws_lb_target_group.internal.arn
    atc_port               = var.atc_port
    tsa_port               = var.tsa_port
    local_user             = var.local_user
    local_admin_user       = var.local_admin_user
    github_client_id       = var.github_client_id
    github_client_secret   = var.github_client_secret
    github_users           = var.github_users
    github_teams           = var.github_teams
    prometheus_enabled     = var.prometheus_enabled
    prometheus_bind_port   = var.prometheus_port
    concourse_web_host     = "${lower(var.web_protocol)}://${var.domain != "" ? var.domain : module.external_lb.dns_name}:${var.web_port}"
    postgres_host          = var.postgres_host
    postgres_port          = var.postgres_port
    postgres_username      = var.postgres_username
    postgres_password      = var.postgres_password
    postgres_database      = var.postgres_database
    log_level              = var.log_level
    tsa_host_key           = file("${var.concourse_keys}/tsa_host_key")
    session_signing_key    = file("${var.concourse_keys}/session_signing_key")
    authorized_worker_keys = file("${var.concourse_keys}/authorized_worker_keys")
    encryption_key         = var.encryption_key
    old_encryption_key     = var.old_encryption_key
  })
}

data "template_cloudinit_config" "atc" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = local.shared_cloud_init
  }

  part {
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content      = local.atc_cloud_init
  }
}

resource "aws_cloudwatch_log_group" "atc" {
  name = "${var.name_prefix}-atc"
}

data "aws_iam_policy_document" "atc" {
  statement {
    effect = "Allow"

    resources = ["*"]

    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "ec2:DescribeTags",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.atc.arn,
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]
  }

  # Used for cfn-signal
  statement {
    effect = "Allow"

    resources = ["*"]

    actions = [
      "elasticloadbalancing:DescribeTargetHealth",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:/concourse/*",
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:/concourse-deployment/*",
    ]
  }
}

resource "aws_security_group_rule" "ingress" {
  security_group_id = module.external_lb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.web_port
  to_port           = var.web_port
  cidr_blocks       = var.authorized_cidr
}

resource "aws_route53_record" "main" {
  count   = var.domain == "" ? 0 : 1
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = module.external_lb.dns_name
    zone_id                = module.external_lb.zone_id
    evaluate_target_health = false
  }
}

module "external_lb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "3.0.0"

  name_prefix = "${var.name_prefix}"
  vpc_id      = var.vpc_id
  subnet_ids  = var.public_subnet_ids
  type        = "application"
  internal    = false
  tags        = var.tags
}

resource "aws_lb_listener" "external" {
  load_balancer_arn = module.external_lb.arn
  port              = var.web_port
  protocol          = upper(var.web_protocol)
  certificate_arn   = var.web_certificate_arn
  ssl_policy        = var.web_certificate_arn == "" ? "" : "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_lb_target_group.external.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "external" {
  vpc_id   = var.vpc_id
  port     = var.atc_port
  protocol = "HTTP"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = 200
  }

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-target-${var.atc_port}"
    },
  )
}

module "internal_lb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "3.0.0"

  name_prefix = "${var.name_prefix}"
  vpc_id      = var.vpc_id
  subnet_ids  = var.private_subnet_ids
  type        = "network"
  internal    = true
  tags        = var.tags
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = module.internal_lb.arn
  port              = var.tsa_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.internal.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "internal" {
  vpc_id   = var.vpc_id
  port     = var.tsa_port
  protocol = "TCP"

  # Since the TSA attempts to handshake TCP health checks which generates INFO log entries 
  # with "error: EOF" we are instead health checking the ATC which is part of the same binary.
  health_check {
    protocol            = "TCP"
    port                = var.atc_port
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-target-${var.tsa_port}"
    },
  )
}

