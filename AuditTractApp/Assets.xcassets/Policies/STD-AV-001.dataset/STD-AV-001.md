# [Company Name] Anti-Virus Standard

**Document ID:** STD-AV-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.8.7), SOC 2 (CC6.8), NIST SP 800-53 (SI-3)

---

## 1. Scope
All employees, contractors, part-time and temporary workers, and those employed by others to perform work on Company premises or who have been granted access to Company information or systems, are covered by this standard and must comply with associated guidelines and procedures.

* **Customers & Customer Information:** Defined in the Asset Identification and Classification Standard.
* **Exchangeable Media:** Refers to removable hard drives, flash media, compact disks, optical storage, etc.
* **Viruses & Malware:** Refers to malicious software code such as Trojan horses, viruses, worms, ransomware, and malicious mobile code that masquerades or replicates with the potential to cause damage, destruction, or disruption.

## 2. Requirements

### A. General
1. The Company has approved and licensed anti-virus / EDR software packages.
2. Company-approved anti-virus software must be installed on all Company computing resources deemed appropriate by the Data Security Officer.
3. Company-approved anti-virus software must be enabled at all times.
4. Virus detection shall not be disabled on any computer resources equipped with anti-virus protection.
5. Only Company authorized personnel can configure or approve modifications to anti-virus software configurations.
6. Automatic notification features will be used to ensure appropriate personnel are aware of software version updates.
7. All licensed executable or version upgrades to anti-virus software shall be distributed and implemented as necessary to effectively respond to security advisories.
8. Automatic signature update features must be configured to perform automatic signature updates as required.
9. Distribution of virus signature updates shall be expedited to respond to emerging security advisories.
10. All detected virus infections shall be automatically "cleaned". If unavailable, infected files, programs, and systems shall be isolated and quarantined until restored.
11. All virus detections and infections should be reported immediately to Infrastructure Services and Information Security at `[sirt@company.com]` providing name, employee ID, phone number, description of the problem, virus name (if known), and affected asset.

### B. Firewalls and Perimeter Network
1. Company-approved anti-virus features and options should be implemented to stop viruses and malicious code at Company firewalls and perimeter networks.
2. Cloud computing resources utilized in production environments must conform with SOC 2 Anti-Virus Standards.

## 3. Responsibilities
The **[Data Security Officer]** approves the Anti-Virus Standard and ensures its development, implementation, and maintenance.

Company Management is accountable for ensuring that the Anti-Virus Standard is properly communicated and understood within their respective units.

Asset Owners are responsible for defining procedures consistent with this standard and ensuring integrity controls are reviewed annually.

Asset Custodians are responsible for providing a secure processing environment, ensuring anti-virus software and signature updates are distributed, and leading recovery efforts from virus infections.

Users are responsible for ensuring virus scanning is not disabled on workstations and notifying `[sirt@company.com]` immediately upon threat detection.

## 4. Enforcement and Exception Handling
Non-compliance may result in disciplinary action up to termination of employment or contract. Exception requests must be submitted in writing to the **[Data Security Officer]**.

## 5. Review and Revision
The Anti-Virus Standard will be reviewed and revised annually in accordance with the Information Security Program Charter.