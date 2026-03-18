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
}
variable "bq_error_threshold" {
  description = "Any time if the series violates the threshold then the alert gets triggered."
  default     = "3"
}
variable "email_channels" {
  type = map(string)
  default = {
    "ops"      = "ops-team@company.com"
    "dev"      = "dev-team@company.com"
    "security" = "security-team@company.com"
    "managers" = "managers-team@company.com"
  }
}
variable "log_dataset_id" {
  description = "The BigQuery dataset for logs storig."
  type        = string
}
