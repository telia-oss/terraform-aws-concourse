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

variable "private_subnet_ids" {
  description = "ID of subnets where private resources (Workers) can be provisioned."
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
  default     = 3
}

variable "instance_type" {
  description = "Type of instance to provision for the Concourse workers."
  type        = string
  default     = "t3.large"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch. See the include packer image."
  type        = string
}

variable "instance_key" {
  description = "The key name that should be used for the worker instances."
  type        = string
  default     = ""
}

variable "instance_volume_size" {
  description = "The size of the worker volumes in gigabytes."
  type        = number
  default     = 50
}

variable "concourse_keys" {
  description = "Path to a directory containing the Concourse SSH keys. (See README.md)."
  type        = string
}

variable "atc_sg" {
  description = "The ID of the security group created for the Concourse ATC."
  type        = string
}

variable "tsa_host" {
  description = "TSA host to forward the worker through (i.e. the address of the internal load balancer for the ATC)."
  type        = string
}

variable "tsa_port" {
  description = "The port used to reach the TSA host."
  type        = number
}

variable "prometheus_enabled" {
  description = "Enable exporting of prometheus metrics."
  type        = bool
  default     = false
}

variable "worker_team" {
  description = "The name of the team that this worker will be assigned to."
  type        = string
  default     = ""
}

variable "ulimit_no_file" {
  description = "Number of File Descriptors (default is 4096:8192, softlimit:hardlimit)"
  type        = string
  default     = "4096:8192"
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
