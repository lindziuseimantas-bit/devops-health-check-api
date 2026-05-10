# DevOps Candidate Homework: Serverless Health Check API

## Submission

Public GitHub repository URL: `https://github.com/lindziuseimantas-bit/devops-health-check-api`

Replace the placeholder above with the final public repository URL before submitting the homework form.

## Overview

This repository deploys a serverless health check API on AWS using Terraform and GitHub Actions.

The API exposes `/health` through API Gateway. Requests must include an API key and a JSON body with a top-level `payload` key. Valid requests invoke a Python Lambda function, which logs the incoming event, writes the request details to DynamoDB, and returns:

```json
{ "status": "healthy", "message": "Request processed and saved." }
```

Invalid JSON or a missing `payload` key returns HTTP `400`.

## Architecture

```text
Client
  |
  | x-api-key + JSON body containing payload
  v
API Gateway REST API
  |-- API key authentication
  |-- usage plan throttling and monthly quota
  |-- request model validation for payload
  v
Lambda function in private VPC subnets
  |
  | DynamoDB gateway VPC endpoint
  v
DynamoDB requests table encrypted with customer-managed KMS key
```

## Repository structure

```text
.
├── .github/workflows/terraform.yml       # CI/CD pipeline
├── bootstrap/                            # One-time Terraform for remote state and GitHub OIDC deploy roles
├── lambda/                               # Python Lambda source code
└── terraform/                            # Application Terraform
    ├── environments/staging.tfvars
    ├── environments/prod.tfvars
    └── modules/
        ├── apigateway/
        ├── dynamodb/
        ├── kms/
        ├── lambda/
        └── vpc/
```

## Prerequisites

Install locally if you want to run Terraform outside GitHub Actions:

* Terraform `>= 1.6.0`
* AWS CLI v2
* Python 3.12 for local Lambda checks
* An AWS account with permissions to create the bootstrap resources
* A public GitHub repository containing this code

## Required GitHub configuration

The workflow uses GitHub OIDC instead of long-lived AWS access keys.

Create GitHub environments named:

* `staging`
* `prod`

Add the following repository or environment variables in GitHub:

|Variable|Scope|Example|Purpose|
|-|-|-|-|
|`AWS\_REGION`|repository or each environment|`eu-central-1`|AWS region used by the workflow|
|`TF\_STATE\_BUCKET`|repository or each environment|`my-unique-health-check-tf-state`|S3 bucket for Terraform state|
|`TF\_STATE\_LOCK\_TABLE`|repository or each environment|`health-check-terraform-locks`|DynamoDB table for Terraform locking|
|`TF\_STATE\_KMS\_KEY\_ID`|repository or each environment|`abcd-1234...`|KMS key ID for state encryption|
|`AWS\_DEPLOY\_ROLE\_ARN`|each environment|`arn:aws:iam::<account-id>:role/staging-health-check-deployment-role`|OIDC role assumed by GitHub Actions|

Recommended production protection:

1. Go to **Settings -> Environments -> prod**.
2. Add required reviewers.
3. This makes the `prod` deployment job wait for manual approval before running.

## One-time bootstrap

The `bootstrap/` Terraform creates:

* encrypted S3 bucket for Terraform remote state
* encrypted DynamoDB table for Terraform state locking
* GitHub OIDC provider
* dedicated deployment IAM roles for `staging` and `prod`

Create a bootstrap tfvars file:

```bash
cp bootstrap/example.tfvars bootstrap/local.tfvars
```

Edit `bootstrap/local.tfvars`:

```hcl
aws\_region            = "eu-central-1"
github\_owner          = "YOUR\_GITHUB\_OWNER"
github\_repo           = "devops-health-check-api"
state\_bucket\_name     = "YOUR\_GLOBALLY\_UNIQUE\_STATE\_BUCKET"
state\_lock\_table\_name = "health-check-terraform-locks"
```

Apply bootstrap once from an admin workstation:

```bash
cd bootstrap
terraform init
terraform apply -var-file="local.tfvars"
```

Then copy the outputs into GitHub variables:

```bash
terraform output
```

If `token.actions.githubusercontent.com` already exists as an IAM OIDC provider in the AWS account, import it instead of creating a duplicate provider.

## Deploying staging from GitHub Actions

To trigger a staging deployment manually:

1. Push this repository to GitHub.
2. Open **Actions -> serverless-health-check-ci-cd**.
3. Select **Run workflow**.
4. Set `environment` to `staging`.
5. Set `apply` to `true`.
6. Run the workflow.

The same workflow also deploys `staging` automatically on pushes to `main` that modify `terraform/`, `lambda/`, or the workflow file.

## Deploying prod

Production deploys are manual:

1. Open **Actions -> serverless-health-check-ci-cd**.
2. Select **Run workflow**.
3. Set `environment` to `prod`.
4. Set `apply` to `true`.
5. Approve the `prod` environment deployment if required reviewers are configured.

## Local deployment example

Application Terraform uses per-environment tfvars files:

