# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "domain" {
  description = "The (domain) name to use for a new Concourse record."
  default     = ""
}

variable "zone_id" {
  description = "The ID of the hosted zone to contain the Concourse record."
  default     = ""
}

variable "web_protocol" {
  description = "The protocol for connections from clients to the external load balancer (Concourse web interface)."
  default     = "HTTP"
}

variable "web_port" {
  description = "The port on which the external load balancer is listening (Concourse web interface)"
  default     = "80"
}

variable "web_certificate_arn" {
  description = "The ARN of the default SSL server certificate."
  default     = ""
}

variable "authorized_cidr" {
  description = "List of authorized CIDR blocks which can reach the Concourse web interface."
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "private_subnet_count" {
  description = "Number of private subnets to provision (will not exceed the number of AZ's in the region)."
  default     = "3"
}

variable "web_count" {
  description = "The minimum and desired number of Concourse web nodes to provision."
  default     = "1"
}

variable "web_count_max" {
  description = "The maximum number of Concourse web nodes to provision."
  default     = "2"
}

variable "worker_count" {
  description = "The minimum and desired number of Concourse worker nodes to provision."
  default     = "1"
}

variable "worker_count_max" {
  description = "The maximum number of Concourse worker nodes to provision."
  default     = "2"
}

variable "ami_id" {
  description = "The EC2 image ID to launch. See the include packer image."
}

variable "github_users" {
  description = "GitHub user to permit admin access."
  type        = "list"
  default     = []
}

variable "github_teams" {
  description = "GitHub team whose members will have admin access (<org>:<team>)."
  type        = "list"
  default     = []
}

variable "github_client_id" {
  description = "Application client ID for GitLab OAuth."
}

variable "github_client_secret" {
  description = "Application client secret for GitLab OAuth (KMS encrypted)."
}

variable "sts_lambda_zip" {
  description = "Path to the STS lambda zip-file."
}

variable "github_lambda_zip" {
  description = "Path to the Github lambda zip-file."
}

variable "github_lambda_deploy_key_prefix" {
  description = "Prefix to use for deploy keys created by the Github Lambda (to avoid conflicts between e.g. stage and prod)."
}

variable "postgres_username" {
  description = "Username for the master DB user."
  default     = "superuser"
}

variable "postgres_password" {
  description = "Password for the master DB user (KMS encrypted)."
}

variable "encryption_key" {
  description = "A 16 or 32 length key used to encrypt sensitive information before storing it in the database (KMS encrypted)."
}

variable "postgres_snapshot_identifier" {
  description = "Snapshot identifier to restore the postgres backend from."
  default     = ""
}

variable "prometheus_sg" {
  description = "The security group ID of Prometheus. Will be allowed ingress to the web/worker nodes to scrape metrics."
  default     = ""
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}
