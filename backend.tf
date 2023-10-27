### Network ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// Interal Loand Balancer
// source: https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-internal-serverless#gcloud_2

//TODO add the ssl-certificates
resource "google_compute_region_network_endpoint_group" "serverless_neg_backend" {
  provider              = google-beta
  name                  = "serverless-neg-${local.backend_app_name}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.backend_app.name
  }
}

# backend service
resource "google_compute_region_backend_service" "region_backend_frontend" {
  name                  = "region-backend-frontend-${var.project_name}"
  provider              = google-beta
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
  provider        = google-beta
  region          = var.region
  default_service = google_compute_region_backend_service.region_backend_frontend.id
}

# HTTP target proxy
resource "google_compute_region_target_http_proxy" "http_proxy_backend" {
  name     = "http-proxy-${local.backend_app_name}"
  provider = google-beta
  region   = var.region
  url_map  = google_compute_region_url_map.url_map_backend.id
}

# forwarding rule
resource "google_compute_forwarding_rule" "forwarding_rule_backend" {
  name                  = "forwarding-rule-${local.backend_app_name}"
  depends_on            = [google_compute_subnetwork.proxy_only_subnet]
  provider              = google-beta
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
resource "google_cloud_run_service" "backend_app" {
  name     = local.backend_app_name
  location = var.region

  traffic {
    percent         = 100
    latest_revision = true
    tag             = local.backend_app_name
  }

  template {
    spec {
      containers {
        // Git repository: https://github.com/silvermx/generic-webapp-backend
        image = "${var.repo_name}/${local.backend_app_name}:latest"
        ports {
          container_port = 8080
        }
        env {
          name  = "DATABASE_NAME"
          value = local.db_name
        }
        env {
          name  = "INSTANCE_CONNECTION_NAME"
          value = "${var.project_id}:${var.region}:${local.db_instance_name}"
        }
        env {
          name  = "DATABASE_USERNAME"
          value = local.db_user_name
        }
        env {
          name  = "DATABASE_PASSWORD"
          value = var.db_user_pass
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "terraform"
        "run.googleapis.com/ingress"            = "internal-and-cloud-load-balancing"
      }
    }
  }
  autogenerate_revision_name = true
}


data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "public-access-tmp-backed" {
  location    = var.region
  project     = var.project_id
  service     = google_cloud_run_service.backend_app.name
  policy_data = data.google_iam_policy.noauth.policy_data
}