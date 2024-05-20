data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = var.cluster_name
  location = var.cluster_region
  project  = var.project_id
}

data "local_file" "node_configurations" {
  for_each = fileset("${path.module}/data/node_configurations", "*.json")
  filename = "${path.module}/data/node_configurations/${each.value}"
}

# load all of the possible node templatess from the ./data directory
locals {
  json_files           = fileset("${path.module}/data", "*.json")
  json_objects         = [for file in local.json_files : jsondecode(file("${path.module}/data/${file}"))]
  node_templates_json  = merge(local.json_objects...)
  #node_templates_json = jsondecode(file("${path.module}/data/node_templates.json"))
  selected_templates   = { for name, template in local.node_templates_json : name => template if contains(var.selected_template_names, name) }
  node_configurations  = { for name, file in data.local_file.node_configurations : trimprefix(basename(file.filename), ".json") => jsondecode(file.content) }
  #selected_node_configurations = { for name, config in local.node_configurations : name => config if contains(var.selected_node_configuration_names, name) }
}

provider "castai" {
  api_url   = var.castai_api_url
  api_token = var.castai_api_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth.0.cluster_ca_certificate)
  }
}

# Configure GKE cluster connection using CAST AI gke-cluster module.
module "castai-gke-iam" {
  source = "castai/gke-iam/castai"

  project_id       = var.project_id
  gke_cluster_name = var.cluster_name
}

module "node_templates" {
  source              = "./modules/node_templates"
  templates           = local.selected_templates
  node_configurations = module.castai-gke-cluster.castai_node_configurations
  cluster_id          = module.castai-gke-cluster.cluster_id
  depends_on          = [module.castai-gke-cluster]
}

module "castai-gke-cluster" {
  source = "castai/gke-cluster/castai"

  api_url                    = var.castai_api_url
  castai_api_token           = var.castai_api_token
  grpc_url                   = var.castai_grpc_url
  wait_for_cluster_ready     = true
  project_id                 = var.project_id
  gke_cluster_name           = var.cluster_name
  gke_cluster_location       = var.cluster_region
  gke_credentials            = module.castai-gke-iam.private_key
  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
  default_node_configuration = module.castai-gke-cluster.castai_node_configurations["default"]

  node_configurations = local.node_configurations
  /*{
    default = {
      disk_cpu_ratio = 25
      subnets        = var.subnets
      tags           = var.tags
    }

    test_node_config = {
      disk_cpu_ratio    = 10
      subnets           = var.subnets
      tags              = var.tags
      max_pods_per_node = 40
      #disk_type         = "pd-ssd",
      #network_tags      = ["dev"]
    }

  }*/

  autoscaler_policies_json = <<-EOT
{
  "enabled": false,
  "unschedulablePods": {
    "enabled": false
  },
  "nodeDownscaler": {
    "enabled": false,
    "emptyNodes": {
      "enabled": false
    },
    "evictor": {
      "aggressiveMode": false,
      "cycleInterval": "5m10s",
      "dryRun": false,
      "enabled": false,
      "nodeGracePeriodMinutes": 10,
      "scopedMode": false
    }
  }
}
  EOT

  depends_on = [data.google_container_cluster.my_cluster, module.castai-gke-iam]
}