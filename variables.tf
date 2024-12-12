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

variable "application" {
  description = "The name of the application"
  type        = string
  default     = "api"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = false
}