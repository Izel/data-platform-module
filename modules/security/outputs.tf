output "keyring_id" {
  description = "ID of the KMS key ring"
  value       = google_kms_key_ring.data_platform.id
}

output "gcs_kms_key_id" {
  description = "ID of the KMS key for GCS encryption"
  value       = google_kms_crypto_key.gcs_key.id
}

output "bigquery_kms_key_id" {
  description = "ID of the KMS key for BigQuery encryption"
  value       = google_kms_crypto_key.bigquery_key.id
}

output "db_credentials_secret_id" {
  description = "Secret Manager secret ID for database credentials"
  value       = google_secret_manager_secret.db_credentials.secret_id
}
