provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

module "postgres" {
  source  = "telia-oss/rds-cluster/aws"
  version = "0.1.1"

  name_prefix = "example"
  username    = "superuser"
  password    = "<postgres-password>"
  engine      = "aurora-postgresql"
  port        = "5439"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

module "concourse_atc" {
  source = "../../modules/atc"

  name_prefix          = "example"
  web_protocol         = "HTTP"
  web_port             = "80"
  authorized_cidr      = ["0.0.0.0/0"]
  concourse_keys       = "${path.root}/keys"
  vpc_id               = "${data.aws_vpc.main.id}"
  public_subnet_ids    = ["${data.aws_subnet_ids.main.ids}"]
  private_subnet_ids   = ["${data.aws_subnet_ids.main.ids}"]
  postgres_connection  = "${module.postgres.postgres_connection_string}"
  encryption_key       = ""
  instance_ami         = "<packer-ami>"
  github_client_id     = "<github-client>"
  github_client_secret = "<github-secret>"
  github_users         = ["itsdalmo"]
  github_teams         = ["telia-oss/some-team"]

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

module "concourse_worker" {
  source = "../../modules/worker"

  name_prefix        = "example"
  concourse_keys     = "${path.root}/keys"
  vpc_id             = "${data.aws_vpc.main.id}"
  private_subnet_ids = ["${data.aws_subnet_ids.main.ids}"]
  atc_sg             = "${module.concourse_atc.security_group_id}"
  tsa_host           = "${module.concourse_atc.tsa_host}"
  tsa_port           = "${module.concourse_atc.tsa_port}"
  instance_ami       = "<packer-ami>"

  tags {
    environment = "prod"
    terraform   = "True"
  }
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

# Allow workers to fetch ECR images
resource "aws_iam_role_policy" "main" {
  name   = "example-worker-ecr-policy"
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

output "endpoint" {
  description = "The Concourse web interface."
  value       = "${module.concourse_atc.endpoint}"
}
