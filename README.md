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

## Architecture

[architecture diagram]

## Module Structure

data-platform-module/
├── modules/
│   ├── networking/
│   ├── iam/
│   ├── storage/
│   ├── bigquery/
│   ├── security/
│   └── monitoring/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── README.md

## Key Design Decisions

* All storage encrypted with Customer-Managed Encryption Keys (CMEK)
* Service accounts follow least-privilege principle
* Private Google Access enabled — no public IPs on data resources
* Environment promotion via shared modules with per-env tfvars
* Secrets never stored in state — managed via Secret Manager

## Environments

[explain dev/staging/prod tfvars pattern]

## Usage

[terraform init / plan / apply commands]

## Future Improvements

* Add Dataplex for data governance
* Add VPC Service Controls for data exfiltration prevention
