variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "log_dataset_id" {
  description = "BigQuery dataset ID to export logs into (from bigquery module output)"
  type        = string
}

variable "notification_channel_ids" {
  description = "List of Cloud Monitoring notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "bq_error_threshold" {
  description = "BigQuery error rate threshold to trigger an alert"
  type        = number
  default     = 5
}
