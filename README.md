# Terraform AWS ECS Service

This Terraform configuration sets up an AWS ECS service with associated resources such as CloudWatch log group, security group, task definition, and autoscaling policies.

## Variables

| Name                      | Description                                           | Type          | Default       | Required |
|---------------------------|-------------------------------------------------------|---------------|---------------|----------|
| `environment`             | The environment in which the resources are being created | `string`      | `"dev"`       | No       |
| `project`                 | The name of the project                               | `string`      | `"test"`      | No       |
| `application`             | The name of the application                           | `string`      | `"api"`       | No       |
| `tags`                    | A map of tags to add to all resources                 | `map(string)` | `{}`          | No       |
| `retention_in_days`       | The number of days to retain log events               | `number`      | `7`           | No       |
| `application_port`        | The port on which the application listens             | `number`      | `8080`        | No       |
| `vpc_cidr_block`          | The CIDR block for the VPC                            | `string`      | `"10.0.0.0/16"` | No     |
| `vpc_id`                  | The ID of the VPC                                     | `string`      |               | Yes      |
| `private_subnets`         | A list of private subnets inside the VPC              | `list(string)`| `[]`          | No       |
| `execution_role_arn`      | The ARN of the IAM role to use for the ECS task execution | `string`   |               | Yes      |
| `task_role_arn`           | The ARN of the IAM role to use for the ECS task       | `string`      |               | Yes      |
| `ecs_cpu`                 | The amount of CPU to reserve for the ECS task         | `string`      | `"256"`       | No       |
| `ecs_memory`              | The amount of memory to reserve for the ECS task      | `string`      | `"512"`       | No       |
| `application_ecr_image`   | The ECR image to use for the ECS task                 | `string`      |               | Yes      |
| `ecs_cluster_arn`         | The name of the ECS cluster ARN                       | `string`      |               | Yes      |
| `container_desired_count` | The desired count of the container                    | `number`      | `1`           | No       |
| `container_max_count`     | The maximum count of the container                    | `number`      | `2`           | No       |
| `health_check`            | The health check configuration for the target group   | `object`      | `{ path = "/", port = 80 }` | No |
| `ecs_lifecycle_policy`    | The lifecycle policy configuration for the ECS service | `object`     | `{ ignore_changes = ["desired_count", "task_definition", "load_balancer", "service_registries", "service_connect_configuration"] }` | No |

## Example Usage

```hcl
provider "aws" {
  region = "us-west-2"
}

//Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.common_name}-ecs-cluster"
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.sd_http_ns.arn
  }
  tags = merge(local.common_tags, { "Name" = "${local.common_name}-ecs-cluster" })
}

resource "aws_service_discovery_http_namespace" "sd_http_ns" {
  name        = "${local.common_name}-svc.local"
  description = "Service Discovery HTTP Namespace for ECS Service"
  tags = merge(local.common_tags, { Name = "${local.common_name}-svc.local" })
}

module "ecs_service" {
  source = ""git::https://github.com/jignesh-pro/shared-terraform-modules.git//?ref=ecs""

  environment             = "prod"
  project                 = "myproject"
  application             = "myapp"
  tags                    = { Owner = "team", Environment = "production" }
  retention_in_days       = 14
  application_port        = 8080
  vpc_cidr_block          = "10.0.0.0/16"
  vpc_id                  = "vpc-12345678"
  private_subnets         = ["subnet-12345678", "subnet-87654321"]
  execution_role_arn      = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
  task_role_arn           = "arn:aws:iam::123456789012:role/ecsTaskRole"
  ecs_cpu                 = "512"
  ecs_memory              = "1024"
  application_ecr_image   = "123456789012.dkr.ecr.us-west-2.amazonaws.com/myapp:latest"
  ecs_cluster_arn         = "arn:aws:ecs:us-west-2:123456789012:cluster/my-cluster"
  private_dns_namespace_id = aws_servicediscovery_private_dns_namespace.ecs_service_namespace.id
  container_desired_count = 2
  container_max_count     = 4
  health_check = {
    path = "/health"
    port = 8080
  }
  ecs_lifecycle_policy = {
    ignore_changes = [
      "desired_count",
      "task_definition",
      "load_balancer",
      "service_registries",
      "service_connect_configuration",
    ]
  }
}


## Outputs

| Name                                | Description                                                      |
|-------------------------------------|------------------------------------------------------------------|
| `ecs_service_log_group_name`        | The name of the CloudWatch Log Group for the ECS service         |
| `ecs_service_security_group_id`     | The ID of the Security Group for the ECS service                 |
| `ecs_task_definition_arn`           | The ARN of the ECS Task Definition                               |
| `ecs_service_name`                  | The name of the ECS service                                      |
| `ecs_service_target_group_arn`      | The ARN of the Target Group for the ECS service                  |
| `ecs_service_namespace_id`          | The ID of the Private DNS Namespace for the ECS service          |
| `ecs_service_service_id`            | The ID of the Service Discovery Service for the ECS service      |
| `ecs_service_autoscaling_target_id` | The ID of the ECS Service Autoscaling Target                     |
| `ecs_cpu_service_policy_arn`        | The ARN of the ECS Service Autoscaling Policy for CPU            |
| `ecs_memory_service_policy_arn`     | The ARN of the ECS Service Autoscaling Policy for Memory         |