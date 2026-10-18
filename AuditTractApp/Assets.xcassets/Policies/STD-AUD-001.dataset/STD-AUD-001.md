# [Company Name] Auditing Standard

**Document ID:** STD-AUD-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.8.15), SOC 2 (CC7.2), NIST SP 800-53 (AU-2, AU-6, AU-9, AU-12)

---

## 1. Scope
All employees, contractors, and temporary personnel operating Company systems or who have been granted access to Company information assets must comply with this auditing standard.

## 2. Requirements

### A. General
1. **Centralized Logging:** The Company shall employ a centralized audit-logging scheme such that audit logs are securely written to a centralized log system.
2. **Log Archiving:** The centralized log system shall provide a mechanism for archiving audit logs in accordance with legal and regulatory requirements.
3. **Time Synchronization:** All Company servers, network devices, and multi-user systems shall receive time synchronization from a dedicated, central Company Network Time Protocol (NTP) source.
4. **Log Review:** Authorized personnel shall review audit logs to detect indications or patterns associated with malicious activity and take appropriate action in accordance with the Incident Response Plan.

### B. Activation
Auditing shall be enabled on all Company servers, network devices, and multi-user systems. Audit records shall be generated for successful and/or failed attempts to:
1. Log on or log off the system
2. Change User and Group Accounts
3. Startup and shutdown system services
4. Change security policy or configuration settings
5. Backup or restore data
6. Access sensitive (Restricted or Confidential) information

Audit records must include **who**, **what**, **when**, and **from where** the recorded event occurred.

### C. Protection
Audit logs and records shall be protected to prevent deletion or alteration by unauthorized users. Access to audit logs, audit records, and audit configuration settings shall be restricted strictly to privileged security accounts.

### D. Retention and Storage
1. **Capacity Buffer:** Each system will provide sufficient storage to ensure logs will not be overwritten during normal operating conditions or situations generating logging activity 300% greater than normal.
2. **Retention Schedule:** Audit logs must be retained online for a time period defined by legal and regulatory requirements, which currently is **thirteen (13) months**.

## 3. Responsibilities
The **[Data Security Officer]** approves and maintains the Auditing Standard.

Asset Owners ensure audit logs are periodically reviewed and securely archived. Custodians configure logging capabilities, protect log data, and notify Owners immediately if auditing capabilities are compromised.

## 4. Enforcement & Review
Failure to comply can result in disciplinary action up to termination. Exceptions require written approval from the **[Data Security Officer]**. Reviewed annually.