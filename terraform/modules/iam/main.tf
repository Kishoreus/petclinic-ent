# Explicitly grants IAM principals access to the EKS cluster using the
# modern EKS Access Entries API (replaces manually editing the aws-auth
# ConfigMap). This is what lets `kubectl`, run by the same IAM user your
# GitHub Actions secrets authenticate as, actually talk to the cluster.

resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = var.cluster_name
  principal_arn = each.value
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = var.cluster_name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}

resource "aws_eks_access_entry" "readonly" {
  for_each = toset(var.readonly_principal_arns)

  cluster_name  = var.cluster_name
  principal_arn = each.value
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "readonly" {
  for_each = toset(var.readonly_principal_arns)

  cluster_name  = var.cluster_name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.readonly]
}
