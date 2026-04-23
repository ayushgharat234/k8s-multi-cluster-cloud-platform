# Security Policy

## Supported Versions

Since this project serves as a reference architecture and a portfolio demonstration for a production-grade Internal Developer Platform rather than a distributed software library, only the most recent main branch configuration is supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| v2.0.x  | :white_check_mark: |
| < v2.0  | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this architecture, Terraform configurations, or the CI/CD supply chain implementation, please do **NOT** publicly disclose it via GitHub Issues. 

Instead, report it privately to the maintainer:

1. Send an email to [ayush.gharat234@gmail.com](mailto:ayush.gharat234@gmail.com) (or the email associated with the GitHub profile).
2. Include "Security Vulnerability - OpsNexus Config" in the subject line.
3. Provide a clear description of the vulnerability, the potential blast radius, and steps to reproduce the exploit.

You should receive a response within 48 hours acknowledging the report. If the vulnerability is confirmed, a patch will be issued with attribution to the reporter (if desired).

## Threat Model & Out of Scope

This platform is designed with a Hub-and-Spoke zero-trust architecture, relying on Workload Identity Federation (WIF) and HSM-backed KMS attestation. 

The following are **NOT** considered valid vulnerabilities for this specific repository layer:
* Vulnerabilities in the base images of the Node.js or Python application code (these are demo applications, though the pipeline will block CRITICAL CVEs).
* Lack of DNS/HTTPS termination on the Global Load Balancer (documented as a known limitation due to domain non-registration in the demo environment).
* 0-day exploits in Google Cloud or AWS underlying managed services (e.g., GKE etcd breakouts).

Any bypasses of the **Binary Authorization**, **Config Sync GitOps reconciliation**, or **Cross-Cloud IAM** are considered highly critical and should be reported immediately.
