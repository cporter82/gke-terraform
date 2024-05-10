# Node Templates Module

This module is used to create and manage node templates for Kubernetes clusters.

## Usage

To use this module, provide a map of node template configurations. Each configuration should specify details such as 
the name, labels, taints, and constraints.

### Variables

- `templates`: A map of node template configurations.

### Outputs

- `node_template_ids`: The IDs of the created node templates.

Example usage:

```hcl
module "node_templates" {
  source    = "./modules/node_templates"
  templates = var.templates
}
