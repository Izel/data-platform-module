
variable "project_id" {
  description = "GCP project ID."
  type        = string
}
variable "environment" {
  description = "Environment name for the current deployment."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment variable value must be one of: dev, staging, prd"
  }
}
variable "region" {
  description = "Primary region for project resources provisioning"
  type        = string
  default     = "europe-west2"
}
variable "subnet_cidr" {
  description = "CIDR for defining IP address ranges and network masks."
  type        = string
  default     = "10.8.0.0/28"
}

variable "key_rotation_period" {
  description = "KMS key rotation period in seconds"
  type        = string
}

variable "notification_channel_ids" {
  description = "Monitoring notification channel IDs"
  type        = list(string)
  default     = []
}
