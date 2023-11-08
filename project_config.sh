#!/bin/sh
# Sets the project id
export PROJECT_ID=terraform-$RANDOM
# Creates the new project
gcloud projects create $PROJECT_ID --name=terraform-project

# Sets the Cloud Shell to the new project
gcloud config set project $PROJECT_ID

# Creates a new service account
gcloud iam service-accounts create terraform --display-name="terraform"

# Sets the roles required for the new service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageAdmin"

# Enable the apis required (it may take some minutes)
# Some apis require to enable billing before to activate, terraform will help with that
gcloud services enable cloudresourcemanager.googleapis.cosm
gcloud services enable serviceusage.googleapis.com
gcloud services enable networkmanagement.googleapis.com
gcloud services enable sqladmin.googleapis.com