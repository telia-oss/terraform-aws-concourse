# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID."
  type        = string
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
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of the auto scale group."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "Type of instance to provision for the Concourse ATC."
  type        = string
  default     = "t3.small"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch. See the include packer image."
  type        = string
}

variable "instance_key" {
  description = "The key name that should be used for the ATC instances."
  type        = string
  default     = ""
}

variable "concourse_keys" {
  description = "Path to a directory containing the Concourse SSH keys. (See README.md)."
  type        = string
}

variable "postgres_host" {
  description = "The DNS address of the postgres DB."
  type        = string
}

variable "postgres_port" {
  description = "The port on which the DB accepts connections."
  type        = number
}

variable "postgres_username" {
  description = "The master username for the database."
  type        = string
}

variable "postgres_password" {
  description = "Password for the master DB user."
  type        = string
}

variable "postgres_database" {
  description = "Name for the automatically created database."
  type        = string
}

variable "github_client_id" {
  description = "Application client ID for enabling GitLab OAuth."
  type        = string
  default     = ""
}

variable "github_client_secret" {
  description = "Application client secret for enabling GitLab OAuth."
  type        = string
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
  type        = string
  default     = ""
}

variable "local_admin_user" {
  description = "Add the local user to the main team to grant admin privileges (format: username)."
  type        = string
  default     = ""
}

variable "domain" {
  description = "The (domain) name of the record."
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "The ID of the hosted zone to contain this record."
  type        = string
  default     = ""
}

variable "web_protocol" {
  description = "The protocol for connections from clients to the external load balancer (Concourse web interface)."
  type        = string
  default     = "HTTP"
}

variable "web_port" {
  description = "The port on which the external load balancer is listening (Concourse web interface)"
  type        = number
  default     = 80
}

variable "web_certificate_arn" {
  description = "The ARN of the default SSL server certificate. Exactly one certificate is required if the protocol (Concourse web interface) is HTTPS."
  type        = string
  default     = ""
}

variable "atc_port" {
  description = "Port specification for the Concourse ATC."
  type        = number
  default     = 8080
}

variable "tsa_port" {
  description = "Port specification for the Concourse TSA."
  type        = number
  default     = 2222
}

variable "prometheus_enabled" {
  description = "Enable exporting of prometheus metrics."
  type        = bool
  default     = false
}

variable "prometheus_port" {
  description = "Port where prometheus metrics can be scraped."
  type        = number
  default     = 9391
}

variable "placement_strategy" {
  description = "Concourse container placement strategy."
  type        = string
  default     = "volume-locality"
}

variable "encryption_key" {
  description = "A 16 or 32 length key used to encrypt sensitive information before storing it in the database."
  type        = string
}

variable "old_encryption_key" {
  description = "Encryption key previously used for encrypting sensitive information. If provided without a new key, data is encrypted. If provided with a new key, data is re-encrypted."
  type        = string
  default     = ""
}

variable "log_level" {
  description = "Minimum level of logs to see (options: debug|info|error|fatal)."
  type        = string
  default     = "info"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

