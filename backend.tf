### Interal Loand Balancer ------------------------------------------------------------------------------------------------------------------------------------------------------------------
// source: https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-internal-serverless#gcloud_2

//TODO add the ssl-certificates
resource "google_compute_region_network_endpoint_group" "serverless_neg_backend" {
  name                  = "serverless-neg-${local.backend_app_name}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.backend_app.name
  }
  depends_on = [google_project_service.networkmanagement_api]
}

# backend service
resource "google_compute_region_backend_service" "region_backend_frontend" {
  name                  = "region-backend-frontend-${var.project_name}"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  backend {
    group           = google_compute_region_network_endpoint_group.serverless_neg_backend.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# URL map
resource "google_compute_region_url_map" "url_map_backend" {
  name            = "url-map-${local.backend_app_name}"
  region          = var.region
  default_service = google_compute_region_backend_service.region_backend_frontend.id
}

# HTTP target proxy
resource "google_compute_region_target_http_proxy" "http_proxy_backend" {
  name    = "http-proxy-${local.backend_app_name}"
  region  = var.region
  url_map = google_compute_region_url_map.url_map_backend.id
}

# forwarding rule
resource "google_compute_forwarding_rule" "forwarding_rule_backend" {
  name                  = "forwarding-rule-${local.backend_app_name}"
  depends_on            = [google_compute_subnetwork.proxy_only_subnet]
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "8080"
  target                = google_compute_region_target_http_proxy.http_proxy_backend.id
  network               = google_compute_network.internal_lb_network.id
  subnetwork            = google_compute_subnetwork.internal_lb_subnet.id
  network_tier          = "PREMIUM"
}


### Back Application - Java  ----------------------------------------------------------------------------------------------------------------------------------------------------------------
//source: https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-java-service
//source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service#example-usage---cloudrunv2-service-sql

resource "google_cloud_run_v2_service" "backend_app" {
  name     = local.backend_app_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    tag     = local.backend_app_name
  }

  template {
    containers {
      // Git repository: https://github.com/silvermx/generic-webapp-backend
      image = "${var.repo_name}/${local.backend_app_name}:latest"
      ports {
        container_port = 8080
      }
      env {
        name  = "INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.instance.connection_name
      }
      env {
        name  = "DATABASE_NAME"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.db_name.secret_id
            version = "1"
          }
        }
      }
      env {
        name  = "DATABASE_USERNAME"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.db_user_name.secret_id
            version = "1"
          }
        }
      }
      env {
        name  = "DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.db_user_pass.secret_id
            version = "1"
          }
        }
      }
      env {
        name  = "APP_FRONTEND_URL"
        value = "http://${module.external_lb_http.external_ip}"
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.instance.connection_name]
      }
    }
  }
  client = "terraform"
  depends_on = [google_project_service.secretmanager_api, google_project_service.cloudrun_api, google_project_service.sqladmin_api]
}

resource "google_cloud_run_v2_service_iam_member" "public_access_backend" {
  location = var.region
  project  = var.project_id
  name     = google_cloud_run_v2_service.backend_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}