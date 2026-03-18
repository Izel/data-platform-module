# KMS Key Ring 
# One key ring per environment — groups all encryption keys logically
resource "google_kms_key_ring" "data_platform" {
  project  = var.project_id
  name     = "${var.environment}-data-platform-keyring"
  location = var.region
}

# KMS Key: GCS Buckets
resource "google_kms_crypto_key" "gcs_key" {
  name            = "${var.environment}-gcs-cmek"
  key_ring        = google_kms_key_ring.data_platform.id
  rotation_period = var.key_rotation_period

  lifecycle {
    prevent_destroy = true # Never accidentally destroy encryption keys
  }
}

# KMS Key: BigQuery 
resource "google_kms_crypto_key" "bigquery_key" {
  name            = "${var.environment}-bigquery-cmek"
  key_ring        = google_kms_key_ring.data_platform.id
  rotation_period = var.key_rotation_period

  lifecycle {
    prevent_destroy = true
  }
}

# Grant GCS service account permission to use the KMS key 
data "google_storage_project_service_account" "gcs_sa" {
  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_kms_binding" {
  crypto_key_id = google_kms_crypto_key.gcs_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_sa.email_address}"
}

# Grant BigQuery service account permission to use the KMS key 
data "google_bigquery_default_service_account" "bq_sa" {
  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "bq_kms_binding" {
  crypto_key_id = google_kms_crypto_key.bigquery_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_bigquery_default_service_account.bq_sa.email}"
}

# Secret Manager: Database credentials
# Secret shell only — actual value set out-of-band, never in Terraform state
resource "google_secret_manager_secret" "db_credentials" {
  project   = var.project_id
  secret_id = "${var.environment}-db-credentials"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Secret Manager: Pipeline API keys 
resource "google_secret_manager_secret" "pipeline_api_key" {
  project   = var.project_id
  secret_id = "${var.environment}-pipeline-api-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
