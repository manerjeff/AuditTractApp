# [Company Name] Configuration Management Standard

**Document ID:** STD-CFG-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.8.9), SOC 2 (CC6.1, CC8.1), NIST SP 800-53 (CM-2, CM-6)

---

## 1. Scope
This standard applies to all computing infrastructure, network devices, cloud instances, databases, and desktop environments in the **[Company Name]** production and corporate environments.

## 2. Requirements

### A. General Protection Standards
1. Protection hardening standards must be established and enforced for all production assets.
2. Baseline configurations must incorporate access control, remote access restrictions, encryption, file integrity, logging, anti-virus, and patch management controls.
3. Baseline configurations must be reviewed by Information Security to prevent introducing vulnerabilities.

### B. Network Devices
1. Every network device (firewall, router, load balancer) must be configured according to established hardening standards.
2. Every network device must be uniquely identified with records retained regarding physical/cloud location, OS version, revision level, and active rulesets.
3. Network changes must comply with the Change Control Standard and Vulnerability Management Policy.

### C. Server Infrastructure
1. Production servers must be uniquely identified, with operating system builds, patch levels, and application configurations documented.
2. Server configurations must be audited against security baselines at least **monthly** to detect configuration drift.
3. All changes to production servers must follow formal CAB approval processes.

### D. Desktop & Endpoint Environment
1. Standardized corporate workstation images (OS build, anti-virus, disk encryption, standard tooling) must be maintained and deployed automatically.
2. Desktop and laptop systems are subject to routine unannounced compliance audits. Unapproved software will be removed automatically.

## 3. Responsibilities
The **[Data Security Officer]** approves and maintains this standard. Asset Owners and Custodians are responsible for applying hardening baselines and maintaining accurate asset inventories.

## 4. Enforcement & Review
Violations may result in disciplinary action up to termination. Reviewed annually.