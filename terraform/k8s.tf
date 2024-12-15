resource "kubernetes_deployment_v1" "time_api" {
  metadata {
    name = "time-api-deployment"
    labels = {
      app = "time-api"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "time-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "time-api"
        }
      }

      spec {
        container {
          image = "${azurerm_container_registry.timeapi_acr.login_server}/time-api:latest"
          name  = "time-api"

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          # Resource constraints
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }

        # Optional: Image pull secret if needed
        # image_pull_secrets {
        #   name = kubernetes_secret.acr_secret.metadata[0].name
        # }
      }
    }
  }

  depends_on = [docker_registry_image.time_api_push]
}

# Kubernetes Service
resource "kubernetes_service_v1" "time_api" {
  metadata {
    name = "time-api-service"
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-internal" = "false"
    }
  }

  spec {
    selector = {
      app = "time-api"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }

  depends_on = [kubernetes_deployment_v1.time_api]
}

# Optional: Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "time_api_hpa" {
  metadata {
    name = "time-api-hpa"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.time_api.metadata[0].name
    }

    min_replicas = 2
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
