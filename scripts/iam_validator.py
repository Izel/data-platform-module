"""
iam_validator.py
────────────────
Audits IAM bindings in a GCP project and flags violations of the
least-privilege principle.

What it checks:
  - Primitive roles (Owner, Editor, Viewer) assigned at project level
  - Service accounts with roles/owner or roles/editor
  - allUsers / allAuthenticatedUsers bindings (public access)

Usage:
  pip install google-cloud-resource-manager google-auth
  python iam_validator.py --project YOUR_PROJECT_ID
  python iam_validator.py --project YOUR_PROJECT_ID --output json
"""

import argparse
import json
import sys
from dataclasses import dataclass, field
from typing import Optional

try:
    from google.cloud import resourcemanager_v3
    from google.iam.v1 import iam_policy_pb2
    import google.auth
except ImportError:
    print(
        "Missing dependencies. Run:\n"
        "  pip install google-cloud-resource-manager google-auth"
    )
    sys.exit(1)


@dataclass
class Violation:
    """Represents a single IAM policy violation."""

    severity: str  # Values: "HIGH", "MEDIUM", "LOW"
    role: str
    member: str
    reason: str


@dataclass
class AuditResult:
    """Aggregated result of an IAM audit run."""

    project_id: str
    total_bindings: int = 0
    violations: list = field(default_factory=list)

    @property
    def violation_count(self) -> int:
        return len(self.violations)

    @property
    def is_compliant(self) -> bool:
        high_severity = [v for v in self.violations if v.severity == "HIGH"]
        return len(high_severity) == 0


# Main validator class


class IAMValidator:
    """
    Audits GCP project IAM bindings for least-privilege violations.
    """

    # Class-level constants — shared across all instances
    PRIMITIVE_ROLES = {
        "roles/owner",
        "roles/editor",
        "roles/viewer",
    }

    HIGH_RISK_ROLES = {
        "roles/owner",
        "roles/editor",
        "roles/iam.securityAdmin",
        "roles/resourcemanager.projectIamAdmin",
    }

    PUBLIC_MEMBERS = {
        "allUsers",
        "allAuthenticatedUsers",
    }

    def __init__(self, project_id: str):
        """
        Initialise the validator with a GCP project ID.

        Args:
            project_id: The GCP project ID to audit (not project number)
        """
        self.project_id = project_id
        self._client = resourcemanager_v3.ProjectsClient()
        self._result = AuditResult(project_id=project_id)

    def _get_iam_policy(self) -> Optional[iam_policy_pb2.Policy]:
        """
        Fetch the IAM policy for the project.

        Returns:
            The IAM policy object, or None if fetch fails.

        Note the leading underscore — Python convention for private methods.
        External code should call run_audit() not this directly.
        """
        try:
            resource = f"projects/{self.project_id}"
            request = resourcemanager_v3.GetIamPolicyRequest(resource=resource)
            return self._client.get_iam_policy(request=request)

        except Exception as e:
            # Catch broad exceptions from the API and re-raise with context
            raise RuntimeError(
                f"Failed to fetch IAM policy for project '{self.project_id}': {e}"
            ) from e

    def _check_primitive_roles(self, role: str, member: str) -> Optional[Violation]:
        """Check if a binding uses a primitive (overly broad) role."""
        if role in self.PRIMITIVE_ROLES:
            severity = "HIGH" if role in ("roles/owner", "roles/editor") else "MEDIUM"
            return Violation(
                severity=severity,
                role=role,
                member=member,
                reason=(
                    f"Primitive role '{role}' grants broad permissions. "
                    "Replace with a predefined or custom role scoped to the resource."
                ),
            )
        return None

    def _check_service_account_over_privilege(
        self, role: str, member: str
    ) -> Optional[Violation]:
        """Flag service accounts assigned high-risk roles."""
        is_service_account = member.startswith("serviceAccount:")
        if is_service_account and role in self.HIGH_RISK_ROLES:
            return Violation(
                severity="HIGH",
                role=role,
                member=member,
                reason=(
                    f"Service account has high-risk role '{role}' at project level. "
                    "Service accounts should use resource-scoped bindings."
                ),
            )
        return None

    def _check_public_access(self, role: str, member: str) -> Optional[Violation]:
        """Flag any bindings that grant access to allUsers or allAuthenticatedUsers."""
        if member in self.PUBLIC_MEMBERS:
            return Violation(
                severity="HIGH",
                role=role,
                member=member,
                reason=(
                    f"Role '{role}' is granted to '{member}'. "
                    "This makes the resource publicly accessible. Remove immediately."
                ),
            )
        return None

    def run_audit(self) -> AuditResult:
        """
        Run the full IAM audit and return a structured result.

        This is the main public method. It:
          1. Fetches the IAM policy
          2. Iterates over all bindings
          3. Runs each check per (role, member) pair
          4. Collects violations into the result

        Returns:
            AuditResult dataclass with all findings
        """
        print(f"\n🔍 Auditing IAM policy for project: {self.project_id}\n")

        policy = self._get_iam_policy()

        # List comprehension to flatten all (role, member) pairs
        # policy.bindings is a list of {role, members[]} objects
        all_bindings = [
            (binding.role, member)
            for binding in policy.bindings
            for member in binding.members
        ]

        self._result.total_bindings = len(all_bindings)

        # Define all checks to run — easy to extend later
        checks = [
            self._check_primitive_roles,
            self._check_service_account_over_privilege,
            self._check_public_access,
        ]

        for role, member in all_bindings:
            for check in checks:
                violation = check(role, member)
                if violation:
                    self._result.violations.append(violation)

        return self._result


