terraform {
  backend "gcs" {
    bucket = "${var.project_id}-${var.environment}-terraform-state"
    prefix = "terraform/state"
  }
}
