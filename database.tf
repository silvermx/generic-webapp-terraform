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
  depends_on          = [google_project_service.sqladmin_api]
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

### Store the database configuration as a secret --------------------------------------------------------------------------------------------------------------------------------------------
// source: https://github.com/terraform-google-modules/terraform-docs-samples/blob/main/run/connect_cloud_sql/main.tf

data "google_project" "project" {
}

# Store db_name

resource "google_secret_manager_secret" "db_name" {
  secret_id = "db_name"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "db_name_version_data" {
  secret = google_secret_manager_secret.db_name.name
  secret_data = local.db_name
}

resource "google_secret_manager_secret_iam_member" "db_name_access" {
  secret_id = google_secret_manager_secret.db_name.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_secret.db_name]
}

# Store db_user_name

resource "google_secret_manager_secret" "db_user_name" {
  secret_id = "db_user_name"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "db_user_name_version_data" {
  secret = google_secret_manager_secret.db_user_name.name
  secret_data = local.db_user_name
}

resource "google_secret_manager_secret_iam_member" "db_user_name_access" {
  secret_id = google_secret_manager_secret.db_user_name.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_secret.db_user_name]
}

# Store db_user_pass
resource "google_secret_manager_secret" "db_user_pass" {
  secret_id = "db_user_pass"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "db_user_pass_version_data" {
  secret = google_secret_manager_secret.db_user_pass.name
  secret_data = var.db_user_pass
}

resource "google_secret_manager_secret_iam_member" "db_user_pass_access" {
  secret_id = google_secret_manager_secret.db_user_pass.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [google_secret_manager_secret.db_user_pass]
}