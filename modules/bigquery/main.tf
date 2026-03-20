# Raw Dataset 
resource "google_bigquery_dataset" "raw" {
  project                    = var.project_id
  dataset_id                 = "${var.environment}_raw"
  friendly_name              = "Raw Layer (${var.environment})"
  description                = "Landing zone for raw ingested data. No transformations applied."
  location                   = var.region
  delete_contents_on_destroy = var.environment != "prod"

  default_encryption_configuration {
    kms_key_name = var.bigquery_kms_key_id
  }

  # Default table expiry — raw data expires after 90 days in dev
  default_table_expiration_ms = var.environment == "dev" ? 7776000000 : null

  labels = {
    environment = var.environment
    layer       = "raw"
    managed_by  = "terraform"
  }
}

# Curated Dataset 
resource "google_bigquery_dataset" "curated" {
  project                    = var.project_id
  dataset_id                 = "${var.environment}_curated"
  friendly_name              = "Curated Layer (${var.environment})"
  description                = "Cleaned, validated, and transformed data ready for analytics."
  location                   = var.region
  delete_contents_on_destroy = var.environment != "prod"

  default_encryption_configuration {
    kms_key_name = var.bigquery_kms_key_id
  }

  labels = {
    environment = var.environment
    layer       = "curated"
    managed_by  = "terraform"
  }
}

# Analytics Dataset 
resource "google_bigquery_dataset" "analytics" {
  project                    = var.project_id
  dataset_id                 = "${var.environment}_analytics"
  friendly_name              = "Analytics Layer (${var.environment})"
  description                = "Aggregated and business-ready data for dashboards and reporting."
  location                   = var.region
  delete_contents_on_destroy = var.environment != "prod"

  default_encryption_configuration {
    kms_key_name = var.bigquery_kms_key_id
  }

  labels = {
    environment = var.environment
    layer       = "analytics"
    managed_by  = "terraform"
  }
}

# Dataset IAM: pipeline SA can write to raw and curated 
resource "google_bigquery_dataset_iam_member" "pipeline_raw_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.data_pipeline_sa_email}"
}

resource "google_bigquery_dataset_iam_member" "pipeline_curated_editor" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.curated.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.data_pipeline_sa_email}"
}

# Dataset IAM: analyst SA can read analytics only 
resource "google_bigquery_dataset_iam_member" "analyst_analytics_viewer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.bq_analyst_sa_email}"
}
