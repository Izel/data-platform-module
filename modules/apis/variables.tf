variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "required_apis" {
  description = "List of GCP APIs to enable for the data platform"
  type        = list(string)
}
