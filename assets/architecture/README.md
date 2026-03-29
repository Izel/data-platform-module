# GCP Data Platform — Architecture Guide

This document describes the architectural decisions, patterns, and design principles behind the GCP Data Platform Terraform module.
For setup and usage instructions, see the main [README](../README.md).

---

## Table of Contents

1. [Platform Overview](#1-platform-overview)
2. [Architectural Patterns](#2-architectural-patterns)
3. [Module Architecture](#3-module-architecture)
4. [Medallion Data Architecture](#4-medallion-data-architecture)
5. [Security Architecture](#5-security-architecture)
6. [Environment Strategy](#6-environment-strategy)
7. [Deployment Order and Dependencies](#7-deployment-order-and-dependencies)
8. [Design Decisions](#8-design-decisions)

---

## 1. Platform Overview

This platform provisions the foundational GCP infrastructure required to run secure, scalable, and observable data pipelines. It is not a pipeline itself — it is the **foundation on which pipelines run**.

```
┌─────────────────────────────────────────────────────────────────┐
│                      4. DATA CONSUMERS                          │
│              Looker Studio · BI Tools · ML Models               │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Ingestion
┌──────────────────────────▼──────────────────────────────────────┐
│                    3. ANALYTICS LAYER                           │
│              BigQuery — analytics dataset                       │
│         Aggregated, business-ready, query-optimised             │
└──────────────────────────┬──────────────────────────────────────┘
                           │  transformation
┌──────────────────────────▼──────────────────────────────────────┐
│                     2. CURATED LAYER                            │
│         BigQuery — curated dataset · GCS processed bucket       │
│           Cleaned, validated, deduplicated, enriched            │
└──────────────────────────┬──────────────────────────────────────┘
                           │  transformation
┌──────────────────────────▼──────────────────────────────────────┐
│                      1. RAW LAYER                               │
│           BigQuery — raw dataset · GCS raw bucket               │
│         Data lands exactly as ingested — no modifications       │
└──────────────────────────┬──────────────────────────────────────┘
                           │  ingestion
┌──────────────────────────▼──────────────────────────────────────┐
│                      0. DATA SOURCES                            │
│          APIs · Pub/Sub Streams · Databases · Files             │
└─────────────────────────────────────────────────────────────────┘
```

The platform provisions all infrastructure represented by the ***middle three*** layers. Data sources and consumers are external to this module.

---

## 2. Architectural Patterns

This platform combines three distinct architectural patterns. Understanding each one separately is important for explaining the design in technical discussions.

### 2.1 Medallion Architecture (Data Organisation)

The medallion architecture — also known as the Delta Architecture or multi-hop architecture — organises data into progressive quality layers. Each layer increases the trustworthiness and business-readiness of the data.

| Layer | Also Known As | GCP Resources | Purpose |
|---|---|---|---|
| **Raw** | Bronze | `*_raw` BQ dataset, `*-raw` GCS bucket | Immutable copy of source data |
| **Curated** | Silver | `*_curated` BQ dataset, `*-processed` GCS bucket | Validated, cleaned, joined |
| **Analytics** | Gold | `*_analytics` BQ dataset | Aggregated, business-ready |

**Why this matters:** Raw data is never modified. If a transformation introduces a bug, you can always reprocess from the raw layer without re-ingesting from the source. This makes the platform resilient and auditable — a hard requirement in regulated industries such as financial services.

### 2.2 Defence in Depth (Security)

Defence in depth is a security architecture principle in which multiple independent security controls protect data at every layer. No single control failure exposes the data.

```
┌───────────────────────────────────────────────────────┐
│  Layer 1 — Network        VPC · Private Google Access│
│  Layer 2 — Identity       Least-privilege IAM · SAs  │
│  Layer 3 — Encryption     CMEK · KMS key rotation    │
│  Layer 4 — Secrets        Secret Manager             │
│  Layer 5 — Observability  Logging · Monitoring       │
└───────────────────────────────────────────────────────┘
```

Each layer is implemented by a dedicated Terraform module, making controls independently auditable and replaceable.

### 2.3 Infrastructure as Code Platform Pattern

The platform follows the IaC platform pattern — reusable, composable Terraform modules consumed by multiple environments via a thin environment wrapper. This is the model used by platform engineering teams in large organisations.

```
modules/          ← reusable, environment-agnostic
  apis/
  networking/
  iam/
  security/
  storage/
  bigquery/
  monitoring/

environments/     ← thin wrappers — only tfvars differ
  dev/
  pre/            
  prod/
```

The result is that `dev`, `pre`, and `prod` are guaranteed to be architecturally identical. Only variable values (project IDs, CIDR ranges, key rotation periods) differ between environments.

---

## 3. Module Architecture
**Infrastructure as Code Platform Pattern**  implemented via the Terraform module structure (networking → IAM → security → storage → compute). This is a platform engineering pattern, not a data pattern. This is what separates a Data Platform from a Data Engineering.  

Each module encapsulates a single infrastructure concern. Modules are deliberately decoupled — they communicate only through input variables and outputs, never through shared state.

```
                    ┌─────────────┐
                    │    apis     │  ← All modules depend on this
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ apis_ready  │  ← Time sleep waiting for APIs propagation
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼───────┐
   │  networking │  │     iam     │  │  security   │
   │  VPC · DNS  │  │  SAs · IAM  │  │  KMS · SM   │
   └─────────────┘  └──────┬──────┘  └──────┬──────┘
                           │                │
                    ┌──────▼────────────────▼──────┐
                    │           storage            │
                    │   GCS buckets · lifecycle    │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │           bigquery           │
                    │  datasets · IAM · encryption │
                    └──────────────┬───────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │          monitoring          │
                    │  log sinks · alert policies  │
                    └──────────────────────────────┘
```

### Module Responsibilities

| Module | Provisions | Key Design Choice |
|---|---|---|
| `apis` | Enables required GCP APIs | `disable_on_destroy = false` prevents accidental data loss |
| `networking` | VPC, subnets, firewall rules | Private Google Access enabled — no public IPs on data resources |
| `iam` | Service accounts, IAM bindings | One SA per workload; no primitive roles |
| `security` | KMS key rings + keys, Secret Manager secrets | Separate KMS keys for GCS and BigQuery; 90-day rotation |
| `storage` | GCS buckets (raw, processed, tf-state) | CMEK + lifecycle policies + versioning on all buckets |
| `bigquery` | BQ datasets (raw, curated, analytics) | CMEK + dataset-level IAM; table expiry in dev |
| `monitoring` | Log sinks, alert policies | Logs exported to BigQuery for long-term analysis |

---

## 4. Medallion Data Architecture

### Data Flow

```
            Source Data
                │
                │  ingestion (Dataflow · Pub/Sub · batch)
                ▼
┌───────────────────────────────────┐
│  RAW LAYER                        │
│  GCS: {project}-{env}-raw/        │
│  BQ:  {env}_raw                   │
│                                   │
│  • Exact copy of source           │
│  • No schema enforcement          │
│  • Immutable once written         │
│  • 30-day lifecycle → Nearline    │
│  • 90-day lifecycle → Coldline    │
└───────────────┬───────────────────┘
                │
                │  transformation (Dataflow · dbt · SQL)
                ▼
┌───────────────────────────────────┐
│  CURATED LAYER                    │
│  GCS: {project}-{env}-processed/  │
│  BQ:  {env}_curated               │
│                                   │
│  • Schema enforced                │
│  • Nulls handled                  │
│  • Duplicates removed             │
│  • Data types cast and validated  │
│  • PII masked or tokenised        │
└───────────────┬───────────────────┘
                │
                │  aggregation (SQL · dbt · Dataform)
                ▼
┌───────────────────────────────────┐
│  ANALYTICS LAYER                  │
│  BQ: {env}_analytics              │
│                                   │
│  • Pre-aggregated metrics         │
│  • Business logic applied         │
│  • Optimised for dashboard reads  │
│  • Read-only for analysts         │
└───────────────┬───────────────────┘
                │
                ▼
        Looker Studio · BI Tools · ML Models
```

### Why Raw Data Is Never Modified

A core principle of the medallion architecture is that raw data is immutable. This provides:

- **Reprocessability** — any transformation bug can be fixed by reprocessing from raw, without re-ingesting from the source system
- **Auditability** — regulators and auditors can always see the original data as it was received
- **Debugging** — data quality issues can be traced back to their origin

This is particularly important for the financial services and media sectors, where data lineage is a regulatory requirement.

---

## 5. Security Architecture
**Defence in Depth Security Pattern** implemented by forcing CMEK usage on every storage layer, least-privilege service accounts per workload, Private Google Access, Secret Manager for credentials, KMS key rotation. Each layer adds an independent security control. 

### Encryption

All data at rest is encrypted using **Customer-Managed Encryption Keys (CMEK)** via Cloud KMS. This means Google holds the infrastructure but the organisation controls the encryption keys.

```
┌─────────────────────────────────────────────────────┐
│                  Cloud KMS                          │
│                                                     │
│  keyring: {env}-data-platform-keyring               │
│  ├── key: {env}-gcs-cmek      → GCS buckets         │
│  └── key: {env}-bigquery-cmek → BQ datasets         │
│                                                     │
│  Rotation period: 90 days (prod) · 30 days (dev)    │
└─────────────────────────────────────────────────────┘
```

Separate keys for GCS and BigQuery means that a key compromise affects only one storage system, not both.

### Identity and Access

Three dedicated service accounts follow the **least-privilege principle** — each SA holds only the permissions required for its specific workload:

```
data-pipeline-sa   → Dataflow worker · BQ editor · GCS object admin · Secret accessor
bq-analyst-sa      → BQ data viewer · BQ job user (read-only)
tf-deployer-sa     → Used by Cloud Build CI/CD only
```

No primitive roles (`roles/owner`, `roles/editor`) are assigned anywhere. The `iam_validator.py` script in `/scripts` audits this automatically.

### Secrets

No credentials are stored in Terraform state or `.tfvars` files. All secrets are managed via **Secret Manager**, with secret shells provisioned by Terraform and values set out-of-band by operations teams.

---

## 6. Design Decisions

### Why separate KMS keys for GCS and BigQuery?
A single compromised key would expose all storage. Separate keys limit the blast radius of a key compromise to one storage system.

### Why `disable_on_destroy = false` on APIs?
Disabling a GCP API with existing resources silently deletes those resources. In a production environment, this would be catastrophic. APIs are cheap to keep enabled and expensive to accidentally disable.

### Why three service accounts instead of one?
Analysts should never have write access to raw data. Pipeline SAs should never have admin access. The principle of least privilege requires separate identities per workload. If a pipeline SA is compromised, the blast radius is limited to pipeline operations only.

### Why is `force_destroy = false` hardcoded for the Terraform state bucket?
The state bucket is the source of truth for all infrastructure. Accidentally destroying it would make all managed resources untrackable by Terraform. This is one of the few cases where a hardcoded safety value is preferable to a configurable variable.

### Why export logs to BigQuery instead of Cloud Storage?
BigQuery enables SQL queries directly on log data — useful for audit queries, cost analysis, and compliance reporting. Cloud Storage is cheaper for archival but not queryable without additional tooling.




