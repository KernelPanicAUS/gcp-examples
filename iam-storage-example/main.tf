terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>3.0"
    }
  }
}

provider "google" {
  # Configuration options
  region  = var.region
  project = var.project_id
}

variable "project_id" {}
variable "region" {
  default = "europe-west3"
}

/**************************************/
// SA
/**************************************/
resource "google_service_account" "shushu" {
  account_id = "shushu"
}

resource "google_service_account" "popo" {
  account_id = "popooo"
}

resource "google_service_account_iam_member" "shushu_allow_impersonate" {
  member             = "user:xxxxxx@gmail.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  service_account_id = google_service_account.shushu.name
}

resource "google_service_account_iam_member" "popo_allow_impersonate" {
  member             = "serviceAccount:${google_service_account.shushu.email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  service_account_id = google_service_account.popo.name
}

resource "google_service_account_iam_member" "popo_allow_shushu_to_impersonate" {
  member             = "serviceAccount:${google_service_account.shushu.email}"
  role               = "roles/iam.serviceAccountUser"
  service_account_id = google_service_account.popo.name
}

/******************************************/
// GS Bucket
/******************************************/
resource "google_storage_bucket" "popo_bucket" {
  name                        = "popo-has-a-secret-bucket"
  location                    = "EUROPE-WEST3"
  uniform_bucket_level_access = true
}

resource "google_project_iam_custom_role" "protecc_popo_bucket" {
  permissions = [
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.list",
    "storage.multipartUploads.abort",
    "storage.multipartUploads.create",
    "storage.multipartUploads.listParts"
  ]
  role_id = "popo_bucket_custom_role"
  title   = "PopoBucketCustomRole"
}

resource "google_storage_bucket_iam_binding" "popo-role-binding" {
  bucket  = google_storage_bucket.popo_bucket.name
  members = ["serviceAccount:${google_service_account.popo.email}"]
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.protecc_popo_bucket.role_id}"
  condition {
    expression = "resource.name == \"projects/_/buckets/${google_storage_bucket.popo_bucket.name}\" || resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.popo_bucket.name}\")"
    title      = "restrict_resource_bucket_name"
  }
}