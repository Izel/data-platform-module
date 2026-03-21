# Platform Scripts

Python companion tooling for validating, auditing, and operating the GCP data platform.

## Setup

```bash
pip install -r ../requirements.txt
```

## Scripts

### `iam_validator.py` — IAM Least-Privilege Auditor

Audits all IAM bindings in a GCP project and flags violations:
- Primitive roles (`roles/owner`, `roles/editor`, `roles/viewer`) at project level
- Service accounts with high-risk roles
- Public access bindings (`allUsers`, `allAuthenticatedUsers`)

```bash
# Text report
python iam_validator.py --project YOUR_PROJECT_ID

# JSON output (pipe to file or other tools)
python iam_validator.py --project YOUR_PROJECT_ID --output json > report.json
```

Exits with code `1` if non-compliant — safe to use in CI/CD pipelines.

---

### Coming soon

| Script                        | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| `bucket_compliance_checker.py`| Validates GCS bucket security configuration          |
| `secret_rotation.py`          | Rotates secrets in Secret Manager, logs to BigQuery  |
| `tfvars_validator.py`         | CLI tool to validate tfvars completeness per env     |
| `platform_health_report.py`   | Queries Cloud Monitoring, writes health to BigQuery  |
