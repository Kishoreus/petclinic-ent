variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets the control plane ENIs live in (usually public + private)"
}

variable "node_subnet_ids" {
  type        = list(string)
  description = "Subnets worker nodes launch into (usually private only)"
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "enable_irsa" {
  type    = bool
  default = true
}

# Parameterized so you can add more node groups later (e.g. a "spot" group,
# a GPU group, a batch-workload group) just by adding entries here - no
# module code changes needed.
variable "node_groups" {
  description = "Map of EKS managed node group configs"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
    min_size       = number
    max_size       = number
    desired_size   = number
    labels         = optional(map(string), {})
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      labels         = { role = "worker" }
    }
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
