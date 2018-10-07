# -------------------------------------------------------------------------------
# Output
# -------------------------------------------------------------------------------
output "endpoint" {
  value = "${module.concourse_atc.endpoint}"
}

output "sts_lambda_arn" {
  value = "${module.sts_lambda.arn}"
}

output "sts_lambda_role_arn" {
  value = "${module.sts_lambda.role_arn}"
}

output "github_lambda_arn" {
  value = "${module.github_lambda.function_arn}"
}