```bash
cd terraform
mkdir -p .build
terraform init \\
  -backend-config="bucket=$TF\_STATE\_BUCKET" \\
  -backend-config="key=health-check/staging/terraform.tfstate" \\
  -backend-config="region=eu-central-1" \\
  -backend-config="dynamodb\_table=$TF\_STATE\_LOCK\_TABLE" \\
  -backend-config="encrypt=true" \\
  -backend-config="kms\_key\_id=$TF\_STATE\_KMS\_KEY\_ID"

terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

## Testing the `/health` endpoint

After deployment, get the endpoint URL:

```bash
cd terraform
terraform output -raw health\_endpoint\_url
```

Get the API key ID:

```bash
terraform output -raw api\_key\_id
```

Retrieve the API key value:

```bash
aws apigateway get-api-key \\
  --api-key "$(terraform output -raw api\_key\_id)" \\
  --include-value \\
  --query value \\
  --output text
```

Call the API:

```bash
API\_URL="$(terraform output -raw health\_endpoint\_url)"
API\_KEY="REPLACE\_WITH\_API\_KEY\_VALUE"

curl -i -X POST "$API\_URL" \\
  -H "Content-Type: application/json" \\
  -H "x-api-key: $API\_KEY" \\
  -d '{"payload":{"source":"manual-test","message":"hello"}}'
```

Expected success response:

```json
{ "status": "healthy", "message": "Request processed and saved." }
```

Invalid request example:

```bash
curl -i -X POST "$API\_URL" \\
  -H "Content-Type: application/json" \\
  -H "x-api-key: $API\_KEY" \\
  -d '{"missing":"payload"}'
```

Expected result: HTTP `400`.

## CI/CD pipeline behavior

The workflow has two jobs.

### `validate-and-scan`

Runs on pull requests, pushes to `main`, and manual dispatches:

* `terraform fmt -check -recursive`
* `terraform init -backend=false`
* `terraform validate`
* Trivy IaC security scan against the Terraform code
* `pip-audit` dependency scan for `lambda/requirements.txt`

The security scan runs before Terraform apply.

### `deploy`

Runs on pushes to `main` and manual dispatches, but not pull requests:

* assumes the environment-specific AWS deployment role using GitHub OIDC
* initializes Terraform remote state in S3
* creates the Lambda deployment ZIP with Terraform's `archive\_file` provider
* runs `terraform plan`
* runs `terraform apply` when `APPLY=true`
* prints Terraform outputs after apply

## Security controls implemented

|Requirement|Implementation|
|-|-|
|DynamoDB SSE|DynamoDB table uses `server\_side\_encryption` with a customer-managed KMS key|
|IaC security scanning|Trivy config scan runs before apply|
|Lambda dependency scanning|`pip-audit` scans `lambda/requirements.txt`|
|Least privilege Lambda role|Lambda role can only write to the specific table, write to its log group, decrypt its KMS key, and manage VPC ENIs required by Lambda VPC execution|
|Dedicated deployment role|Bootstrap creates one GitHub OIDC deployment role per environment|
|No long-lived AWS secrets|GitHub Actions uses OIDC and `aws-actions/configure-aws-credentials`|
|API throttling|API Gateway usage plan and method settings set rate and burst limits|
|API key auth|API Gateway requires `x-api-key` for `/health`|
|Input validation in Lambda|Lambda returns `400` when the JSON body is invalid or lacks `payload`|
|API Gateway request validation|REST API model validates that JSON requests include `payload` before invoking Lambda|
|Lambda VPC|Lambda runs in private subnets with a DynamoDB gateway VPC endpoint|
|KMS CMK|Customer-managed KMS key encrypts DynamoDB, Lambda environment variables, and Lambda log group|

## IAM wildcard note

The Lambda execution policy uses `Resource: "\*"` only for EC2 network-interface operations required for Lambda VPC execution, because those EC2 actions do not support strict resource-level scoping in the way needed by Lambda. KMS key policies also use `Resource: "\*"` as required by KMS key policy semantics. The deployment role similarly uses broader resource scopes only where AWS create/list APIs do not support narrower ARNs reliably; otherwise it scopes by environment-specific resource names such as `staging-health-check-\*` and `prod-health-check-\*`.

## Design choices and assumptions

* API Gateway REST API was selected instead of HTTP API because REST API supports request validators, API keys, and usage plans.
* Both `GET` and `POST` methods are created for `/health`. The intended test command uses `POST` because the security requirement mandates a JSON body containing `payload`.
* Terraform modules are split by concern: KMS, VPC, DynamoDB, Lambda, and API Gateway.
* The deployment role is bootstrapped separately because GitHub Actions needs an AWS role before it can deploy the application stack.
* DynamoDB uses on-demand billing to avoid capacity planning for this exercise.
* Lambda reserved concurrency is set to `10` to add another blast-radius limit behind API Gateway throttling.
* No NAT gateway is created. The Lambda reaches DynamoDB through a DynamoDB gateway VPC endpoint.

## Suggested atomic commit history

Use clear commits that show the development flow:

```text
chore: add repository scaffold and Lambda health handler
chore: add Terraform modules for KMS DynamoDB VPC Lambda and API Gateway
chore: add environment tfvars for staging and prod
chore: add GitHub Actions CI CD workflow with security scans
chore: add bootstrap Terraform for OIDC deployment roles and remote state
chore: document deployment and testing workflow
```

## Cleanup

Destroy an environment with:

```bash
cd terraform
terraform destroy -var-file="environments/staging.tfvars"
```

Destroy bootstrap resources only after all environment state has been destroyed and the state bucket is empty.

