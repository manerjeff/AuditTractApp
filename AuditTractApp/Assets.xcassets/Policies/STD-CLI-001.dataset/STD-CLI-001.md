# [Company Name] Client Account Access Control Standard

**Document ID:** STD-CLI-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.5.15), SOC 2 (CC6.1, CC6.2), NIST SP 800-53 (AC-2, IA-2)

---

## 1. Scope
All employees, contractors, and support personnel who manage or provision client user access to **[Company Name]** software platforms are covered by this standard and must comply with associated procedures.

## 2. Requirements

### A. Identification
1. Each Client User must have a unique account identifier or user ID within their product environment. User IDs cannot be shared or reused under any circumstance.
2. Shared group or team accounts are strictly prohibited to ensure accurate audit tracking.
3. User IDs must be disabled within **twenty-four (24) business hours** of official notification from the client regarding a status change (e.g., resignation or role change).
4. User IDs must be disabled **immediately** when a client user is terminated under adversarial conditions.
5. Requests to add or disable client user accounts must be submitted via an incoming support ticket from an authorized client email domain. Support personnel must verify requests with the primary client contact via a secondary channel (e.g., phone call) to ensure email accounts are not compromised.

### B. Authentication
1. Each client account must enforce password requirements.
2. Passwords must be at least eight (8) characters long and contain at least one (1) alphabetic and one (1) non-alphabetic character.
3. Automated tools should enforce password standards natively whenever possible.
4. Clients should be encouraged to review and change passwords every three hundred and sixty-five (365) days.
5. All authentication data transmitted across public or shared networks must be encrypted in accordance with the Encryption Standard.

### C. Authorization
Client user access rights must be restricted strictly to the level of information and functional access required to meet approved business needs.

## 3. Responsibilities
The **[Data Security Officer]** approves and maintains this standard. All personnel are required to report suspected credential compromises immediately to `[sirt@company.com]`.

## 4. Enforcement & Review
Violations may result in disciplinary action up to termination. Reviewed annually in accordance with the Information Security Program Charter.