# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "atc_asg_name" {
  description = "Name of the ATC autoscaling group."
  type        = string
}

variable "atc_log_group_name" {
  description = "Name of the ATC log group."
  type        = string
}

variable "worker_asg_name" {
  description = "Name of the worker autoscaling group."
  type        = string
}

variable "worker_log_group_name" {
  description = "Name of the worker log group."
  type        = string
}

variable "rds_cluster_id" {
  description = "ID/Name of the RDS cluster."
  type        = string
}

variable "external_lb_arn" {
  description = "ARN of the external load balancer."
  type        = string
}

variable "internal_lb_arn" {
  description = "ARN of the external load balancer."
  type        = string
}

variable "nat_gateway_ids" {
  description = "A list of NAT gateways for which to include metrics."
  type        = list(string)
  default     = []
}

variable "period" {
  description = "The default period, in seconds, for all metrics in this widget. The period is the length of time represented by one data point on the graph."
  type        = number
  default     = 60
}


variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

