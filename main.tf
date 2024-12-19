//get region
data "aws_region" "current" {}

locals {
  common_name = "${var.environment}-${var.project}-${var.application_name}"
}

//Create Cloudwatch Group for ECS service Logs
resource "aws_cloudwatch_log_group" "ecs_service_log_group" {
  name              = "/ecs/${local.common_name}-SVCECSLogGroup"
  retention_in_days = var.retention_in_days
  tags              = merge(var.tags, { Name = "${local.common_name}-SVCECSLogGroup" })
}

resource "random_integer" "four_digit_number" {
  min = 1000
  max = 9999
}

//Create Security Group for ECS Service
resource "aws_security_group" "ecs_service_sg" {
  name        = "${local.common_name}-${random_integer.four_digit_number.result}-SVCECSSG"
  description = "Security Group for ECS Service"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${local.common_name}-SVCECSSG" })
}

resource "aws_ecs_task_definition" "api_task_definition" {
  family                   = "${local.common_name}-ECSTaskDefinition"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name                   = var.application_name
      image                  = var.application_ecr_image
      cpu                    = tonumber(var.ecs_cpu)
      memory                 = tonumber(var.ecs_memory)
      enable_execute_command = true
      essential              = true
      portMappings = [
        {
          containerPort = tonumber(var.application_port)
          hostPort      = tonumber(var.application_port)
          protocol      = var.application_protocol
          name          = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_service_log_group.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
          "mode"                  = "non-blocking"
          "max-buffer-size"       = "25m"
        }
      }
    }
  ])
  tags = merge(var.tags, { Name = "${local.common_name}-API-ECSTaskDefinition" })
}

//create ecs service
resource "aws_ecs_service" "ecs_service" {
  name            = "${local.common_name}-svc"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.api_task_definition.arn
  desired_count   = var.container_desired_count
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = var.environment == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight            = 1
  }

  dynamic "load_balancer" {
    for_each = var.application_type == "external" ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.ecs_service_target_group[0].arn
      container_name   = var.application_name
      container_port   = var.application_port
    }
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  propagate_tags                     = "SERVICE"
  scheduling_strategy                = "REPLICA"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service_discovery_service.arn
  }

  # service_connect_configuration {
  #   enabled   = true
  #   namespace = var.private_dns_namespace_id

  # service {
  #   port_name      = "http"
  #   discovery_name = var.application_name
  #   client_alias {
  #     port = var.application_port
  #   }
  # }
  # }

  tags = merge(var.tags, { Name = "${local.common_name}-svc" })
  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      # load_balancer,
      # service_registries,
      # service_connect_configuration,
    ]
  }
}

// Create Service Discovery Service for API Service
resource "aws_service_discovery_service" "service_discovery_service" {
  name = var.application_name
  dns_config {
    namespace_id = var.private_dns_namespace_id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(var.tags, { "Name" = "${local.common_name}-Service" }, )
}

//Create a target group for the ECS service
resource "aws_lb_target_group" "ecs_service_target_group" {
  count       = var.application_type == "external" ? 1 : 0
  name        = "${local.common_name}-SVCECS-TG"
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check.path
    port                = var.health_check.port
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = merge(var.tags, { Name = "${local.common_name}-SVCECSTargetGroup" })
}

//Create ECS Service Autoscaling Policy
resource "aws_appautoscaling_target" "ecs_service_target" {
  max_capacity       = var.container_max_count
  min_capacity       = var.container_desired_count
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

//Create ECS Service Autoscaling Policy for CPU
resource "aws_appautoscaling_policy" "ecs_cpu_service_policy" {
  name               = "${var.application_name}-CPUECSServiceScalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

//Create ECS Service Autoscaling Policy for Memory
resource "aws_appautoscaling_policy" "ecs_memory_service_policy" {
  name               = "${var.application_name}-MemoryECSServiceScalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}