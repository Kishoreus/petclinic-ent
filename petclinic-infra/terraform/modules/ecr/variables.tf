variable "project_name" {
  type = string
}

variable "repositories" {
  description = "List of service names to create an ECR repo for. Add a new microservice here later and it just appears."
  type        = list(string)
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

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
