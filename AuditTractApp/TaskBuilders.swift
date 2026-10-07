import Foundation

extension AuditEstimator {
    
    func buildAllFallbackTasks() -> [AuditTask] {
        var items: [AuditTask] = []
        items.append(contentsOf: buildSOC2Tasks())
        items.append(contentsOf: buildISOTasks())
        items.append(contentsOf: buildPCITasks())
        items.append(contentsOf: buildNISTTasks())
        items.append(contentsOf: buildHIPAATasks())
        items.append(contentsOf: buildSOC1Tasks())
        items.append(contentsOf: buildFedRAMPTasks())
        items.append(contentsOf: buildGDPRTasks())
        return items
    }
    
    func buildSOC2Tasks() -> [AuditTask] {
        var items: [AuditTask] = []
        let soc2Categories = [
            ("CC1", "Control Environment", 5),
            ("CC2", "Communication and Information", 3),
            ("CC3", "Risk Assessment", 4),
            ("CC4", "Monitoring Activities", 2),
            ("CC5", "Control Activities", 3),
            ("CC6", "Logical and Physical Access Controls", 8),
            ("CC7", "System Operations", 4),
            ("CC8", "Change Management", 1),
            ("CC9", "Risk Mitigation", 2),
            ("A1", "Availability Criteria", 3),
            ("C1", "Confidentiality Criteria", 2),
            ("PI1", "Privacy Criteria", 8)
        ]
        
        for idx in 0..<soc2Categories.count {
            let (pref, catName, maxCount) = soc2Categories[idx]
            for i in 1...maxCount {
                items.append(AuditTask(
                    id: "SOC2-\(pref).\(i)",
                    frameworkKey: "SOC2",
                    title: "\(catName): Common Criteria \(pref).\(i)",
                    category: catName,
                    blurb: "AICPA Trust Services Criteria requirement for \(catName.lowercased()).",
                    discussion: "The entity demonstrates commitment to integrity, security, and operational standards under AICPA Trust Services Criteria \(pref).\(i).",
                    controlActivities: "1. Inspect operational policy documentation and management approval records.\n2. Verify system audit logging and annual compliance reviews."
                ))
            }
        }
        return items
    }
    
    func buildISOTasks() -> [AuditTask] {
        var items: [AuditTask] = []
        for i in 1...93 {
            items.append(AuditTask(
                id: "ISO-A.8.\(i)",
                frameworkKey: "ISO27001",
                title: "ISO/IEC 27001:2022 Control A.8.\(i)",
                category: i <= 37 ? "Organizational Controls" : "Technological Controls",
                blurb: "ISO/IEC 27001:2022 ISMS Annex A control specification.",
                discussion: "ISO/IEC 27001:2022 Annex A specification for information security governance and risk management.",
                controlActivities: "1. Inspect ISMS management review sign-offs.\n2. Sample technical safeguard enforcement logs."
            ))
        }
        return items
    }
    
    func buildPCITasks() -> [AuditTask] {
        var items: [AuditTask] = []
        for req in 1...12 {
            for sub in 1...21 {
                items.append(AuditTask(
                    id: "PCI-\(req).\(sub)",
                    frameworkKey: "PCIDSS",
                    title: "PCI DSS v4.0 Requirement \(req).\(sub)",
                    category: "Requirement \(req)",
                    blurb: "Payment Card Industry Data Security Standard v4.0 safeguard.",
                    discussion: "Restrict inbound and outbound traffic, protect cardholder data environment (CDE), and enforce strong authentication pursuant to PCI DSS v4.0 standard \(req).\(sub).",
                    controlActivities: "1. Inspect network firewall rulesets and database encryption configurations.\n2. Audit administrative login logs and MFA enforcement rules."
                ))
            }
        }
        return items
    }
    
    func buildNISTTasks() -> [AuditTask] {
        var items: [AuditTask] = []
        let families = ["AC", "AU", "AT", "CM", "IA", "IR", "MA", "MP", "PE", "PL", "PS", "RA", "SA", "SC", "SI"]
        for fam in families {
            for i in 1...19 {
                items.append(AuditTask(
                    id: "NIST-\(fam)-\(i)",
                    frameworkKey: "NIST",
                    title: "NIST SP 800-53 Control \(fam)-\(i)",
                    category: "\(fam) Control Family",
                    blurb: "Federal information system security and privacy safeguard.",
                    discussion: "NIST SP 800-53 Rev 5 federal security and privacy safeguard for information system authorization.",
                    controlActivities: "1. Inspect System Security Plan (SSP) control responses.\n2. Review automated vulnerability scan reports."
                ))
            }
        }
        return items
    }
    
    func buildHIPAATasks() -> [AuditTask] {
        var items: [AuditTask] = []
        for i in 1...42 {
            items.append(AuditTask(
                id: "HIPAA-164.308.\(i)",
                frameworkKey: "HIPAA",
                title: "HIPAA Security Rule §164.308(\(i))",
                category: i <= 20 ? "Administrative Safeguards" : "Technical Safeguards",
                blurb: "HIPAA ePHI data protection requirement.",
                discussion: "HIPAA Security Rule technical and administrative requirement for safeguarding ePHI data stores.",
                controlActivities: "1. Review executed Business Associate Agreements (BAAs).\n2. Audit ePHI access and revocation logs."
            ))
        }
        return items
    }
    
    func buildSOC1Tasks() -> [AuditTask] {
        var items: [AuditTask] = []
        for i in 1...38 {
            items.append(AuditTask(
                id: "SOC1-CTRL-\(i)",
                frameworkKey: "SOC1",
                title: "SOC 1 / SSAE 18 Assertion Control \(i)",
                category: "ICFR Financial Reporting",
                blurb: "Financial reporting internal control assertion.",
                discussion: "SSAE 18 assertion control establishing reasonable assurance over financial reporting processes.",
                controlActivities: "1. Sample transaction authorization records.\n2. Verify management approval sign-offs."
            ))
        }
        return items
    }
    
    func buildFedRAMPTasks() -> [AuditTask] {
        var items: [AuditTask] = []
        for i in 1...325 {
            items.append(AuditTask(
                id: "FEDRAMP-MOD-\(i)",
                frameworkKey: "FEDRAMP",
                title: "FedRAMP Moderate Baseline Control \(i)",
                category: "Moderate Baseline Safeguards",
                blurb: "Federal cloud authorization baseline control.",
                discussion: "FedRAMP Moderate baseline authorization control requirement for cloud service offerings.",
                controlActivities: "1. Review monthly Continuous Monitoring (ConMon) executive package.\n2. Inspect Plan of Action & Milestones (POA&M) logs."
            ))
        }
        return items
    }
    
    func buildGDPRTasks() -> [AuditTask] {
        var items: [AuditTask] = []
        for i in 1...99 {
            items.append(AuditTask(
                id: "GDPR-ART-\(i)",
                frameworkKey: "GDPR",
                title: "EU GDPR Article \(i) Mandate",
                category: "Data Subject Rights & Processing",
                blurb: "EU General Data Protection Regulation privacy mandate.",
                discussion: "General Data Protection Regulation requirement ensuring lawful, fair, and transparent data processing.",
                controlActivities: "1. Inspect Data Protection Impact Assessment (DPIA) registers.\n2. Test Data Subject Access Request (DSAR) fulfillment workflows."
            ))
        }
        return items
    }
}

