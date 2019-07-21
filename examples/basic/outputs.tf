

output "endpoint" {
  description = "The Concourse web interface."
  value       = module.concourse_atc.endpoint
}

output "atc_asg_id" {
  description = "ID/name of the ATC autoscaling group."
  value       = module.concourse_atc.asg_id
}

output "worker_asg_id" {
  description = "ID/name of the worker autoscaling group."
  value       = module.concourse_worker.asg_id
}
