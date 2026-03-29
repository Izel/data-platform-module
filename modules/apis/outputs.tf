output "enabled_apis" {
  description = "Set of APIs enabled by this module"
  value       = keys(google_project_service.apis)
}

# output "apis_ready" {
#   description = "Dependency handle: reference this output in other modules to ensure APIs are enabled first"
#   value       = true
#   depends_on  = [google_project_service.apis]
# }
