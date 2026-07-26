variable "project_name" {
  type        = string
  description = "Prefix used on all resource names"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name - used for the kubernetes.io/cluster/<name> subnet tags"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to spread subnets across"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "true = 1 NAT gateway shared by all AZs (cheap, dev/free-tier). false = 1 NAT per AZ (HA, more cost) - toggle this when you move to the enterprise phase."
}

variable "tags" {
  type    = map(string)
  default = {}
}
