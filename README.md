## Terraform Project

This Terraform project creates a simple three-tier website architecture on Google Cloud Platform. The architecture consists of a web server, a database server, and a load balancer.

### Requirements

* Terraform 1.2.0 or higher
* Google Cloud Platform account

### Usage

To deploy the architecture, run the following command:

Use code with caution. Learn more
terraform apply


This will create the necessary resources in Google Cloud Platform.

To destroy the architecture, run the following command:

terraform destroy

This will delete all of the resources that were created by Terraform.

Inputs
This Terraform project uses the following inputs:

region: The region where the resources will be created.
machine_type: The machine type for the web server and database server.
database_name: The name of the database.

Outputs
This Terraform project outputs the following information:

project_id: The project id in gcp
project_name: The project name, this will be use to named the different components like the repositories
region: The region to deploy all the componentes, us-central1 is used by default

db_user_pass: The data base password, this variable can be change as your convenience or pass it as parameter, it has a value by default

Example Usage
To deploy the architecture to the us-central1 region using the and with the database name my_database, run the following command:

terraform apply -var project_id=<PROJECT_ID> -var project_name=<PROJECT_NAME> -var db_user_pass=<DB_USER_PASS>

Note: to avoid passing the parameters in the command line change the values in the variables.tf file.

Once the deployment is complete, you can access the website by accessing the frontend Cloud Run application.


### Support
If you have any questions or problems with this Terraform project, please feel free to open an issue on GitHub (https://github.com/silvermx).

