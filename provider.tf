terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
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
  credentials = "${var.project_id}-sa-key.json"
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = "us-central1-a"
  credentials = "${var.project_id}-sa-key.json"
}


//Enable google  apis
module "project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.4"

  project_id  = var.project_id

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "networkmanagement.googleapis.com",
  ]
  disable_services_on_destroy = false
}