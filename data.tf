# Data block to check if the namespace exists
data "aws_service_discovery_namespace" "existing" {
  filter {
    name   = "TYPE"
    values = ["DNS_PRIVATE"]
  }

  filter {
    name   = "NAME"
    values = ["${local.common_name}-svc.local"]
  }
}