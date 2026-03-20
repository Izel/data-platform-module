output "data_pipeline_sa_email" {
  description = "Email of the data pipeline service account"
  value       = google_service_account.data_pipeline.email
}

output "bq_analyst_sa_email" {
  description = "Email of the BigQuery analyst service account"
  value       = google_service_account.bq_analyst.email
}

output "terraform_deployer_sa_email" {
  description = "Email of the Terraform deployer service account"
  value       = google_service_account.terraform_deployer.email
}
