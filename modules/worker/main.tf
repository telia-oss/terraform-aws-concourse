# -------------------------------------------------------------------------------
# Resources
# -------------------------------------------------------------------------------
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_security_group_rule" "atc_ingress_garbage_collection" {
  security_group_id        = module.worker.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7799
  to_port                  = 7799
  source_security_group_id = var.atc_sg
}

resource "aws_security_group_rule" "atc_ingress_baggageclaim" {
  security_group_id        = module.worker.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7788
  to_port                  = 7788
  source_security_group_id = var.atc_sg
}

resource "aws_security_group_rule" "atc_ingress_garden" {
  security_group_id        = module.worker.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 7777
  to_port                  = 7777
  source_security_group_id = var.atc_sg
}

module "worker" {
  source  = "telia-oss/asg/aws"
  version = "4.0.0"

  name_prefix          = "${var.name_prefix}-worker"
  user_data_base64     = data.template_cloudinit_config.worker.rendered
  vpc_id               = var.vpc_id
  subnet_ids           = var.private_subnet_ids
  min_size             = var.min_size
  max_size             = var.max_size
  instance_type        = var.instance_type
  instance_ami         = var.instance_ami
  instance_key         = var.instance_key
  instance_policy      = data.aws_iam_policy_document.worker.json
  instance_volume_size = var.instance_volume_size
  await_signal         = true
  pause_time           = "PT5M"
  health_check_type    = "EC2"
  tags                 = var.tags

}

locals {
  shared_cloud_init = templatefile("${path.module}/../cloud-init/shared.yml", {
    region               = data.aws_region.current.name
    cloudwatch_namespace = var.name_prefix
    log_group_name       = aws_cloudwatch_log_group.worker.name
    prometheus_enabled   = var.prometheus_enabled
  })

  worker_cloud_init = templatefile("${path.module}/../cloud-init/worker.yml", {
    region                    = data.aws_region.current.name
    stack_name                = "${var.name_prefix}-worker-asg"
    tsa_host                  = var.tsa_host
    tsa_port                  = var.tsa_port
    log_level                 = var.log_level
    worker_team               = var.worker_team
    worker_key                = file("${var.concourse_keys}/worker_key")
    pub_worker_key            = file("${var.concourse_keys}/worker_key.pub")
    pub_tsa_host_key          = file("${var.concourse_keys}/tsa_host_key.pub")
    lifecycle_topic           = aws_sns_topic.worker.arn
    lifecycled_log_group_name = aws_cloudwatch_log_group.worker_lifecycled.name
  })
}

data "template_cloudinit_config" "worker" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = local.shared_cloud_init
  }

  part {
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content      = local.worker_cloud_init
  }
}

resource "aws_cloudwatch_log_group" "worker" {
  name = "${var.name_prefix}-worker"
}

resource "aws_cloudwatch_log_group" "worker_lifecycled" {
  name = "${var.name_prefix}-worker-lifecycled"
}

data "aws_iam_policy_document" "worker" {
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
      aws_cloudwatch_log_group.worker.arn,
      aws_cloudwatch_log_group.worker_lifecycled.arn,
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      aws_sns_topic.worker.arn,
    ]

    actions = [
      "sns:Subscribe",
      "sns:Unsubscribe",
    ]
  }

  statement {
    effect = "Allow"

    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:lifecycled-*"]

    actions = [
      "sqs:*",
    ]
  }

  statement {
    effect = "Allow"

    resources = ["*"]

    actions = [
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:CompleteLifecycleAction",
    ]
  }
}

resource "aws_sns_topic" "worker" {
  name = "${var.name_prefix}-worker-lifecycle"
}

resource "aws_autoscaling_lifecycle_hook" "worker" {
  name                    = "${var.name_prefix}-worker-lifecycle"
  autoscaling_group_name  = module.worker.id
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  default_result          = "CONTINUE"
  heartbeat_timeout       = 300
  notification_target_arn = aws_sns_topic.worker.arn
  role_arn                = aws_iam_role.lifecycle.arn
}

resource "aws_iam_role" "lifecycle" {
  name               = "${var.name_prefix}-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.asg_assume.json
}

resource "aws_iam_role_policy" "lifecycle" {
  name   = "${var.name_prefix}-lifecycle-permissions"
  role   = aws_iam_role.lifecycle.id
  policy = data.aws_iam_policy_document.asg_permissions.json
}

data "aws_iam_policy_document" "asg_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "asg_permissions" {
  statement {
    effect = "Allow"

    resources = [
      aws_sns_topic.worker.arn,
    ]

    actions = [
      "sns:Publish",
    ]
  }
}

