terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  # Bucket/table names are injected by CI via -backend-config so the same
  # code works for dev/prod just by pointing at a different key.
  backend "s3" {
    key     = "petclinic/dev/terraform.tfstate"
    encrypt = true
  }
}
