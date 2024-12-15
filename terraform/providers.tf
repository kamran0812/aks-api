# Provider Configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
  }
}

# Configure providers
provider "azurerm" {
  features {}
}

// Mac/Linux
# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }

// Windows
provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
  registry_auth {
    address  = "timeapiregistry.azurecr.io"
    username = azurerm_container_registry.timeapi_acr.admin_username
    password = azurerm_container_registry.timeapi_acr.admin_password
  }
}

provider "kubernetes" {
  host = azurerm_kubernetes_cluster.timeapi_cluster.kube_config.0.host

  client_certificate = base64decode(
    azurerm_kubernetes_cluster.timeapi_cluster.kube_config.0.client_certificate
  )
  client_key = base64decode(
    azurerm_kubernetes_cluster.timeapi_cluster.kube_config.0.client_key
  )
  cluster_ca_certificate = base64decode(
    azurerm_kubernetes_cluster.timeapi_cluster.kube_config.0.cluster_ca_certificate
  )
}
