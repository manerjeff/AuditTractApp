# [Company Name] Encryption Standard

**Document ID:** STD-CRY-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.8.24), SOC 2 (CC6.7), NIST SP 800-53 (SC-13)

---

## 1. Scope
All personnel, systems, cloud databases, and software applications managing, storing, or transmitting sensitive **[Company Name]** data must adhere to this standard.

## 2. Approved Cryptographic Algorithms

### A. Message Digest Algorithms (Hashing)
* SHA-256 (256-bit)
* SHA-512 (512-bit)
* SHA3-256 / SHA3-512

### B. Symmetric Block Ciphers (Data at Rest)
* **AES-256** (or higher).
* Encryption keys are sensitive assets; symmetric master keys must be escrowed with the Data Security Officer to ensure organizational recovery capability.

### C. Asymmetric Algorithms (Public Key)
* **RSA** with **2048-bit or stronger** key pairs.
* Public key passphrases must contain a minimum of twelve (12) characters.

### D. Transit Encryption (TLS / SSL)
* **Approved Protocols:** TLS 1.2 or TLS 1.3.
* **Approved Ciphers:** ECDHE-RSA-AES128-GCM-SHA256, ECDHE-RSA-AES256-GCM-SHA384, AES256-GCM-SHA384.
* All endpoints must use valid SSL certificates approved by the Data Security Officer.

### E. Password Hashing
* Applications must utilize **BCrypt / Eksblowfish** or equivalent adaptive key derivation algorithms with appropriate salt and cost factors.

## 3. Key Compromise Reporting
Any actual or suspected compromise of an encryption key, private key, or TLS certificate must be reported immediately to `[sirt@company.com]` so certificates can be revoked.

## 4. Enforcement & Review
Violations may lead to disciplinary action. Exceptions require written approval from the **[Data Security Officer]**. Reviewed annually.