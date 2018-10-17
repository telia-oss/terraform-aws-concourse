provider "aws" {
  region = "eu-west-1"
}

module "concourse" {
  source = "../../"

  name_prefix          = "concourse-example"
  domain               = "concourse.example.com"
  zone_id              = "<zone-id>"
  web_port             = "443"
  web_protocol         = "HTTPS"
  web_certificate_arn  = "<certificate-arn>"
  authorized_cidr      = ["0.0.0.0/0"]
  private_subnet_count = 2

  web_count        = 1
  web_count_max    = 2
  worker_count     = 1
  worker_count_max = 2
  ami_id           = "<packer-ami>"

  postgres_password               = "<kms-encrypted-secret>"
  encryption_key                  = "<kms-encrypted-secret>"
  github_client_id                = "<github-client>"
  github_client_secret            = "<github-secret>"
  github_lambda_deploy_key_prefix = "concourse-stage"

  # Github teams and users that are made into members of the 'main' team on Concourse
  github_users = ["itsdalmo"]
  github_teams = ["telia-oss:concourse-owners"]

  tags {
    environment = "dev"
    terraform   = "True"
  }
}

output "endpoint" {
  description = "The Concourse web interface."
  value       = "${module.concourse.endpoint}"
}
