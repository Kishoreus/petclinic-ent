# PetClinic Microservices on AWS EKS — Terraform + GitHub Actions

## ⚠️ Cost note (read first)
- EKS control plane: **not free tier**, flat ~$0.10/hr (~$73/mo) whenever the cluster exists.
- 2x t3.medium worker nodes: ~$0.0416/hr each = not free-tier eligible either (free tier only covers t2.micro/t3.micro, which is too small for ~7 Spring Boot services).
- NAT Gateway: ~$0.045/hr + data.
- **This is why you have a destroy pipeline** — spin the cluster up when working on it, tear it down when you're not. Roughly: a full day up/down costs a few dollars, not the full monthly rate.

## Repo layout
```
terraform/
  modules/
    vpc/          -> VPC, subnets, IGW, NAT (parameterized: single or per-AZ NAT)
    eks/           -> EKS cluster + parameterized node groups map
    ecr/           -> ECR repos, driven by a list variable
  environments/
    dev/           -> wires the modules together for this environment
      main.tf       -> module calls only, no hardcoded resources
      variables.tf   -> variable definitions
      terraform.tfvars -> ALL the actual values you'd tune live here
      backend.tf     -> remote state config (bucket/table injected by CI)
      provider.tf
      outputs.tf
k8s/          -> Deployments/Services for each PetClinic microservice
.github/workflows/
  create-infra.yml            -> provisions everything + deploys the app + backs up state to repo
  destroy-infra.yml           -> manual teardown, run whenever you're done for the session
  scheduled-auto-destroy.yml  -> runs nightly automatically as a credit-safety net
terraform/state-backup/       -> read-only backup copy of state, committed by create-infra.yml
```

## Terraform state: two copies, one source of truth
- **Primary (authoritative)**: S3 bucket `petclinic-tfstate-<account-id>` + DynamoDB lock table `petclinic-tf-lock`. This is what `terraform init`/`plan`/`apply`/`destroy` actually read and write, with locking so concurrent runs can't corrupt it.
- **Backup (read-only)**: after every successful `terraform apply`, the `create-infra.yml` pipeline runs `terraform state pull` and commits the result to `terraform/state-backup/terraform.tfstate.backup` in this repo. This exists purely so you have a fallback if the S3 bucket is ever lost — **never edit or `init` against this file directly**.

## Three pipelines
| Pipeline | Trigger | What it does |
|---|---|---|
| `create-infra.yml` | Manual (`workflow_dispatch`) | Provisions VPC/EKS/ECR, deploys PetClinic, backs up state to repo |
| `destroy-infra.yml` | Manual (`workflow_dispatch`) | Tears down k8s workloads + all AWS infra, right now, on demand |
| `scheduled-auto-destroy.yml` | Automatic, nightly at 23:30 UTC (also manually runnable) | Checks if the cluster still exists; if so, tears it down the same safe way. This is the safety net for "I forgot to destroy it and burned credits overnight." Adjust or remove the `cron` line in the workflow file to change/disable the schedule. |

### Why modules
- **`modules/`** holds reusable, environment-agnostic building blocks. You won't touch these often.
- **`environments/dev/terraform.tfvars`** is the one file you edit for day-to-day tuning: node instance types/sizes, NAT strategy, ECR repo list, region, etc.
- **Adding a new environment** (e.g. `prod`) later: copy `environments/dev` to `environments/prod`, adjust `terraform.tfvars` (e.g. `single_nat_gateway = false`, bigger `node_groups`), give it its own `backend.tf` key (e.g. `petclinic/prod/terraform.tfstate`), and point a new pair of GitHub Actions jobs at that folder. No module code changes needed.
- **Adding a node group** (e.g. spot instances for cost savings, or a GPU group later): add an entry to the `node_groups` map in `terraform.tfvars` — the `eks` module already loops over whatever you put there.
- **Adding a microservice**: add its name to `ecr_repositories` in `terraform.tfvars`, and add a manifest in `k8s/`.

## One-time setup (before first run)

1. **AWS credentials**: create an IAM user with programmatic access and (for simplicity in phase 1) `AdministratorAccess`, or a scoped policy covering EC2/VPC/EKS/IAM/ECR/S3/DynamoDB. Scope this down later.

2. **GitHub repo secrets** (Settings → Secrets and variables → Actions):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_ACCOUNT_ID` (your 12-digit account ID — used to make the state bucket name globally unique)

3. **Push this repo to GitHub.**

4. **kubectl/aws-cli** locally (optional, only if you want to interact outside CI): install `awscli`, `kubectl`, `terraform` CLI.

## Running it

- **Create everything**: Actions tab → "Create PetClinic Infra" → Run workflow → type `create` → Run.
  This: creates the S3 backend/lock table (first run only) → `terraform apply` (VPC + EKS + node group + ECR) → deploys all PetClinic k8s manifests → prints the LoadBalancer URL for `api-gateway`.

- **Destroy everything**: Actions tab → "Destroy PetClinic Infra" → Run workflow → type `destroy` → Run.
  This deletes the `petclinic` namespace (and its LoadBalancer) first, waits for AWS to clean up the ELB, then runs `terraform destroy`. Doing it in this order avoids a common failure mode: a Kubernetes-created ELB blocking VPC/subnet deletion.

## Access the app
```bash
aws eks update-kubeconfig --region us-east-1 --name petclinic-eks
kubectl -n petclinic get svc api-gateway
# open the EXTERNAL-IP hostname in a browser
```

## What's NOT in phase 1 (intentionally, per your ask to complete basics first)
- OIDC-based GitHub→AWS auth (using static keys for now — swap in later, it's more secure)
- RDS instead of in-memory/H2 DB in each service
- Ansible (not needed yet since EKS/node groups are fully managed — Ansible becomes relevant if you add self-managed EC2, e.g. a Jenkins box)
- Jenkins (you can add a Jenkins-on-EC2 module later if you want an internal CI in addition to GitHub Actions)
- HPA, cluster autoscaler, monitoring (Prometheus/Grafana), multi-env workspaces, least-privilege IAM

Ask me when you're ready and I'll help layer these in for the "enterprise" phase.
