# [Company Name] AWS IAM & Credential Management Standard

**Document ID:** STD-AWS-IAM  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** AWS Security Best Practices, ISO/IEC 27001 (A.5.15, A.5.17), SOC 2 (CC6.1, CC6.2)

---

## 1. Scope
Applies to all IAM users, roles, service accounts, and API access keys across **[Company Name]** AWS infrastructure.

## 2. Access Control Requirements
1. **Identity Federation:** All human access to AWS accounts must originate from AWS IAM Identity Center (Single Sign-On) federated with the central Identity Provider (IdP).
2. **Elimination of Long-Lived Access Keys:** Long-lived IAM programmatic access keys are prohibited for human users. Temporary STS credentials must be used via IAM roles.
3. **MFA Requirement:** Multi-factor authentication (MFA) is mandatory for all access to AWS management consoles and CLI sessions.
4. **Credential Rotation:** Service keys (where required) must be rotated every **90 days**. Credentials unused for 90 days are automatically disabled.
5. **Least Privilege Verification:** IAM policies must restrict permissions to specific actions and ARNs using AWS IAM Access Analyzer validation.