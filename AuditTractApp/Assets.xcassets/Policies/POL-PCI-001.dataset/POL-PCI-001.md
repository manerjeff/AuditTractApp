# [Company Name] Payment Card Industry (PCI DSS v4.0) Security Policy

**Document ID:** POL-PCI-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer / Chief Financial Officer]  
**Regulatory Alignment:** PCI DSS v4.0, ISO/IEC 27001 (A.8.24), SOC 2 (CC6.1)

---

## 1. Purpose
This policy establishes security standards to protect Primary Account Numbers (PAN), Sensitive Authentication Data (SAD), and the Cardholder Data Environment (CDE) managed by **[Company Name]**.

## 2. Scope
Applies to all systems, network boundaries, cloud databases, payment gateways, employees, and third-party service providers connected to or handling cardholder data.

## 3. Core Requirements
1. **Firewall & Boundary Protection:** Maintain Network Security Controls isolating the CDE from external and internal untrusted networks.
2. **Data Encryption:** Store PAN using strong cryptography (AES-256). Transmit PAN across public networks exclusively via TLS 1.2 or 1.3. Storing Sensitive Authentication Data (SAD) post-authorization is strictly prohibited.
3. **Multi-Factor Authentication (MFA):** Mandatory MFA for all logical access to the CDE and administrative accounts.
4. **Vulnerability Management & Scanning:** Execute quarterly Approved Scanning Vendor (ASV) vulnerability scans and annual penetration testing.
5. **Audit Logging:** Retain write-protected SIEM audit logs recording all access to cardholder data for at least 12 months.