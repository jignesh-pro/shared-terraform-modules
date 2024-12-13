variable "environment" {
  description = "The environment in which the resources are being created"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "uat", "prod"], var.environment)
    error_message = "The environment must be one of 'dev', 'qa', 'uat', or 'prod'."
  }
}

variable "project" {
  description = "The name of the project"
  type        = string
  default     = "test"
}

variable "application_name" {
  description = "The name of the application"
  type        = string
  default     = "api"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "retention_in_days" {
  description = "The number of days to retain log events"
  type        = number
  default     = 7
}

variable "application_port" {
  description = "The port on which the application listens"
  type        = number
  default     = 8080
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "execution_role_arn" {
  description = "The ARN of the IAM role to use for the ECS task execution"
  type        = string

}

variable "task_role_arn" {
  description = "The ARN of the IAM role to use for the ECS task"
  type        = string
}

variable "ecs_cpu" {
  description = "The amount of CPU to reserve for the ECS task"
  type        = string
  default     = "256"

}

variable "ecs_memory" {
  description = "The amount of memory to reserve for the ECS task"
  type        = string
  default     = "512"

}

variable "application_ecr_image" {
  description = "The ECR image to use for the ECS task"
  type        = string

}

variable "ecs_cluster_arn" {
  description = "The name of the ECS cluster ARN"
  type        = string

}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string

}

variable "container_desired_count" {
  description = "The desired count of the container"
  type        = number
  default     = 1

}

variable "container_max_count" {
  description = "The maximum count of the container"
  type        = number
  default     = 2
}

variable "health_check" {
  description = "The health check configuration for the target group"
  type = object({
    path = string
    port = number
  })
  default = {
    path = "/"
    port = 80
  }
}

variable "private_dns_namespace_id" {
  description = "The ID of the private DNS namespace"
  type        = string

}

variable "application_type" {
  description = "The type of the application Allowed values are external or internal"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["external", "internal"], var.application_type)
    error_message = "The environment must be one of 'external' or 'internal'."
  }
}

variable "application_protocol" {
  description = "value of the protocol"
  type        = string
}