### Network ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

resource "google_compute_network" "internal_lb_network" {
  provider                = google-beta
  name                    = "internal-lb-network"
  auto_create_subnetworks = false
  depends_on = [google_project_service.networkmanagement_api]
}

resource "google_compute_subnetwork" "internal_lb_subnet" {
  provider                 = google-beta
  name                     = "internal-lb-subnet"
  region                   = var.region
  network                  = google_compute_network.internal_lb_network.id
  ip_cidr_range            = "10.1.2.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "proxy_only_subnet" {
  name          = "proxy-only-subnet"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  region        = var.region
  network       = google_compute_network.internal_lb_network.id
  ip_cidr_range = "10.129.0.0/23"
}
