# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "public_subnet_ids" {
  description = "ID of subnets where public resources (public LB) can be provisioned."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "ID of subnets where private resources (ATC and private LB) can be provisioned."
  type        = list(string)
}

variable "authorized_cidr" {
  description = "List of authorized CIDR blocks which can reach the Concourse web interface."
  type        = list(string)
}

variable "min_size" {
  description = "The minimum (and desired) size of the auto scale group."
  default     = "1"
}

variable "max_size" {
  description = "The maximum size of the auto scale group."
  default     = "2"
}

variable "instance_type" {
  description = "Type of instance to provision for the Concourse ATC."
  default     = "t3.small"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch. See the include packer image."
}

variable "instance_key" {
  description = "The key name that should be used for the ATC instances."
  default     = ""
}

variable "concourse_keys" {
  description = "Path to a directory containing the Concourse SSH keys. (See README.md)."
}

variable "postgres_host" {
  description = "The DNS address of the postgres DB."
}

variable "postgres_port" {
  description = "The port on which the DB accepts connections."
}

variable "postgres_username" {
  description = "The master username for the database."
}

variable "postgres_password" {
  description = "Password for the master DB user."
}

variable "postgres_database" {
  description = "Name for the automatically created database."
}

variable "github_client_id" {
  description = "Application client ID for enabling GitLab OAuth."
  default     = ""
}

variable "github_client_secret" {
  description = "Application client secret for enabling GitLab OAuth."
  default     = ""
}

variable "github_users" {
  description = "GitHub user to permit admin access."
  type        = list(string)
  default     = []
}

variable "github_teams" {
  description = "GitHub team whose members will have admin access (<org>:<team>)."
  type        = list(string)
  default     = []
}

variable "local_user" {
  description = "Create a local user (format: username:password)."
  default     = ""
}

variable "local_admin_user" {
  description = "Add the local user to the main team to grant admin privileges (format: username)."
  default     = ""
}

variable "domain" {
  description = "The (domain) name of the record."
  default     = ""
}

variable "zone_id" {
  description = "The ID of the hosted zone to contain this record."
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
  description = "The ARN of the default SSL server certificate. Exactly one certificate is required if the protocol (Concourse web interface) is HTTPS."
  default     = ""
}

variable "atc_port" {
  description = "Port specification for the Concourse ATC."
  default     = "8080"
}

variable "tsa_port" {
  description = "Port specification for the Concourse TSA."
  default     = "2222"
}

variable "prometheus_enabled" {
  description = "Enable exporting of prometheus metrics."
  default     = "false"
}

variable "prometheus_port" {
  description = "Port where prometheus metrics can be scraped."
  default     = "9391"
}

variable "encryption_key" {
  description = "A 16 or 32 length key used to encrypt sensitive information before storing it in the database."
}

variable "old_encryption_key" {
  description = "Encryption key previously used for encrypting sensitive information. If provided without a new key, data is encrypted. If provided with a new key, data is re-encrypted."
  default     = ""
}

variable "log_level" {
  description = "Minimum level of logs to see (options: debug|info|error|fatal)."
  default     = "info"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

