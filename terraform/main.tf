
# Resource Group
resource "azurerm_resource_group" "timeapi_rg" {
  name     = "aks-api-resources"
  location = "East US"
}

# Azure Container Registry
resource "azurerm_container_registry" "timeapi_acr" {
  name                = "timeapiregistry"
  resource_group_name = azurerm_resource_group.timeapi_rg.name
  location            = azurerm_resource_group.timeapi_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Build Docker Image
resource "docker_image" "time_api" {
  name = "${azurerm_container_registry.timeapi_acr.login_server}/time-api:latest"


  build {
    context = "${path.module}/../api"
  }
}

# Push Image to Azure Container Registry
resource "docker_registry_image" "time_api_push" {
  name          = docker_image.time_api.name
  keep_remotely = true
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "timeapi_cluster" {
  name                = "timeapi-aks"
  location            = azurerm_resource_group.timeapi_rg.location
  resource_group_name = azurerm_resource_group.timeapi_rg.name
  dns_prefix          = "timeapi"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Role Assignment to allow AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.timeapi_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.timeapi_cluster.kubelet_identity[0].object_id
}
