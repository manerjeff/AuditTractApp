# [Company Name] Firewall Hardening Standard

**Document ID:** STD-FW-001  
**Version:** 1.0  
**Effective Date:** [Effective Date]  
**Approved By:** [Data Security Officer]  
**Framework Alignment:** ISO/IEC 27001 (A.8.20, A.8.22), SOC 2 (CC6.6), NIST SP 800-53 (SC-7)

---

## 1. Scope
This standard applies to all perimeter firewalls, cloud security groups (e.g., AWS Security Groups, Cloudflare WAF), and internal network segmentation routers owned or operated by **[Company Name]**.

## 2. Ruleset Structure & Evaluation Order
Firewall rulesets operate on a first-match basis and must enforce strict rule ordering:
1. **User Permit Rules:** Allow explicitly authorized business traffic (e.g., inbound HTTPS over port 443).
2. **Management Permit Rules:** Allow authorized administrative management traffic (e.g., SNMP/SSH from trusted management IPs).
3. **Deny and Alert:** Log and alert on suspicious traffic spikes or blocked connection bursts.
4. **Default Deny All:** Drop and log all remaining unapproved traffic.

## 3. Technical Requirements
1. **Port Restrictions:** Production endpoints must restrict open inbound ports exclusively to **443 (HTTPS)** and **22 (SSH)**.
2. **SSH Restrictions (Port 22):** Port 22 must be restricted strictly to explicitly trusted corporate IP addresses. Trusted IP access lists must be audited and verified **monthly**.
3. **Web Application Firewalls (WAF):** WAF configurations must integrate with intrusion detection logging and receive automatic attack signature updates.
4. **Network Segmentation:** Dual firewall boundaries (or isolated VPC subnets) must separate public web tiers from internal database engines.

## 4. Enforcement & Review
Unauthorized rule modifications will result in immediate reversal and potential disciplinary action. Exception requests require written approval from the **[Data Security Officer]**. Reviewed annually.