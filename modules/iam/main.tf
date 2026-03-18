# Service Account: Data Pipeline Runner 
# Used by Dataflow jobs and batch pipelines to read and write data
resource "google_service_account" "data_pipeline" {
  project      = var.project_id
  account_id   = "${var.environment}-data-pipeline-sa"
  display_name = "Data Pipeline Service Account (${var.environment})"
  description  = "Least-privilege SA for data pipeline execution"
}

# Service Account: BigQuery Analyst 
# Used by BI tools and analysts — read-only access to datasets
resource "google_service_account" "bq_analyst" {
  project      = var.project_id
  account_id   = "${var.environment}-bq-analyst-sa"
  display_name = "BigQuery Analyst Service Account (${var.environment})"
  description  = "Read-only SA for BigQuery analytics access"
}

# Service Account: Terraform Deployer 
# Used by CI/CD to deploy infrastructure — scoped to required roles only
resource "google_service_account" "terraform_deployer" {
  project      = var.project_id
  account_id   = "${var.environment}-tf-deployer-sa"
  display_name = "Terraform Deployer Service Account (${var.environment})"
  description  = "SA used by Cloud Build to deploy Terraform changes"
}

# IAM Bindings: Data Pipeline SA 
resource "google_project_iam_member" "pipeline_dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

resource "google_project_iam_member" "pipeline_bq_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

resource "google_project_iam_member" "pipeline_storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

resource "google_project_iam_member" "pipeline_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.data_pipeline.email}"
}

# IAM Bindings: BQ Analyst SA 
resource "google_project_iam_member" "analyst_bq_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.bq_analyst.email}"
}

resource "google_project_iam_member" "analyst_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.bq_analyst.email}"
}

# IAM Bindings: Terraform Deployer SA 
resource "google_project_iam_member" "deployer_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.terraform_deployer.email}"
}

resource "google_project_iam_member" "deployer_bq_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.terraform_deployer.email}"
}
