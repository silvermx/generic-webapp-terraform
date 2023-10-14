### Network ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// External Load Balancer
//url: https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples
module "lb_http_serverless_negs" {
  name    = "lb-http-serverless-negs"
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
          group = google_compute_region_network_endpoint_group.serverless_neg.id
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

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  provider              = google-beta
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.frontend_app.name
  }
}

// Interal Loand Balancer


### Front Application - vau.js --------------------------------------------------------------------------------------------------------------------------------------------------------------
resource "google_cloud_run_service" "frontend_app" {
  name     = local.frontend_app_name
  location = var.region

  template {
    spec {
      containers {
        image = "${var.repo_name}/${local.frontend_app_name}:latest"
        ports {
          container_port = 8080
        }
      }
    }
  }
  metadata {
    annotations = {
      # For valid annotation values and descriptions, see
      # https://cloud.google.com/sdk/gcloud/reference/run/deploy#--ingress
      "run.googleapis.com/ingress" = "all"
    }
  }
  autogenerate_revision_name = true
  depends_on = [google_cloudbuild_trigger.frontend-build-trigger, google_cloud_run_service.backend_app]
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.frontend_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

### Back Application - Java  ----------------------------------------------------------------------------------------------------------------------------------------------------------------
//source: https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-java-service
resource "google_cloud_run_service" "backend_app" {
  name     = local.backend_app_name
  location = var.region

  template {
    spec {
      containers {
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
      }
    }
  }
  autogenerate_revision_name = true
  depends_on = [google_cloudbuild_trigger.backend-build-trigger]
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

### Database  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "instance" {
  name             = local.db_instance_name
  region           = var.region
  database_version = "MYSQL_5_7"
  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
  }
  //Allow to destroy the db only for testing (false)
  deletion_protection = "false"
}

resource "google_sql_database" "database" {
  name     = local.db_name
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = local.db_user_name
  instance = google_sql_database_instance.instance.name
  password = var.db_user_pass
}