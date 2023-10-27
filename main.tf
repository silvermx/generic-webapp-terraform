### Network ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "internal_lb_network" {
  provider                = google-beta
  name                    = "internal-lb-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "internal_lb_subnet" {
  provider                 = google-beta
  name                     = "internal-lb-subnet"
  region                   = var.region
  network                  = google_compute_network.internal_lb_network.id
  ip_cidr_range            = "10.1.2.0/24"
  private_ip_google_access = true
}


resource "google_compute_firewall" "allow_8080" {
  name    = "allow-8080"
  network = google_compute_network.internal_lb_network.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_tags = ["web-app"]
}

resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "proxy-only-subnet"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  region        = var.region
  network       = google_compute_network.internal_lb_network.id
  ip_cidr_range = "10.129.0.0/23"
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