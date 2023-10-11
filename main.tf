
### Network Infrastructure

/**
resource "google_compute_network" "vpc_network"{
    name = "vpc-network"
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_network" {
  name = "subnet-network"
  ip_cidr_range = "10.1.0.0/24"
  region = var.region
  network = google_compute_network.vpc_network.id
}
**/

### Cloud Storage  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------



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
        image = "us-central1-docker.pkg.dev/${var.project_id}/${local.frontend_repo_name}/${local.frontend_app_name}:latest"
        //image = "us-docker.pkg.dev/cloudrun/container/hello"
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
        image = "us-central1-docker.pkg.dev/${var.project_id}/${local.backend_repo_name}/${local.backend_app_name}:latest"
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

### MemoryStore - Redis ---------------------------------------------------------------------------------------------------------------------------------------------------------------------


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

### Cloud Build  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// Frontend Application Configuration
resource "google_artifact_registry_repository" "frontend-repo" {
  location      = var.region
  repository_id = local.frontend_repo_name
  format        = "DOCKER"
}

resource "google_cloudbuild_trigger" "frontend-build-trigger" {
  name     = "${local.frontend_app_name}-trigger"
  location = var.region

  trigger_template {
    branch_name = "master"
    repo_name   = local.frontend_app_name
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "us-central1-docker.pkg.dev/${var.project_id}/${local.frontend_repo_name}/${local.frontend_app_name}:$COMMIT_SHA", "-t", "us-central1-docker.pkg.dev/${var.project_id}/${local.frontend_repo_name}/${local.frontend_app_name}:latest", "."]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "us-central1-docker.pkg.dev/${var.project_id}/${local.frontend_repo_name}/${local.frontend_app_name}:$COMMIT_SHA"]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "us-central1-docker.pkg.dev/${var.project_id}/${local.frontend_repo_name}/${local.frontend_app_name}:latest"]
    }
  }
}

// Backend Application Configuration
resource "google_artifact_registry_repository" "backend-repo" {
  location      = var.region
  repository_id = local.backend_repo_name
  format        = "DOCKER"

  //docker_config {
  //  immutable_tags = true
  //}
}

resource "google_cloudbuild_trigger" "backend-build-trigger" {
  name     = "${local.backend_app_name}-trigger"
  location = var.region

  trigger_template {
    branch_name = "master"
    repo_name   = local.backend_app_name
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "us-central1-docker.pkg.dev/${var.project_id}/${local.backend_repo_name}/${local.backend_app_name}:$COMMIT_SHA", "-t", "us-central1-docker.pkg.dev/${var.project_id}/${local.backend_repo_name}/${local.backend_app_name}:latest", "."]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "us-central1-docker.pkg.dev/${var.project_id}/${local.backend_repo_name}/${local.backend_app_name}:$COMMIT_SHA"]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "us-central1-docker.pkg.dev/${var.project_id}/${local.backend_repo_name}/${local.backend_app_name}:latest"]
    }
  }
}