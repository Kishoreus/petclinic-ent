# Wraps the community EKS module so the rest of the codebase only ever talks
# to modules/eks - if the underlying module version or implementation changes,
# nothing outside this file needs to know.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  enable_irsa = var.enable_irsa

  # Required so IAM principals (like our CI user) can be granted cluster
  # access via the modern EKS Access Entries API.
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = false

  # ---------------------------------------------------------
  # Allow SSH access to EKS worker nodes through the
  # EC2 Instance Connect Endpoint (EICE)
  # ---------------------------------------------------------
  node_security_group_additional_rules = {
    eice_ssh = {
      description              = "Allow SSH from EC2 Instance Connect Endpoint"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = var.eice_security_group_id
    }
  }

  # ---------------------------------------------------------
  # EKS Managed Node Groups
  # ---------------------------------------------------------
  eks_managed_node_groups = {
    for name, ng in var.node_groups : name => {
      min_size       = ng.min_size
      max_size       = ng.max_size
      desired_size   = ng.desired_size
      instance_types = ng.instance_types
      capacity_type  = ng.capacity_type

      subnet_ids = var.node_subnet_ids

      # EC2 key pair used for SSH access
      key_name = ng.ssh_key_name

      iam_role_additional_policies = ng.iam_role_additional_policies

      labels = ng.labels
    }
  }

  tags = var.tags
}
