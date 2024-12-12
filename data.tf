# Data block to check if the namespace exists
data "aws_service_discovery_private_dns_namespace" "existing" {
  name = "${local.common_name}-svc.local"
}