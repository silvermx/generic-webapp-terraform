terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.84.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.84.0"
    }
  }
  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-lb-http:serverless_negs/v9.2.0"
  }

  provider_meta "google-beta" {
    module_name = "blueprints/terraform/terraform-google-lb-http:serverless_negs/v9.2.0"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = "us-central1-a"
  credentials = "terraform-sa-key.json"
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = "us-central1-a"
  credentials = "terraform-sa-key.json"
}

# Enable Resource Manager API
resource "google_project_service" "resourcemanager_api" {
  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

# Enable Service Usage API
resource "google_project_service" "cloudserviceusage_api" {
  service                    = "serviceusage.googleapis.com"
  disable_dependent_services = true
}

# Enable Compute API
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable Network Manager API
resource "google_project_service" "networkmanagement_api" {
  service            = "networkmanagement.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Run API
resource "google_project_service" "cloudrun_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Enable Sql Manager API
resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager_api" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "time_sleep" "gcp_wait_crm_api_enabling" {
  depends_on = [google_project_service.resourcemanager_api]
  create_duration = "1m"
}