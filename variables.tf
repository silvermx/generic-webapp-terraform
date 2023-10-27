### Global Configuration --------------------------------------------------------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  default = "terraformv2-403117"
}

variable "project_name" {
  default = "generic-webapp"
}

variable "region" {
  default = "us-central1"
}

### Frontend Application Configuration ------------------------------------------------------------------------------------------------------------------------------------------------------
locals {
  frontend_app_name = "${var.project_name}-frontend"
}

### Backend Application Configuration ------------------------------------------------------------------------------------------------------------------------------------------------------
locals {
  backend_app_name = "${var.project_name}-backend"
}

### Database config  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
locals {
  db_instance_name = "${var.project_name}-instance"
  db_name          = "${var.project_name}-db"
  db_user_name     = "${var.project_name}-user"
}

//TODO: (optional) to pass the pass in the command line
variable "db_user_pass" {
  default = "VeY.}@/2SV'Q[VfuD85#."
}

### GitHub Repo  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

variable "repo_name" {
  default = "silvermx"
}