# Output formatting


class ReportFormatter:
    """
    Formats an AuditResult for display.

    Kept separate from IAMValidator — single responsibility principle.
    """

    @staticmethod
    def as_text(result: AuditResult) -> str:
        """
        Format audit result as human-readable text.

        @staticmethod means this method doesn't need 'self' —
        it belongs to the class for organisation, but has no instance state.
        """
        lines = []
        lines.append("=" * 60)
        lines.append(f"IAM AUDIT REPORT — {result.project_id}")
        lines.append("=" * 60)
        lines.append(f"Total bindings scanned : {result.total_bindings}")
        lines.append(f"Violations found       : {result.violation_count}")
        lines.append(
            f"Compliance status      : {'✅ COMPLIANT' if result.is_compliant else '❌ NON-COMPLIANT'}"
        )

        if result.violations:
            lines.append("\n===== Violations =====")
            for i, v in enumerate(result.violations, start=1):
                lines.append(f"\n[{i}] Severity : {v.severity}")
                lines.append(f"    Role     : {v.role}")
                lines.append(f"    Member   : {v.member}")
                lines.append(f"    Reason   : {v.reason}")
        else:
            lines.append("\n✅ No violations found.")

        lines.append("\n" + "=" * 60)
        return "\n".join(lines)

    @staticmethod
    def as_json(result: AuditResult) -> str:
        """Format audit result as JSON — useful for piping to other tools."""
        output = {
            "project_id": result.project_id,
            "total_bindings": result.total_bindings,
            "violation_count": result.violation_count,
            "is_compliant": result.is_compliant,
            "violations": [
                {
                    "severity": v.severity,
                    "role": v.role,
                    "member": v.member,
                    "reason": v.reason,
                }
                for v in result.violations  # list comprehension inside dict
            ],
        }
        return json.dumps(output, indent=2)


# CLI entry point


def parse_args() -> argparse.Namespace:
    """Define and parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Audit GCP project IAM bindings for least-privilege violations.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python iam_validator.py --project my-gcp-project
  python iam_validator.py --project my-gcp-project --output json
  python iam_validator.py --project my-gcp-project --output json > report.json
        """,
    )
    parser.add_argument(
        "--project",
        required=True,
        help="GCP project ID to audit",
    )
    parser.add_argument(
        "--output",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    try:
        validator = IAMValidator(project_id=args.project)
        result = validator.run_audit()

        formatter = ReportFormatter()
        if args.output == "json":
            print(formatter.as_json(result))
        else:
            print(formatter.as_text(result))

        # Exit with non-zero code if non-compliant — useful in CI/CD pipelines
        sys.exit(0 if result.is_compliant else 1)

    except RuntimeError as e:
        print(f"\n❌ Audit failed: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
