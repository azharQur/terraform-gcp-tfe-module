# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

resource "random_id" "account" {
  count = var.existing_service_account_id == null ? 1 : 0
  # 30 bytes ensures that enough characters are generated to satisfy the service account ID requirements, regardless of
  # the prefix.
  byte_length = 30
  prefix      = "${var.namespace}-tfe-"
}

resource "google_service_account" "main" {
  count = var.existing_service_account_id == null ? 1 : 0
  # Limit the string used to 30 characters.
  account_id   = substr(random_id.account[count.index].dec, 0, 30)
  display_name = "TFE"
  description  = "Service Account used by Terraform Enterprise."
}

data "google_service_account" "main" {
  count      = var.existing_service_account_id == null ? 0 : 1
  account_id = var.existing_service_account_id
}

resource "google_service_account_key" "key" {
  service_account_id = local.service_account.name
}

resource "google_project_iam_member" "log_writer" {
  count   = var.existing_service_account_id == null ? 1 : 0
  member  = local.member
  role    = "roles/logging.logWriter"
  project = "prj-c-tfe-ba9a"
}

resource "google_secret_manager_secret_iam_member" "license_secret" {
  //count     = var.enable_airgap ? 0 : 1
  member    = local.member
  role      = "roles/secretmanager.secretAccessor"
  secret_id = var.tfe_license_secret_id
}

resource "google_secret_manager_secret_iam_member" "ca_certificate_secret" {
  count = var.ca_certificate_secret_id == null || var.enable_airgap ? 0 : 1

  member    = local.member
  role      = "roles/secretmanager.secretAccessor"
  secret_id = var.ca_certificate_secret_id
}

resource "google_secret_manager_secret_iam_member" "ssl_certificate_secret" {
  count = var.ssl_certificate_secret == null || var.enable_airgap ? 0 : 1

  member    = local.member
  role      = "roles/secretmanager.secretAccessor"
  secret_id = var.ssl_certificate_secret
}

resource "google_secret_manager_secret_iam_member" "ssl_private_key_secret" {
  count = var.ssl_private_key_secret == null || var.enable_airgap ? 0 : 1

  member    = local.member
  role      = "roles/secretmanager.secretAccessor"
  secret_id = var.ssl_private_key_secret
}
