### External Load Balancer ------------------------------------------------------------------------------------------------------------------------------------------------------------------
// source: https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples#with_a_backend

module "external_lb_http" {
  name    = "external-lb-http-${local.frontend_app_name}"
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "9.2.0"
  project = var.project_id

  #ssl                             = var.ssl
  #managed_ssl_certificate_domains = [var.domain]
  #https_redirect                  = var.ssl
  #labels                          = { "example-label" = "cloud-run-example" }

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless_neg_frontend.id
        }
      ]
      enable_cdn = false
      iap_config = {
        enable = false
      }
      log_config = {
        enable = false
      }
    }
  }
  depends_on = [google_project_service.networkmanagement_api, google_project_service.compute_api]
}

resource "google_compute_region_network_endpoint_group" "serverless_neg_frontend" {
  provider              = google-beta
  name                  = "serverless-neg-${local.frontend_app_name}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.frontend_app.name
  }
}

### Front Application - vau.js --------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "frontend_app" {
  name         = local.frontend_app_name
  location     = var.region
  launch_stage = "BETA"
  ingress      = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  template {
    containers {
      // Git repository: https://github.com/silvermx/generic-webapp-frontend
      image = "${var.repo_name}/${local.frontend_app_name}:latest"
      ports {
        container_port = 8080
      }
      env {
        name  = "NUXT_APP_INTERNAL_LB_URL"
        value = "http://${google_compute_forwarding_rule.forwarding_rule_backend.ip_address}:8080"

      }
    }
    vpc_access {
      network_interfaces {
        network    = google_compute_network.internal_lb_network.name
        subnetwork = google_compute_subnetwork.internal_lb_subnet.name
      }
      egress = "ALL_TRAFFIC"
    }
  }
  depends_on = [google_compute_forwarding_rule.forwarding_rule_backend, google_project_service.cloudrun_api]
}

resource "google_cloud_run_v2_service_iam_member" "frontend_app_access" {
  location = var.region
  project  = var.project_id
  name     = google_cloud_run_v2_service.frontend_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}