locals {
  # 1. Read the file (Ensure Datastores.yaml is in the Repo Root)
  raw_content = file("${path.module}/../Datastores.yaml")

  # 2. Regex: Use non-capturing groups or clear indexing
  # Added lower() here to make the logic robust for 2026 standards
  team_name     = trimspace(regex("TeamName:\\s*(.*)", local.raw_content)[0])
  cluster_name  = trimspace(regex("ClusterName:\\s*(.*)", local.raw_content)[0])
  size_input    = trimspace(regex("Size:\\s*(.*)", local.raw_content)[0])
  ds_type       = trimspace(regex("DStype:\\s*(.*)", local.raw_content)[0])
  service_level = trimspace(regex("ServiceLevel:\\s*(.*)", local.raw_content)[0])

  # 3. Logic Mapping
  size_map = {
    "S" = "256Mi"
    "M" = "260Mi" 
    "L" = "270Mi" 
  }

  replica_map = {
    "Silver" = 1
    "Gold"   = 2
  }

  # 4. Guard rail
  is_postgres = lower(local.ds_type) == "postgres"
}

# 5. Generate Manifest
resource "local_file" "k8s_manifest" {
  count    = local.is_postgres ? 1 : 0
  # Note: Ensure the 'manifests' directory exists or Terraform might error
  #filename = "${path.module}/../manifest/cnpg/generated_newdb.yaml"
  filename = "/tmp/generate_soficodb.yaml"
  
  # FIX: Reference locals correctly using 'local.<name>'
  content  = <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: ${lower(local.cluster_name)}
  namespace: ${lower(local.team_name)}
spec:
  instances: ${local.replica_map[local.service_level]}
  storage:
    size: ${local.size_map[local.size_input]}
EOF
}
