# -------------------------------------------------------------------------------
# Output
# -------------------------------------------------------------------------------
output "asg_id" {
  value = module.worker.id
}

output "role_arn" {
  value = module.worker.role_arn
}

output "role_name" {
  value = module.worker.role_name
}

output "security_group_id" {
  value = module.worker.security_group_id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.worker.name
}

output "lifecycled_log_group_name" {
  value = aws_cloudwatch_log_group.worker_lifecycled.name
}
