data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = var.tags
}

module "KP" {
  source = "../../modules/KP"
  public_key = var.public_key
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.all_subnet_ids
  node_subnet_ids = module.vpc.private_subnet_ids

  node_groups = var.node_groups
  tags        = var.tags
}

# Grants the IAM user your GitHub Actions secrets authenticate as (and
# anything else listed in var.extra_admin_principal_arns) full cluster-admin
# access, so kubectl in the deploy-app job can actually talk to the cluster.
module "iam" {
  source = "../../modules/iam"

  cluster_name = module.eks.cluster_name
  admin_principal_arns = distinct(concat(
    [data.aws_caller_identity.current.arn],
    var.extra_admin_principal_arns
  ))
  readonly_principal_arns = var.readonly_principal_arns
  tags                    = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  repositories = var.ecr_repositories
  tags         = var.tags
}
