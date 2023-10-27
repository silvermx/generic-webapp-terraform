### Network ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "vpc-subnet"
  region        = var.region
  network       = google_compute_network.internal_lb_network.id
  ip_cidr_range = "10.10.10.0/28"
}


// External Load Balancer
// source: https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples
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
}

### Front Application - vau.js --------------------------------------------------------------------------------------------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "frontend_app" {
  name         = local.frontend_app_name
  location     = var.region
  launch_stage = "BETA"
  template {
    containers {
      // Git repository: https://github.com/silvermx/generic-webapp-frontend
      image = "${var.repo_name}/${local.frontend_app_name}:latest"
      ports {
        container_port = 8080
      }
      env {
        name  = "VUE_APP_INTERNAL_LB_URL"
        value = "${google_compute_forwarding_rule.forwarding_rule_backend.ip_address}:8080"
      }
    }
    vpc_access {
      network_interfaces {
        network    = google_compute_network.internal_lb_network.name
        subnetwork = google_compute_subnetwork.internal_lb_subnet.name
        tags       = ["web-app"]
      }
      egress = "ALL_TRAFFIC"
    }
  }
  depends_on = [google_compute_forwarding_rule.forwarding_rule_backend]
}



resource "google_cloud_run_service_iam_member" "public-access" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_v2_service.frontend_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}


// The vpc access was created with the version 2 so I migrated 
/*
resource "google_cloud_run_service" "frontend_app" {
  name     = local.frontend_app_name
  location = var.region

  traffic {
    percent         = 100
    latest_revision = true
    tag             = local.frontend_app_name
  }
  template {
    spec {
      containers {
        image = "${var.repo_name}/${local.frontend_app_name}:latest"
        ports {
          container_port = 8080
        }
        env {
          name  = "VUE_APP_INTERNAL_LB_URL"
          value = "${google_compute_forwarding_rule.forwarding_rule_backend.ip_address}:8080"
        }
      }
    }
  }
  metadata {
    annotations = {
      # For valid annotation values and descriptions, see
      # https://cloud.google.com/sdk/gcloud/reference/run/deploy#--ingress
      "run.googleapis.com/ingress" = "all"
      "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.vpc_connector.id
      "run.googleapis.com/vpc-access-egress" : "all-traffic"
    }
  }
  autogenerate_revision_name = true
  depends_on                 = [google_compute_forwarding_rule.forwarding_rule_backend, google_vpc_access_connector.vpc_connector]
}
*/

/* Change this for the direct vpc
resource "google_vpc_access_connector" "vpc_connector" {
  name          = "vpc-connector"
  subnet {
    name = google_compute_subnetwork.vpc_subnet.name
  }
  //machine_type = "e2-standard-4"
}

*/