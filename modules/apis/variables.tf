variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "required_apis" {
  description = "List of GCP APIs to enable for the data platform"
  type        = list(string)
  default = [
    # Networking 
    "compute.googleapis.com", # VPC, subnets, firewall rules

    # Core Platform 
    "cloudresourcemanager.googleapis.com", # Required by Terraform itself
    "iam.googleapis.com",                  # IAM service accounts and bindings
    #"iamcredentials.googleapis.com",       # Workload Identity / SA token generation

    # Data Storage 
    "storage.googleapis.com",  # Cloud Storage (GCS)
    "bigquery.googleapis.com", # BigQuery datasets and tables
    #"bigquerystorage.googleapis.com", # BigQuery Storage API (fast reads)

    # Data Pipeline 
    #"dataflow.googleapis.com", # Dataflow (Apache Beam runner)
    #"pubsub.googleapis.com",   # Pub/Sub messaging

    # Security 
    "cloudkms.googleapis.com",      # Cloud KMS (CMEK encryption)
    "secretmanager.googleapis.com", # Secret Manager

    # Monitoring & Logging 
    "monitoring.googleapis.com", # Cloud Monitoring and alerting
    "logging.googleapis.com",    # Cloud Logging and log sinks
    "cloudtrace.googleapis.com", # Distributed tracing

    # CI/CD
    #"cloudbuild.googleapis.com",           # Cloud Build for CI/CD pipelines
    #"artifactregistry.googleapis.com",     # Artifact Registry for container images

    # Service Account & Workload Identity 
    #"serviceusage.googleapis.com", # Manage which APIs are enabled
  ]
}
