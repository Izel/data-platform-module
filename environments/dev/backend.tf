terraform {
  backend "gcs" {
    bucket = "${var.project_id}-${var.environment}-tf-state"
    prefix = "terraform/state/dev"
  }
}
