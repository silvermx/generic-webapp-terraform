terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.82.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.50, < 5.0"
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
  credentials = "terraform-399314-sa-key.json"
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  zone        = "us-central1-a"
  credentials = "terraform-399314-sa-key.json"
}