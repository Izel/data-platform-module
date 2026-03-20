output "log_sink_name" {
  description = "Name of the logging sink"
  value       = google_logging_project_sink.data_platform_sink.name
}

output "dataflow_alert_policy_name" {
  description = "Name of the Dataflow failure alert policy"
  value       = google_monitoring_alert_policy.dataflow_failure.display_name
}
