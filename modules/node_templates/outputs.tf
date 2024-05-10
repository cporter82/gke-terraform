output "node_template_ids" {
  value = { for name, template in castai_node_template.template : name => template.id }
  description = "The IDs of the created node templates."
}
