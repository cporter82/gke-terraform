resource "castai_node_template" "template" {
  for_each = var.templates

  name             = each.value.name
  configuration_id = var.node_configurations[each.value.configuration_id_name]
  cluster_id       = var.cluster_id
  is_default       = each.value.is_default
  is_enabled       = each.value.is_enabled
  should_taint     = each.value.should_taint
  custom_instances_enabled = each.value.custom_instances_enabled

  custom_labels = each.value.custom_labels

  dynamic "custom_taints" {
   for_each = each.value.custom_taints
    content {
      key    = custom_taints.value.key
      value  = custom_taints.value.value
      effect = custom_taints.value.effect
    }
  }

  constraints {
    on_demand          = each.value.constraints.on_demand
    spot               = each.value.constraints.spot
    use_spot_fallbacks = each.value.constraints.use_spot_fallbacks
    fallback_restore_rate_seconds = each.value.constraints.fallback_restore_rate_seconds
    min_cpu            = each.value.constraints.min_cpu
    max_cpu            = each.value.constraints.max_cpu
    min_memory         = each.value.constraints.min_memory
    max_memory         = each.value.constraints.max_memory

    dynamic "instance_families" {
      for_each = [each.value.constraints.instance_families]
      content {
        exclude = instance_families.value.exclude != null ? instance_families.value.exclude : []
        include = instance_families.value.include != null ? instance_families.value.include : []
      }
    }
    dynamic "dedicated_node_affinity" {
    for_each = each.value.constraints.dedicated_node_affinity

    content {
      az_name        = dedicated_node_affinity.value.az_name
      instance_types = dedicated_node_affinity.value.instance_types
      name           = dedicated_node_affinity.value.name

      dynamic "affinity" {
        for_each = dedicated_node_affinity.value.affinity

        content {
          key      = affinity.value.key
          operator = affinity.value.operator
          values   = affinity.value.values
        } #content for affinity
      } #affinity
    } #content for dedicated_node_affinity 
  } #dedicated_node_affinity
  } #constraints
}
