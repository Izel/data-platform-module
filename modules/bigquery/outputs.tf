output "raw_dataset_id" {
  description = "ID of the raw BigQuery dataset"
  value       = google_bigquery_dataset.raw.dataset_id
}

output "curated_dataset_id" {
  description = "ID of the curated BigQuery dataset"
  value       = google_bigquery_dataset.curated.dataset_id
}

output "analytics_dataset_id" {
  description = "ID of the analytics BigQuery dataset"
  value       = google_bigquery_dataset.analytics.dataset_id
}
