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
variable "data_pipeline_sa_email" {
  description = "Service Account to run the data pipeline."
  type        = string
  default     = "pipeline-sa"
}
variable "bigquery_kms_key_id" {
  description = "KMS key used to encrypt data in BQ."
  type        = string
}
variable "bq_analyst_sa_email" {
  description = "Service account for Analytics."
  type        = string
  default     = "value"
}
