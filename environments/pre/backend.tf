terraform {
  backend "gcs" {
    # Replace the bucket with the bucket name
    bucket = "${var.project_id}-${var.environment}-terraform-state"
    prefix = "terraform/state"
  }
}
