variable "templates" {
  description = "A map of node template configurations to be applied."
  type = map(object({
    name             : string
    configuration_id : string
    configuration_id_name : string
    cluster_id       : string
    is_default       : bool
    is_enabled       : bool
    should_taint     : bool
    custom_instances_enabled : bool
    custom_labels    : map(string)
    custom_taints    : list(object({
      key    : string
      value  : string
      effect : string
    }))
    constraints : object({
      on_demand : bool
      spot : bool
      use_spot_fallbacks : bool
      enable_spot_diversity : bool
      spot_diversity_price_increase_limit_percent : number
      fallback_restore_rate_seconds : number
      min_cpu : number
      max_cpu : number
      min_memory : number
      max_memory : number
      instance_families : object({
        exclude : list(string)
        include : list(string)
      })
      compute_optimized : bool
      storage_optimized : bool
    })
  }))
  default = {}
}

variable "node_configurations" {
  type = any
  description = "Map of node configuration IDs and their attributes from the CAST AI GKE cluster module."
}

variable "cluster_id" {
  type = string
  description = "The ID of the cluster to which the node templates should be applied."
}
