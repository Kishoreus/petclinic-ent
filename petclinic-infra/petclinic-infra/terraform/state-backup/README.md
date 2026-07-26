# State backup (read-only)

`terraform.tfstate.backup` here is committed automatically by the
`create-infra.yml` pipeline after every successful `terraform apply`.

**This is a backup only.** The authoritative state lives in the S3 backend
(`petclinic-tfstate-<account-id>`) with DynamoDB locking. Never point
`terraform init` at this file directly, and never edit it by hand — if you
need to recover state, copy this file's contents back into the S3 object
and re-run `terraform init`.
