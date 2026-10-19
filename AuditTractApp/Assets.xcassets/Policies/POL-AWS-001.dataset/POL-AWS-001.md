# [Company Name] AWS Cloud Infrastructure Security Policy

**Document ID:** POL-AWS-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer / Cloud Architecture Lead]  
**Framework Alignment:** AWS Foundational Security Best Practices, SOC 2 (CC6.1, CC6.6), NIST SP 800-53 (AC-2, SC-7)

---

## 1. Purpose
This policy defines mandatory baseline security controls for provisioning, managing, and securing Amazon Web Services (AWS) infrastructure across all production, staging, and development accounts owned by **[Company Name]**.

## 2. Scope
Applies to all AWS accounts, VPCs, IAM identities, cloud resources, serverless workloads, and automated CI/CD pipelines.

## 3. Mandatory AWS Guardrails
1. **Multi-Account Governance:** AWS Organizations with Service Control Policies (SCPs) must enforce top-level guardrails across all accounts.
2. **Root Account Hardening:** The AWS root user account must be secured with hardware MFA. Day-to-day access via root credentials is strictly prohibited.
3. **Network Boundary Security:** Public S3 bucket access must be blocked at the account level. Direct SSH/RDP access to EC2 instances from `0.0.0.0/0` is forbidden; AWS Systems Manager Session Manager must be used instead.
4. **Data Encryption:** All data at rest across S3, EBS, RDS, and DynamoDB must be encrypted using AWS KMS. In-transit traffic must enforce TLS 1.2 or TLS 1.3.
5. **Continuous Auditing:** AWS Config, GuardDuty, and CloudTrail must remain active across all regions at all times.