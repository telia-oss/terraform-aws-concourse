# -------------------------------------------------------------------------------
# Resources
# -------------------------------------------------------------------------------
data "aws_region" "current" {}

locals {
  nat_inbound = [
    for i, id in var.nat_gateway_ids : [
      "AWS/NATGateway",
      "BytesInFromDestination",
      "NatGatewayId",
      id,
      {
        stat    = "Average"
        id      = "nat-${i + 1}-inbound"
        visible = false
      }
    ]
  ]

  nat_outbound = [
    for i, id in var.nat_gateway_ids : [
      "AWS/NATGateway",
      "BytesInFromSource",
      "NatGatewayId",
      id,
      {
        stat    = "Average"
        id      = "nat-${i + 1}-outbound"
        visible = false
      }
    ]
  ]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.name_prefix
  dashboard_body = templatefile("${path.module}/dashboard.json.template", {
    cloudwatch_namespace  = var.name_prefix
    atc_asg_name          = var.atc_asg_name
    atc_log_group_name    = var.atc_log_group_name
    worker_asg_name       = var.worker_asg_name
    worker_log_group_name = var.worker_log_group_name
    rds_cluster_id        = var.rds_cluster_id
    external_lb           = join("/", slice(split("/", var.external_lb_arn), 1, 4))
    internal_lb           = join("/", slice(split("/", var.internal_lb_arn), 1, 4))
    nat_gateway_metrics   = concat(local.nat_inbound, local.nat_outbound)
    nat_inbound_ids       = [for i, _ in var.nat_gateway_ids : "nat-${i + 1}-inbound"]
    nat_outbound_ids      = [for i, _ in var.nat_gateway_ids : "nat-${i + 1}-outbound"]
    period                = var.period
    region                = data.aws_region.current.name
  })
}
