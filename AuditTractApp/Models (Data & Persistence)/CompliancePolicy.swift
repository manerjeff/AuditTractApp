// MARK: - Compliance Policy Template Model
struct CompliancePolicy: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let frameworkMapping: [String]
    let documentID: String
    let contentMarkdown: String
}

// MARK: - Extension for Policy Library Ingestion
extension AuditEstimator {
    func buildDefaultPolicies() -> [CompliancePolicy] {
        return [
            CompliancePolicy(
                id: "POL-CHARTER-001",
                title: "Information Security Program Charter",
                category: "Governance & Charter",
                frameworkMapping: ["ISO/IEC 27001 (5.1)", "SOC 2 (CC1.1)", "NIST SP 800-53 (PM-1)"],
                documentID: "POL-CHARTER-001",
                contentMarkdown: """
                # [Company Name] Information Security Program Charter
                
                **Document ID:** POL-CHARTER-001  
                **Version:** 1.0  
                **Approved By:** [Data Security Officer / Board of Directors]
                
                ---
                
                ## 1. Purpose
                Information is an essential [Company Name] asset and is vitally important to business operations. [Company Name] must ensure that its information assets are protected in a cost-effective manner that reduces the risk of unauthorized disclosure, modification, or destruction.
                
                ## 2. Scope
                This Charter applies to all employees, contractors, part-time and temporary workers, and service providers operating on [Company Name] premises or who have been granted access to company systems.
                
                ## 3. Governance Framework
                - **ISO 27001 Alignment:** Uses ISO/IEC 27001 as its foundation for organizational security controls.
                - **Vulnerability & Risk Reduction:** Establishes policies to assess, identify, prioritize, and manage vulnerabilities.
                - **Security Awareness:** Management shall maintain a formal Security Awareness Program for all personnel.
                """
            ),
            CompliancePolicy(
                id: "STD-ACC-001",
                title: "Access Control Standard",
                category: "Identity & Access",
                frameworkMapping: ["ISO/IEC 27001 (A.5.15)", "SOC 2 (CC6.1)", "NIST SP 800-53 (AC-2)"],
                documentID: "STD-ACC-001",
                contentMarkdown: """
                # [Company Name] Access Control Standard
                
                **Document ID:** STD-ACC-001  
                **Version:** 1.0  
                **Approved By:** [Data Security Officer]
                
                ---
                
                ## 1. Identification Requirements
                - **Unique Account IDs:** Every user must be assigned a unique user ID. Account sharing or reuse is prohibited.
                - **Disabling Timelines:**
                  - Voluntary departure / role change: Account disabled within **24 hours**.
                  - Involuntary termination: Account disabled **immediately**.
                  - Inactive for 180 days: Account disabled; deleted after an additional 180 days.
                
                ## 2. Authentication Requirements
                - **Password Construction:** Minimum 8 characters containing at least one alphabetic and one non-alphabetic character.
                - **Administrative Review:** Privileged account passwords reviewed every 180 days.
                """
            ),
            CompliancePolicy(
                id: "IRP-SEC-001",
                title: "Information Security Incident Response Plan",
                category: "Incident Response",
                frameworkMapping: ["ISO/IEC 27001 (A.5.24)", "SOC 2 (CC7.3)", "NIST SP 800-53 (IR-4)"],
                documentID: "IRP-SEC-001",
                contentMarkdown: """
                # [Company Name] Security Incident Response Plan (IRP)
                
                **Document ID:** IRP-SEC-001  
                **Version:** 1.0  
                **Approved By:** [Data Security Officer]
                
                ---
                
                ## 1. Emergency Contact Summary
                - **Incident Hotline:** [Company Phone Number]
                - **SIRT Escalation Email:** [sirt@company.com]
                
                ## 2. Response Lifecycle
                1. **Triage & Notification:** Log threat details and evaluate data involvement.
                2. **Severity Classification:** Assign High (Red), Medium (Orange), or Low (Yellow) threat levels.
                3. **Evidence Preservation:** Preserve logs, disk snapshots, and maintain chain-of-custody tags.
                4. **Containment & Eradication:** Isolate affected subnets, revoke compromised tokens, and apply patches.
                5. **Recovery & Restoration:** Conduct post-incident monitoring prior to production reconnection.
                """
            )
        ]
    }
}
