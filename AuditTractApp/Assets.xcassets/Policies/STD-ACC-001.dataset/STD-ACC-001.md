# [Company Name] Access Control Standard

**Document ID:** STD-ACC-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.5.15–A.5.18), SOC 2 (CC6.1, CC6.2, CC6.3), NIST SP 800-53 (AC-2, AC-3, AC-7, IA-2)

---

## 1. Scope
All employees, contractors, part-time and temporary workers, and those employed by others to perform work on Company premises, or at the behest of the Company, or who have been granted access to Company information or systems, are covered by this standard and must comply with associated guidelines and procedures.

* **Authentication:** Refers to the controls for providing Users the means to verify or validate a claimed identity through something they know (e.g., passwords), something they own (e.g., hardware token), or something they are (e.g., biometrics).
* **Authorization:** Refers to the controls for determining the resources that Users are permitted to access based upon authorized permissions and privileges.
* **Confidentiality:** Classifications defined in the Information Classification Standard.
* **Encryption:** Refers to a method of scrambling information to render it unreadable to anyone except the intended recipient.
* **Identification:** Refers to controls for providing Users the means to convey their identities using pre-determined identifiers.
* **Information Assets:** Defined in the Asset Identification and Classification Standard.
* **Integrity:** Refers to the protection of information and systems from malicious, unauthorized, or accidental changes.
* **Sensitive Information:** Refers to information classified as Restricted or Confidential.

## 2. Requirements

### A. Identification
1. Each User must have a unique account identifier or user ID. Account Identifiers and/or User IDs cannot be reused for any reason, regardless of circumstance (e.g., return of a previous employee).
2. User communities and working groups must not share a single user ID for system access to ensure accurate accounting of user access and actions.
3. User IDs should not be shared or used by anyone other than the User to whom they are assigned. Users shall be accountable for all activity associated with their assigned user IDs.
4. User IDs must be added, modified, and deleted in accordance with Company-approved account management processes.
5. User IDs must be disabled within twenty-four (24) hours of notification of a status change (for example, resignation or change in job).
6. User IDs must be disabled immediately when a user has been terminated under adversarial conditions to prevent retaliatory risks to company assets, resources, reputation, and employees.
7. Requests for User IDs must be initiated in the designated Operations ticketing system.
8. Requests to disable User IDs must be initiated in the designated Operations ticketing system.
9. User IDs that are unused, dormant, or inactive for 180 days must be disabled.
10. User IDs that are disabled for 180 days must be deleted.
11. Temporary User IDs (for testing, contractors, and temporary employees) should have an account expiration date coinciding with the anticipated end of employment, testing, or contract.
12. Vendor access and User IDs must never be active for more than 180 consecutive days. When Vendors are provided access, they must be added to a Vendor Access List held by the Data Security Officer.

### B. Authentication
1. Each user ID or account must be assigned a password.
2. Passwords on new accounts must expire upon first log-in and require an immediate password change.
3. All default system and application passwords must be changed prior to placing in the production environment or connecting to a live network.
4. Authentication credentials such as passwords and tokens should not be used by anyone other than the User to whom they are assigned.
5. Passwords must conform to the following criteria, with native system enforcement when possible:
   * Password length must be eight (8) characters or longer. If the system does not support eight characters, the password must contain the maximum allowed by the system.
   * Passwords must not be equal to, or a derivative of, the user ID.
   * Passwords must contain at least one (1) alphabetic and one (1) non-alphabetic character.
6. When password criteria cannot be enforced by the native system, an automated password tool should be used, whenever possible, to verify and enforce criteria.
7. Passwords should be reviewed every three hundred and sixty-five (365) days for service and system ID accounts.
8. Passwords should be changed within twenty-four (24) hours upon the termination of any employee with knowledge of the password to service and system ID accounts.
   * The account name and password must be transcribed onto a physical document containing custodian name, position, creation date, recertification date, asset name, and password.
   * Two identical physical copies must be provided to the Data Security Officer and an electronic copy uploaded to the encrypted `[Repository Path / Virtual Safe]` for safe storage.
   * The physical document must be placed into a sealed envelope in safe storage or a password vault application.
   * The sealed envelope must be destroyed when replaced by a newly certified document.
   * Under no circumstances should the document reside unencrypted in any email system, file system, or storage media without the highest level of encryption applied according to the Encryption Standard.
9. Passwords are reviewed every one hundred and eighty (180) days for user IDs with administrative or equivalent privileges.
10. Passwords are to be changed within twenty-four (24) hours upon termination of any employee with knowledge of administrative account passwords.
11. Password entries must not be allowed in rapid succession to prevent a user from "cycling" through passwords. Within all applications built by the Company, appropriate hashing iterations and cycle delays must be enforced.
12. All systems, in accordance with the Auditing Standard, must log date and time for all failed and successful user access attempts.
13. Authentication credentials must not be written down or stored in readable form, automatic log-in scripts, software macros, terminal function keys, shortcuts, or unencrypted locations.
14. All passwords must be immediately changed if known or suspected of being disclosed.
15. All systems must require and authenticate a valid user ID and password, PEM Key, or token prior to granting access to network resources.
16. Authentication data (e.g., password files) must be protected with encryption controls.
17. Authentication data transmitted over public or shared networks must be encrypted in accordance with the Encryption Standard.

### C. Authorization
1. User access to information will be based on the confidentiality classification of the information asset.
2. Users should only be authorized the level of access to information assets required to meet an approved business need or perform job responsibilities.
3. Access to sensitive information must be provided on a need-to-know basis.
4. User access rights to files, directories, and objects should be assigned on a group basis and not assigned individually, unless unavoidable.
5. Concurrent log-ins allowed per user ID should be restricted to the minimum required.
6. Administrative access must be limited strictly to users explicitly requiring privileged access. Access shall not be granted until a properly documented request is approved by two designated managers, including the Data Security Officer.

## 3. Responsibilities
The **[Data Security Officer]** approves the Access Control Standard and is responsible for ensuring its development, implementation, and maintenance.

Asset Owners are responsible for defining processes consistent with this standard, defining access control requirements, processing access requests, and reviewing access privileges at least annually.

Asset Custodians are responsible for providing a secure processing environment, administering access as authorized by the Owner, and implementing procedural safeguards.

Users are responsible for complying with this standard, keeping credentials secure, and reporting compromised credentials immediately to `[sirt@company.com]`.

## 4. Enforcement and Exception Handling
Failure to comply can result in disciplinary action up to termination of employment or contracts. Exception requests must be submitted to executive management and require written approval from the **[Data Security Officer]**.

## 5. Review and Revision
This standard will be reviewed and revised annually in accordance with the Information Security Program Charter.