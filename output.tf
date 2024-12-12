output "ecs_service_log_group_name" {
  description = "The name of the CloudWatch Log Group for the ECS service"
  value       = aws_cloudwatch_log_group.ecs_service_log_group.name
}

output "ecs_service_security_group_id" {
  description = "The ID of the Security Group for the ECS service"
  value       = aws_security_group.ecs_service_sg.id
}

output "ecs_task_definition_arn" {
  description = "The ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.api_task_definition.arn
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.ecs_service.name
}

output "ecs_service_target_group_arn" {
  description = "The ARN of the Target Group for the ECS service"
  value       = try(aws_lb_target_group.ecs_service_target_group[0].arn, null)
}

output "ecs_service_target_group_name" {
  description = "The name of the Target Group for the ECS service"
  value       = try(aws_lb_target_group.ecs_service_target_group[0].name, null)
}

output "ecs_service_autoscaling_target_id" {
  description = "The ID of the ECS Service Autoscaling Target"
  value       = aws_appautoscaling_target.ecs_service_target.id
}

output "ecs_cpu_service_policy_arn" {
  description = "The ARN of the ECS Service Autoscaling Policy for CPU"
  value       = aws_appautoscaling_policy.ecs_cpu_service_policy.arn
}

output "ecs_memory_service_policy_arn" {
  description = "The ARN of the ECS Service Autoscaling Policy for Memory"
  value       = aws_appautoscaling_policy.ecs_memory_service_policy.arn
}