# About data-platform-module

A **GCP** production-ready, reusable **Terraform module** that provisions a secure, well-architected GCP data platform following Google's enterprise **best practices**. Designed for organisations migrating to or scaling on GCP.

## Platform Capabilities

| Capability         | GCP Service                        |
|--------------------|------------------------------------|
| Networking         | VPC, Subnets, Private Google Access|
| Data Warehouse     | BigQuery (CMEK, column security)   |
| Object Storage     | GCS (lifecycle policies, CMEK)     |
| Secret Management  | Secret Manager + KMS               |
| Identity & Access  | Service Accounts, IAM bindings     |
| Observability      | Cloud Logging, Monitoring, Alerts  |
| CI/CD              | Cloud Build                        |

---

## Module Structure

data-platform-module\
├── scripts\
├── modules\
│   ├── networking\
│   ├── iam\
│   ├── storage\
│   ├── bigquery\
│   ├── security\
│   └── monitoring\
├── environments\
│   ├── dev\
│   ├── staging\
│   └── prod\
└── README.md

---
 
## Architecture
 
```
environments/
  dev | staging | prod
        │
        ▼
  ┌─────────────────────────────────────────┐
  │           modules/                      │
  │  networking → iam → security            │
  │       ↓         ↓        ↓              │
  │   storage   bigquery  monitoring        │
  └─────────────────────────────────────────┘
```
 
All modules are independently reusable and composable. Each environment (`dev`, `staging`, `prod`) references the same modules with environment-specific variable overrides via `terraform.tfvars`.
 
---

## Key Design Decisions

- **CMEK everywhere** All GCS buckets and BigQuery datasets encrypted with Customer Managed Encryption Keys via Cloud KMS.
- **Least-privilege IAM** Dedicated service accounts per workload and no primitive roles (`Owner`, `Editor`).
- **Private by default** Private Google Access enabled. The data resources have no public IPs.
- **Secrets never in state** All credentials managed via Secret Manager and no plain text secrets in `.tfvars`, environment variables or state files.
- **Environment parity** Dev, staging, and prod use identical module composition, the differences are tfvars only.
 
---
 
## Prerequisites
 
- Terraform >= 1.5.0
- Google Cloud SDK (`gcloud`)
- A GCP project with billing enabled
- A GCS bucket for Terraform remote state
 
---

## Usage
 
### 1. Clone the repository
 
```bash
git clone https://github.com/Izel/data-platform-module.git
cd data-platform-module
```
 
### 2. Authenticate with GCP
 
```bash
gcloud auth login
gcloud config set project <YOUR_PROJECT_ID>
```
 
### 3. Configure your environment
 
Edit the relevant `terraform.tfvars` file:
 
```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project-specific values
```

### 4. Setup
1. [Create a project](https://developers.google.com/workspace/guides/create-project) via web console
2. Associate the project to a [billing account](https://docs.cloud.google.com/billing/docs/how-to/modify-project).
3. Create a `terraform.tfvars` file for each environment folder.
```
├── environments\
│   ├── dev\
│      ├── terraform.tfvars  
│   ├── staging\
│      ├── terraform.tfvars  
│   ├── prod\
│      ├── terraform.tfvars  
```

4. Copy the variables definition below for each `terraform.tfvars` and modify it according to your values:
```terraform
# The project id  created in GCP. It must be associated to a billing account
project_id = "<YOUR_PROJECT_ID>" # p.e "my-data-infra-project"

# Region for the project resources location.
region = "<YOUR_SELECTED_REGION>" # p.e "europe-west2"

# The current deployment environment 
environment = "<YOUR_ENVIRONMENT>" # p.e "dev"

# The Subnet IP addres range and network mask
subnet_cidr = "<YOUR_SUBNET_IP_AND_MASK>" # p.e "10.0.0.0/24"

# KMS key rotation — shorter in dev for testing. Defined in Seconds
key_rotation_period = "<YOUR_KEY_ROTATION_PERIOD>" # p.e "2592000s" wich is 30 days in secons

# Monitoring — leave empty in dev if no notification channels set up
notification_channel_ids = []
```
> [!IMPORTANT] 
> Hashicorp recommends to **avoid pushing** the `terraform.tfvars` file to public repository (Github, GitLab, BitBucket, etc.).

---

### 5. Deploy
 
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```
 
---

## Environment Promotion
 
Environments share identical module composition. To promote from dev → staging → prod:
 
```bash
# Validate dev
cd environments/dev && terraform plan
 
# Promote to staging
cd environments/staging && terraform plan && terraform apply
 
# Promote to prod
cd environments/prod && terraform plan && terraform apply
```
 
---
 
## Python Companion Scripts
 
The `/scripts` directory contains Python tooling for platform validation and auditing:
 
| Script                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| `iam_validator.py`            | Audits IAM bindings for least-privilege violations   |
| `bucket_compliance_checker.py`| Validates GCS bucket security configuration          |
| `secret_rotation.py`          | Rotates secrets in Secret Manager, logs to BigQuery  |
| `tfvars_validator.py`         | CLI tool to validate tfvars completeness per env     |
| `platform_health_report.py`   | Queries Cloud Monitoring and writes health to BQ     |
 
See `/scripts/README.md` for usage instructions.
 
---
 
## Future Improvements
 
- Add [Dataplex](https://cloud.google.com/dataplex) for data governance and cataloguing.
- Add VPC Service Controls to prevent data exfiltration.
- Add Terraform test framework (`terraform test`).
- Integrate with Cloud Build for automated plan/apply on PR.
 
---
 
## Related Projects
 
- [crypto-prices](https://github.com/Izel/crypto-prices) — Real-time streaming pipeline (Pub/Sub → Dataflow → BigQuery) that uses this platform module for infrastructure provisioning
- [duck-pipeline-dev](https://github.com/Izel/duck-pipeline-dev) — Batch ETL pipeline on Cloud Run, provisioned using patterns from this module
