# -------------------------------------------------------------------------------
# Output
# -------------------------------------------------------------------------------
output "role_arn" {
  value = "${module.worker.role_arn}"
}

output "role_name" {
  value = "${module.worker.role_name}"
}

output "security_group_id" {
  value = "${module.worker.security_group_id}"
}
