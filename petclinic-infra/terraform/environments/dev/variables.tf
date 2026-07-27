variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "petclinic"
}

variable "cluster_name" {
  type    = string
  default = "petclinic-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
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

variable "ecr_repositories" {
  type = list(string)
  default = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "vets-service",
    "visits-service",
    "admin-server",
  ]
}

variable "extra_admin_principal_arns" {
  description = "Additional IAM user/role ARNs to grant EKS cluster-admin access, beyond whichever identity Terraform itself runs as. Add teammates' IAM ARNs here later."
  type        = list(string)
  default     = []
}

variable "readonly_principal_arns" {
  description = "IAM user/role ARNs to grant read-only EKS cluster access."
  type        = list(string)
  default     = []
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "petclinic"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}
