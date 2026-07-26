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

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  repositories = var.ecr_repositories
  tags         = var.tags
}
