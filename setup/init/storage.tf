resource "null_resource" "storage_sa_creation" {
  provisioner "local-exec" {
    command = <<EOT
      curl -X GET -H "Authorization: Bearer ${local.access_token}" \
        "https://storage.googleapis.com/storage/v1/projects/${local.project}/serviceAccount"
    EOT
  }
  depends_on = [google_project_service.apis]
}
