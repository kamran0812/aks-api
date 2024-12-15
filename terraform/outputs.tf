output "acr_login_server" {
  value = azurerm_container_registry.timeapi_acr.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.timeapi_acr.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.timeapi_acr.admin_password
  sensitive = true
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service_v1.time_api.metadata[0].name
}

output "service_type" {
  description = "Type of Kubernetes service"
  value       = kubernetes_service_v1.time_api.spec[0].type
}
