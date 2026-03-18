# Raw / Landing Zone Bucket 
resource "google_storage_bucket" "raw" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.environment}-raw"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true # Disables ACLs — IAM-only access
  force_destroy               = var.environment != "prod"

  encryption {
    default_kms_key_name = var.gcs_kms_key_id
  }

  lifecycle_rule {
    condition {
      age = 30 # Move to Nearline after 30 days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90 # Move to Coldline after 90 days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    layer       = "raw"
    managed_by  = "terraform"
  }
}

# Processed / Curated Zone Bucket 
resource "google_storage_bucket" "processed" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.environment}-processed"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = var.environment != "prod"

  encryption {
    default_kms_key_name = var.gcs_kms_key_id
  }

  lifecycle_rule {
    condition {
      age = 60
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    layer       = "processed"
    managed_by  = "terraform"
  }
}

# Terraform State Bucket 
resource "google_storage_bucket" "tf_state" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.environment}-tf-state"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = false # Never destroy state bucket

  encryption {
    default_kms_key_name = var.gcs_kms_key_id
  }

  versioning {
    enabled = true # Essential for state file history and recovery
  }

  labels = {
    environment = var.environment
    layer       = "infrastructure"
    managed_by  = "terraform"
  }
}
