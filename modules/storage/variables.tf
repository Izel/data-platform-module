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
variable "gcs_kms_key_id" {
  description = "KMS key id to encrypt GCS resources."
  type        = string
}
