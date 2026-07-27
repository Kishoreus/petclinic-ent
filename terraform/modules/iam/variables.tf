variable "cluster_name" {
  description = "EKS cluster name to grant access to"
  type        = string
}

variable "admin_principal_arns" {
  description = "IAM user/role ARNs that should get full cluster-admin access via EKS Access Entries (e.g. the IAM user your GitHub Actions pipelines authenticate as)"
  type        = list(string)
}

variable "readonly_principal_arns" {
  description = "IAM user/role ARNs that should get read-only cluster access. Add ARNs here later for teammates who just need to view, not change, the cluster."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
