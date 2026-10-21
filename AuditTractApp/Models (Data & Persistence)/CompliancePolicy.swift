//
//  CompliancePolicy.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation

// MARK: - Extension for Dynamic Bundle Policy Ingestion
extension AuditEstimator {
    func buildDefaultPolicies() -> [CompliancePolicy] {
        let policyCatalog: [(id: String, title: String, cat: String, map: [String], file: String)] = [
            ("POL-CHARTER-001", "Information Security Program Charter", "Governance & Charter", ["ISO/IEC 27001 (5.1)", "SOC 2 (CC1.1)", "NIST SP 800-53 (PM-1)"], "POL-CHARTER-001"),
            ("STD-AUP-001", "Acceptable Use Standard", "General Acceptable Use", ["ISO/IEC 27001 (A.5.10)", "SOC 2 (CC6.1)", "NIST SP 800-53 (AC-1)"], "STD-AUP-001"),
            ("STD-ACC-001", "Access Control Standard", "Identity & Access Management", ["ISO/IEC 27001 (A.5.15)", "SOC 2 (CC6.1)", "NIST SP 800-53 (AC-2)"], "STD-ACC-001"),
            ("STD-AV-001", "Anti-Virus & Malware Protection Standard", "Technical Safeguards", ["ISO/IEC 27001 (A.8.7)", "SOC 2 (CC6.8)", "NIST SP 800-53 (SI-3)"], "STD-AV-001"),
            ("STD-AST-001", "Asset Identification & Classification Standard", "Asset Management", ["ISO/IEC 27001 (A.5.9)", "SOC 2 (C1.1)", "NIST SP 800-53 (RA-2)"], "STD-AST-001"),
            ("STD-AST-002", "Asset Management Standard", "Asset Management", ["ISO/IEC 27001 (A.5.9)", "SOC 2 (CC6.1)", "NIST SP 800-53 (CM-8)"], "STD-AST-002"),
            ("STD-AUD-001", "Auditing & Logging Standard", "Security Operations", ["ISO/IEC 27001 (A.8.15)", "SOC 2 (CC7.2)", "NIST SP 800-53 (AU-2)"], "STD-AUD-001"),
            ("STD-AVAL-001", "Availability Protection Standard", "Business Continuity", ["ISO/IEC 27001 (A.5.29)", "SOC 2 (A1.1)", "NIST SP 800-53 (CP-9)"], "STD-AVAL-001"),
            ("STD-BYOD-001", "BYOD Acceptable Use Standard", "Mobile & Endpoint Security", ["ISO/IEC 27001 (A.8.1)", "SOC 2 (CC6.1)", "NIST SP 800-53 (AC-19)"], "STD-BYOD-001"),
            ("POL-CAB-001", "Change Advisory Board (CAB) Charter", "Change Governance", ["ISO/IEC 27001 (A.8.32)", "SOC 2 (CC8.1)", "NIST SP 800-53 (CM-3)"], "POL-CAB-001"),
            ("STD-CLI-001", "Client Account Access Control Standard", "Customer Identity Security", ["ISO/IEC 27001 (A.5.15)", "SOC 2 (CC6.1)", "NIST SP 800-53 (AC-2)"], "STD-CLI-001"),
            ("STD-CFG-001", "Configuration Management Standard", "System Hardening", ["ISO/IEC 27001 (A.8.9)", "SOC 2 (CC6.1)", "NIST SP 800-53 (CM-2)"], "STD-CFG-001"),
            ("POL-TOS-001", "Customer Terms of Service Framework", "Legal & Customer Terms", ["ISO/IEC 27001 (A.5.20)", "SOC 2 (CC2.3)", "NIST SP 800-53 (SA-4)"], "POL-TOS-001"),
            ("POL-DOC-001", "Document Retrieval Security Policy", "Physical & Document Security", ["ISO/IEC 27001 (A.7.10)", "SOC 2 (CC6.5)", "NIST SP 800-53 (MP-4)"], "POL-DOC-001"),
            ("STD-EML-001", "Electronic Mail Acceptable Use Standard", "Communications Security", ["ISO/IEC 27001 (A.5.14)", "SOC 2 (CC6.6)", "NIST SP 800-53 (AC-4)"], "STD-EML-001"),
            ("POL-COC-001", "Employee Code of Conduct", "Ethics & Governance", ["ISO/IEC 27001 (A.6.3)", "SOC 2 (CC1.1)", "NIST SP 800-53 (PS-8)"], "POL-COC-001"),
            ("STD-CRY-001", "Encryption Standard", "Cryptography & Key Management", ["ISO/IEC 27001 (A.8.24)", "SOC 2 (CC6.7)", "NIST SP 800-53 (SC-13)"], "STD-CRY-001"),
            ("STD-FW-001", "Firewall Hardening Standard", "Network Defense", ["ISO/IEC 27001 (A.8.20)", "SOC 2 (CC6.6)", "NIST SP 800-53 (SC-7)"], "STD-FW-001"),
            ("IRP-SEC-001", "Information Security Incident Response Plan", "Incident Response", ["ISO/IEC 27001 (A.5.24)", "SOC 2 (CC7.3)", "NIST SP 800-53 (IR-4)"], "IRP-SEC-001"),
            ("POL-VEN-001", "Vendor & Third-Party Risk Management Policy", "Third-Party Oversight", ["ISO/IEC 27001 (A.5.19)", "SOC 2 (CC9.1)", "NIST SP 800-53 (SR-2)"], "POL-VEN-001"),
            ("POL-AWS-001", "AWS Cloud Infrastructure Security Policy", "Cloud Infrastructure Security", ["AWS Best Practices", "SOC 2 (CC6.1)", "NIST SP 800-53 (AC-2)"], "POL-AWS-001"),
            ("STD-AWS-IAM", "AWS IAM & Credential Management Standard", "Identity & Access Management", ["AWS Best Practices", "ISO/IEC 27001 (A.5.15)", "SOC 2 (CC6.2)"], "STD-AWS-IAM"),
            ("POL-FERPA-001", "Student Data Privacy & FERPA Compliance Policy", "Student Data Privacy", ["FERPA (34 CFR Part 99)", "NIST SP 800-122", "ISO/IEC 27001 (A.5.34)"], "POL-FERPA-001"),
            ("POL-CJIS-001", "Criminal Justice Information Services (CJIS) Security Policy", "Public Safety & Law Enforcement", ["FBI CJIS Security Policy v5.9+", "NIST SP 800-53", "FedRAMP Moderate"], "POL-CJIS-001"),
            ("POL-PCI-001", "Payment Card Industry (PCI DSS v4.0) Security Policy", "Payment Security", ["PCI DSS v4.0", "ISO/IEC 27001 (A.8.24)", "SOC 2 (CC6.1)"], "POL-PCI-001"),
            ("POL-SOC3-001", "SOC 3 Public Trust & Disclosure Policy", "Public Security Disclosures", ["AICPA SOC 3", "SOC 2 (CC2.1)", "ISO/IEC 27001 (A.5.1)"], "POL-SOC3-001"),
            ("POL-SOX-001", "Sarbanes-Oxley (SOX 404) IT General Controls Policy", "Financial Governance", ["SOX Section 404", "PCAOB AS 2201", "COSO Framework"], "POL-SOX-001"),
            ("POL-SSAE18-001", "SSAE 18 Audit & Service Organization Attestation Policy", "Audit Governance", ["AICPA SSAE 18", "AT-C 105 / 205", "SOC 1 / SOC 2"], "POL-SSAE18-001"),
            ("POL-FISMA-001", "FISMA Information Security & Risk Management Framework Policy", "Federal Compliance", ["FISMA (44 U.S.C. § 3551)", "NIST SP 800-37 RMF", "FIPS 199 / 200"], "POL-FISMA-001"),
            ("POL-HITRUST-001", "HITRUST CSF Information Security Governance Policy", "Healthcare & Enterprise Security", ["HITRUST CSF v11", "HIPAA Security Rule", "NIST SP 800-53"], "POL-HITRUST-001"),
            ("POL-GDPR-001", "Global Data Protection & Privacy Policy (GDPR / CCPA)", "Data Sovereignty & Privacy", ["EU GDPR (2016/679)", "CCPA / CPRA", "ISO/IEC 27001 (A.5.34)"], "POL-GDPR-001")
            ]
        
        return policyCatalog.map { item in
            let fullText = loadMarkdownFromBundle(named: item.file) ?? fallbackSummary(for: item.id)
            return CompliancePolicy(
                id: item.id,
                title: item.title,
                category: item.cat,
                frameworkMapping: item.map,
                documentID: item.id,
                contentMarkdown: fullText
            )
        }
    }

    private func loadMarkdownFromBundle(named fileName: String) -> String? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "md") ?? Bundle.main.url(forResource: fileName, withExtension: nil) {
            return try? String(contentsOf: url, encoding: .utf8)
        }
        return nil
    }

    private func fallbackSummary(for documentID: String) -> String {
        return """
        # [Company Name] Policy Template (\(documentID))
        
        **Document ID:** \(documentID)  
        **Status:** Local Markdown bundle asset missing. Please ensure `\(documentID).md` is included in the Xcode target.
        """
    }
}
