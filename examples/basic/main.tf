terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.17"
  region  = "${var.region}"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

module "postgres" {
  source  = "telia-oss/rds-cluster/aws"
  version = "3.0.0"

  name_prefix = var.name_prefix
  username    = "superuser"
  password    = var.postgres_password
  engine      = "aurora-postgresql"
  port        = 5439
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

module "concourse_atc" {
  source = "../../modules/atc"

  name_prefix          = var.name_prefix
  web_protocol         = "HTTP"
  web_port             = "80"
  authorized_cidr      = ["0.0.0.0/0"]
  concourse_keys       = "${path.root}/keys"
  vpc_id               = data.aws_vpc.main.id
  public_subnet_ids    = data.aws_subnet_ids.main.ids
  private_subnet_ids   = data.aws_subnet_ids.main.ids
  postgres_host        = module.postgres.endpoint
  postgres_port        = module.postgres.port
  postgres_username    = module.postgres.username
  postgres_password    = var.postgres_password
  postgres_database    = module.postgres.database_name
  encryption_key       = ""
  instance_ami         = var.packer_ami
  github_client_id     = "sm:///concourse-deployment/github-oauth-client-id"
  github_client_secret = "sm:///concourse-deployment/github-oauth-client-secret"
  github_users         = ["itsdalmo"]
  github_teams         = ["telia-oss:concourse-owners"]
  local_user           = "sm:///concourse-deployment/admin-user"
  local_admin_user     = "admin"

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

module "concourse_worker" {
  source = "../../modules/worker"

  name_prefix        = var.name_prefix
  concourse_keys     = "${path.root}/keys"
  vpc_id             = data.aws_vpc.main.id
  private_subnet_ids = data.aws_subnet_ids.main.ids
  atc_sg             = module.concourse_atc.security_group_id
  tsa_host           = module.concourse_atc.tsa_host
  tsa_port           = module.concourse_atc.tsa_port
  instance_ami       = var.packer_ami

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

# ATC ingress postgres
resource "aws_security_group_rule" "atc_ingress_postgres" {
  security_group_id        = module.postgres.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = module.postgres.port
  to_port                  = module.postgres.port
  source_security_group_id = module.concourse_atc.security_group_id
}
