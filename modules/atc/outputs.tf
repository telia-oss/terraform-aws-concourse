# -------------------------------------------------------------------------------
# Output
# -------------------------------------------------------------------------------
output "asg_id" {
  value = module.atc.id
}

output "role_arn" {
  value = module.atc.role_arn
}

output "role_name" {
  value = module.atc.role_name
}

output "security_group_id" {
  value = module.atc.security_group_id
}

output "external_lb_arn" {
  value = module.external_lb.arn
}

output "external_lb_sg" {
  value = module.external_lb.security_group_id
}

output "internal_lb_arn" {
  value = module.internal_lb.arn
}

output "internal_lb_sg" {
  value = module.internal_lb.security_group_id
}

output "tsa_host" {
  value = module.internal_lb.dns_name
}

output "tsa_port" {
  value = var.tsa_port
}

output "endpoint" {
  value = "${lower(var.web_protocol)}://${var.domain == "" ? module.external_lb.dns_name : var.domain}:${var.web_port}"
}

