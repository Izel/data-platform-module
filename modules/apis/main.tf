# Enable Required GCP APIs 
# This module must be deployed before all other modules.
# APIs can take 1-2 minutes to activate after enabling — the depends_on
# pattern in environments/*/main.tf ensures other modules wait for this.
#
# Note: Disabling an API that has existing resources will delete those resources.
# The lifecycle block below prevents accidental disablement on destroy.

resource "google_project_service" "apis" {
  for_each = toset(var.required_apis)

  project = var.project_id
  service = each.value

  # Prevent accidental API disablement when running terraform destroy
  disable_on_destroy         = false
  disable_dependent_services = false
}
