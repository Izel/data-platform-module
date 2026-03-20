# Log Sink: Export all data platform logs to BigQuery 
resource "google_logging_project_sink" "data_platform_sink" {
  project                = var.project_id
  name                   = "${var.environment}-data-platform-log-sink"
  destination            = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.log_dataset_id}"
  filter                 = "resource.type=(\"dataflow_step\" OR \"bigquery_resource\" OR \"gcs_bucket\" OR \"cloudkms_key\")"
  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Notification Channel: Email notifications for Ops team
resource "google_monitoring_notification_channel" "emails" {
  for_each     = var.email_channels
  display_name = "${each.key} email channel"
  type         = "email"
  labels = {
    email_address = each.value
  }
}

# Alert Policy: Dataflow job failure 
resource "google_monitoring_alert_policy" "dataflow_failure" {
  project      = var.project_id
  display_name = "[${upper(var.environment)}] Dataflow Job Failed"
  combiner     = "OR"

  conditions {
    display_name = "Dataflow job in failed state"
    condition_threshold {
      filter          = "metric.type=\"dataflow.googleapis.com/job/is_failed\" resource.type=\"dataflow_job\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = []

  alert_strategy {
    auto_close = "604800s" # Auto-close after 7 days
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Alert Policy: BigQuery job errors 
resource "google_monitoring_alert_policy" "bq_job_errors" {
  project      = var.project_id
  display_name = "[${upper(var.environment)}] BigQuery Job Errors"
  combiner     = "OR"

  conditions {
    display_name = "BigQuery job error rate elevated"
    condition_threshold {
      filter          = "metric.type=\"bigquery.googleapis.com/storage/table_count\" resource.type=\"bigquery_dataset\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.bq_error_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = emails.email_address

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
