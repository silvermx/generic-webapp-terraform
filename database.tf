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