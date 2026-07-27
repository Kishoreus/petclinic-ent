# ---- Everything you're likely to tune lives here. ----
# To add a "prod" environment later: copy this whole environments/dev folder
# to environments/prod, change these values (bigger nodes, multi-NAT, etc.),
# and give it its own backend key in backend.tf.

aws_region      = "us-east-1"
project_name    = "petclinic"
cluster_name    = "petclinic-eks"
<<<<<<< HEAD
# As of mid-2026, supported EKS versions are 1.33-1.36 (1.33 exits standard
# support July 29, 2026). Check https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions-standard.html
# before you apply if this has been sitting a while - AWS drops old versions.
=======
>>>>>>> 29b301dfabbf839a19ee8c3f6d499c1d538a844b
cluster_version = "1.34"

vpc_cidr             = "10.0.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

# true = 1 shared NAT gateway (cheaper, fine for dev/free-tier)
# false = 1 NAT per AZ (HA, for prod)
single_nat_gateway = true

# Your AWS account currently restricts launches to free-tier-eligible types
# only (t2.micro/t3.micro) - see the note in README about lifting this later.
# t3.micro = 1 vCPU / 1GB RAM, so we run more nodes to have enough combined
# capacity for the ~7 PetClinic services (each requests ~384Mi).
node_groups = {
  default = {
    instance_types = ["t3.micro"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 4
    desired_size   = 3
    labels         = { role = "worker" }
  }
}

ecr_repositories = [
  "config-server",
  "discovery-server",
  "api-gateway",
  "customers-service",
  "vets-service",
  "visits-service",
  "admin-server",
]

environment = "dev"

tags = {
  Project     = "petclinic"
  ManagedBy   = "terraform"
  Environment = "dev"
}
