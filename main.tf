# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_kms_secrets" "decrypted" {
  secret {
    name    = "postgres_password"
    payload = "${var.postgres_password}"
  }

  secret {
    name    = "github_client_secret"
    payload = "${var.github_client_secret}"
  }

  secret {
    name    = "encryption_key"
    payload = "${var.encryption_key}"
  }
}

module "vpc" {
  source  = "telia-oss/vpc/aws"
  version = "0.1.0"

  name_prefix          = "${var.name_prefix}"
  cidr_block           = "10.9.0.0/16"
  private_subnet_count = "${var.private_subnet_count}"
  enable_dns_hostnames = "true"
  tags                 = "${var.tags}"
}

module "postgres" {
  source  = "telia-oss/rds-cluster/aws"
  version = "0.3.0"

  name_prefix         = "${var.name_prefix}"
  username            = "${var.postgres_username}"
  password            = "${data.aws_kms_secrets.decrypted.plaintext["postgres_password"]}"
  port                = "5439"
  vpc_id              = "${module.vpc.vpc_id}"
  subnet_ids          = ["${module.vpc.private_subnet_ids}"]
  snapshot_identifier = "${var.postgres_snapshot_identifier}"
  skip_final_snapshot = "false"
  tags                = "${var.tags}"
}

module "sts_lambda" {
  source = "github.com/telia-oss/concourse-sts-lambda//terraform/modules/lambda?ref=v0.4.1"

  name_prefix            = "${var.name_prefix}-sts-credentials"
  role_prefix            = "machine-user"
  secrets_manager_prefix = "concourse"
  tags                   = "${var.tags}"
}

module "github_lambda" {
  source = "github.com/telia-oss/concourse-github-lambda//terraform/modules/lambda?ref=v0.6.2"

  name_prefix                  = "${var.name_prefix}-github-credentials"
  github_prefix                = "${var.github_lambda_deploy_key_prefix}"
  secrets_manager_prefix       = "concourse"
  token_service_integration_id = "sm:///concourse-github-lambda/token-service/integration-id"
  token_service_private_key    = "sm:///concourse-github-lambda/token-service/private-key"
  key_service_integration_id   = "sm:///concourse-github-lambda/key-service/integration-id"
  key_service_private_key      = "sm:///concourse-github-lambda/key-service/private-key"
  tags                         = "${var.tags}"
}

resource "aws_iam_role_policy" "github_lambda_policy" {
  name   = "${var.name_prefix}-github-credentials-secrets-policy"
  role   = "${module.github_lambda.role_name}"
  policy = "${data.aws_iam_policy_document.secrets.json}"
}

data "aws_iam_policy_document" "secrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:/concourse-github-lambda/*/*",
    ]
  }
}

module "concourse_atc" {
  source = "modules/atc"

  name_prefix          = "${var.name_prefix}"
  domain               = "${var.domain}"
  zone_id              = "${var.zone_id}"
  web_certificate_arn  = "${var.web_certificate_arn}"
  web_protocol         = "https"
  web_port             = "443"
  authorized_cidr      = ["${var.authorized_cidr}"]
  concourse_keys       = "${path.root}/keys"
  vpc_id               = "${module.vpc.vpc_id}"
  public_subnet_ids    = "${module.vpc.public_subnet_ids}"
  private_subnet_ids   = "${module.vpc.private_subnet_ids}"
  postgres_host        = "${module.postgres.endpoint}"
  postgres_port        = "${module.postgres.port}"
  postgres_username    = "${module.postgres.username}"
  postgres_password    = "${data.aws_kms_secrets.decrypted.plaintext["postgres_password"]}"
  postgres_database    = "${module.postgres.database_name}"
  encryption_key       = "${data.aws_kms_secrets.decrypted.plaintext["encryption_key"]}"
  min_size             = "${var.web_count}"
  max_size             = "${var.web_count_max}"
  instance_type        = "t3.small"
  instance_ami         = "${var.ami_id}"
  instance_key         = ""
  log_level            = "error"
  github_client_id     = "${var.github_client_id}"
  github_client_secret = "${data.aws_kms_secrets.decrypted.plaintext["github_client_secret"]}"
  prometheus_enabled   = "${var.prometheus_sg != "" ? "true" : "false"}"

  # Github teams and users that are made into members of the 'main' team on Concourse
  github_teams = ["${var.github_teams}"]
  github_users = ["${var.github_users}"]

  tags = "${var.tags}"
}

module "concourse_worker" {
  source = "modules/worker"

  name_prefix          = "${var.name_prefix}"
  concourse_keys       = "${path.root}/keys"
  vpc_id               = "${module.vpc.vpc_id}"
  private_subnet_ids   = "${module.vpc.private_subnet_ids}"
  atc_sg               = "${module.concourse_atc.security_group_id}"
  tsa_host             = "${module.concourse_atc.tsa_host}"
  tsa_port             = "${module.concourse_atc.tsa_port}"
  min_size             = "${var.worker_count}"
  max_size             = "${var.worker_count_max}"
  instance_type        = "t3.large"
  instance_ami         = "${var.ami_id}"
  instance_key         = ""
  instance_volume_size = "150"
  log_level            = "info"
  prometheus_enabled   = "${var.prometheus_sg != "" ? "true" : "false"}"

  tags = "${var.tags}"
}

# ATC ingress postgres
resource "aws_security_group_rule" "atc_ingress_postgres" {
  security_group_id        = "${module.postgres.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "${module.postgres.port}"
  to_port                  = "${module.postgres.port}"
  source_security_group_id = "${module.concourse_atc.security_group_id}"
}

# Prometheus ingress ATC
resource "aws_security_group_rule" "prometheus_ingress_atc" {
  count                    = "${var.prometheus_sg != "" ? 1 : 0}"
  security_group_id        = "${module.concourse_atc.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "9391"
  to_port                  = "9391"
  source_security_group_id = "${var.prometheus_sg}"
}

# Prometheus ingress node-exporter ATC
resource "aws_security_group_rule" "prometheus_ingress_node_exporter_atc" {
  count                    = "${var.prometheus_sg != "" ? 1 : 0}"
  security_group_id        = "${module.concourse_atc.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "9100"
  to_port                  = "9100"
  source_security_group_id = "${var.prometheus_sg}"
}

# Prometheus ingress node-exporter worker
resource "aws_security_group_rule" "prometheus_ingress_node_exporter_worker" {
  count                    = "${var.prometheus_sg != "" ? 1 : 0}"
  security_group_id        = "${module.concourse_worker.security_group_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "9100"
  to_port                  = "9100"
  source_security_group_id = "${var.prometheus_sg}"
}

# Add privileges for SSM agent on both clusters
module "atc_ssm_agent" {
  source  = "telia-oss/ssm-agent-policy/aws"
  version = "0.1.0"

  name_prefix = "${var.name_prefix}"
  role        = "${module.concourse_atc.role_name}"
}

module "worker_ssm_agent" {
  source  = "telia-oss/ssm-agent-policy/aws"
  version = "0.1.0"

  name_prefix = "${var.name_prefix}"
  role        = "${module.concourse_worker.role_name}"
}

# Allow workers to fetch ECR images
resource "aws_iam_role_policy" "worker" {
  name   = "${var.name_prefix}-worker-ecr-policy"
  role   = "${module.concourse_worker.role_name}"
  policy = "${data.aws_iam_policy_document.worker.json}"
}

data "aws_iam_policy_document" "worker" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
  }
}
