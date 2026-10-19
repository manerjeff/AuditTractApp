# [Company Name] Criminal Justice Information Services (CJIS) Security Policy

**Document ID:** POL-CJIS-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Agency Information Security Officer (AISO) / CISO]  
**Regulatory Alignment:** FBI CJIS Security Policy (v5.9+), NIST SP 800-53, FedRAMP Moderate

---

## 1. Purpose
This policy establishes mandatory operational and technical security standards for creating, processing, storing, transmitting, or destroying Criminal Justice Information (CJI) managed by **[Company Name]**.

## 2. Scope
Applies to all systems, physical facilities, cloud environments, contractors, software engineers, and administrative personnel with unescorted physical or logical access to CJI or supporting networks.

## 3. Mandatory CJIS Security Directives
1. **Personnel Clearance:** All personnel requesting access to CJI must undergo a 10-year state and national fingerprint-based background check prior to access authorization.
2. **CJIS Security Addendum:** External contractors, service providers, and vendors must execute a formal CJIS Security Addendum approved by the Agency Information Security Officer (AISO).
3. **Advanced Authentication (MFA):** Multi-factor authentication utilizing FIPS-validated cryptographic modules is strictly enforced for all access originating outside the physically secure perimeter.
4. **FIPS Encryption:** All CJI at rest and in transit across public or non-secure networks must be encrypted using FIPS 140-2 or 140-3 validated cryptographic modules.
5. **Physical & Media Protection:** Physical facilities holding CJI must restrict entry to authorized personnel. Physical or electronic media containing CJI must be sanitized per NIST SP 800-88 before disposal.