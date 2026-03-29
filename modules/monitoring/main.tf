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

# Grant the sink writer permission to write to the BQ log dataset
resource "google_project_iam_member" "log_sink_bq_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_logging_project_sink.data_platform_sink.writer_identity
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

  notification_channels = var.notification_channel_ids

  alert_strategy {
    auto_close = "604800s" # Auto-close after 7 days
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Log-Based Metric: BigQuery job errors 
# Counts BigQuery ERROR log entries.
# Cloud Logging captures all BQ job activity, this metric increments each
# time a log entry with severity=ERROR appears for a BigQuery resource.
resource "google_logging_metric" "bq_job_errors" {
  project = var.project_id
  name    = "${var.environment}-bq-job-errors"

  # Filter matches any ERROR-level log entry from BigQuery jobs
  filter = <<-EOT
    resource.type="bigquery_resource"
    AND severity=ERROR
  EOT

  metric_descriptor {
    metric_kind = "DELTA" # Counts new errors in each time window (not cumulative)
    value_type  = "INT64" # Integer count of error occurrences
    unit        = "1"

    labels {
      key         = "error_code"
      value_type  = "STRING"
      description = "The BigQuery error code from the log entry"
    }
  }

  label_extractors = {
    # Pulls the error code out of the log payload so alerts show which error occurred
    "error_code" = "EXTRACT(protoPayload.status.code)"
  }
}

# Alert Policy: BigQuery job errors 
# fires when the log-based metric above exceeds the threshold.
# It means, more than N BigQuery errors have occurred in a 5-minute window.
resource "google_monitoring_alert_policy" "bq_job_errors" {
  project      = var.project_id
  display_name = "[${upper(var.environment)}] BigQuery Job Errors"
  combiner     = "OR"

  conditions {
    display_name = "BigQuery error log entries exceeded threshold"

    condition_threshold {
      # Reference the log-based metric we created above
      filter     = "metric.type=\"logging.googleapis.com/user/${var.environment}-bq-job-errors\" resource.type=\"bigquery_resource\""
      duration   = "0s" # Fire immediately when threshold is crossed. No sustained period required
      comparison = "COMPARISON_GT"

      # Fires when more than N errors occur in the alignment window
      threshold_value = var.bq_error_threshold

      aggregations {
        alignment_period   = "300s"      # 5-minute window. Counts all errors in each 5-min bucket
        per_series_aligner = "ALIGN_SUM" # ALIGN_SUM counts all error counts within the window
      }
    }
  }

  notification_channels = var.notification_channel_ids

  # Prevents alert storms. if the alert fires, wait 5 min before re-notifying
  alert_strategy {
    auto_close = "604800s" # close after 7 days if not resolved
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
