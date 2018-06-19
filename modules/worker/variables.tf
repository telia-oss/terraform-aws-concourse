# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "private_subnet_ids" {
  description = "ID of subnets where private resources (Workers) can be provisioned."
  type        = "list"
}

variable "min_size" {
  description = "The minimum (and desired) size of the auto scale group."
  default     = "1"
}

variable "max_size" {
  description = "The maximum size of the auto scale group."
  default     = "3"
}

variable "instance_type" {
  description = "Type of instance to provision for the Concourse workers."
  default     = "m5.large"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch. See the include packer image."
}

variable "instance_key" {
  description = "The key name that should be used for the worker instances."
  default     = ""
}

variable "concourse_keys" {
  description = "Path to a directory containing the Concourse SSH keys. (See README.md)."
}

variable "atc_sg" {
  description = "The ID of the security group created for the Concourse ATC."
}

variable "tsa_host" {
  description = "TSA host to forward the worker through (i.e. the address of the internal load balancer for the ATC)."
}

variable "tsa_port" {
  description = "The port used to reach the TSA host."
}

variable "worker_team" {
  description = "The name of the team that this worker will be assigned to."
  default     = ""
}

variable "log_level" {
  description = "Minimum level of logs to see (options: debug|info|error|fatal)."
  default     = "info"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}
