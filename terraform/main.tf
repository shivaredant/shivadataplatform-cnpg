locals {
  # Read the intent file
  raw_content = file("${path.module}/../Datastore.yaml")

  # Regex to extract values after the '#' and ':'
  team_name     = trimspace(regex("TeamName:\\s*(.*)", local.raw_content)[0])
  cluster_name  = trimspace(regex("ClusterName:\\s*(.*)", local.raw_content)[0])
  size_input    = trimspace(regex("Size:\\s*(.*)", local.raw_content)[0])
  ds_type       = trimspace(regex("DStype:\\s*(.*)", local.raw_content)[0])
  service_level = trimspace(regex("ServiceLevel:\\s*(.*)", local.raw_content)[0])

  # Logic Mapping for 2026 POC
  size_map = {
    "S" = "256Mi"
    "M" = "260Mi" 
    "L" = "270Mi" 
  }

  replica_map = {
    "Silver" = 1
    "Gold"   = 2
  }

  # Guard rail: Ensure only postgres is processed
  is_postgres = lower(local.ds_type) == "postgres" ? true : false
}

# Generate the Manifest ONLY if DStype is postgres
resource "local_file" "k8s_manifest" {
  count    = local.is_postgres ? 1 : 0
  filename = "${path.module}/../manifests/generated_db.yaml"
  content  = <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ${lower(local_cluster_name)}
  namespace: ${lower(local_team_name)}
spec:
  instances: ${local.replica_map[local_service_level]}
  storage:
    size: ${local.size_map[local_size_input]}
EOF
}
