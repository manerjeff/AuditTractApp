// === File: ./Models (Data & Persistence)/TaskBuilders.swift ===
//
//  TaskBuilders.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation
import Combine

// MARK: - Audit Estimator Engine
class AuditEstimator: ObservableObject {
    @Published var totalHours: Int = 0
    
    init() {}
    
    static func estimateHours(for tasks: [AuditTask]) -> Int {
        return tasks.count * 2
    }
    
    static func calculateProgress(evaluations: [ControlEvaluation], totalTasks: Int) -> Double {
        guard totalTasks > 0 else { return 0.0 }
        let completed = evaluations.filter { $0.status != "Not Evaluated" }.count
        return Double(completed) / Double(totalTasks)
    }
}

extension AuditEstimator {
    struct FrameworkProgressMetrics {
        let totalControls: Int
        let compliantCount: Int
        let inProgressCount: Int
        let nonCompliantCount: Int
        let completionPercentage: Double
        let scopedFrameworksCount: Int
    }
    
    static func calculateGlobalMetrics(
        tasks: [AuditTask],
        evaluations: [ControlEvaluation],
        frameworks: [FrameworkItem]
    ) -> FrameworkProgressMetrics {
        // Identify active in-scope frameworks based on existing evaluations (or default NIST)
        let scopedKeys = Set(evaluations.map { $0.frameworkKey }).union(["NIST_800_53"])
        
        // Filter tasks that belong to active in-scope frameworks
        let scopedTasks = tasks.filter { task in
            scopedKeys.contains(where: { task.frameworkKey.uppercased().contains($0.uppercased()) })
        }
        
        let total = scopedTasks.isEmpty ? tasks.count : scopedTasks.count
        
        var compliant = 0
        var inProgress = 0
        var nonCompliant = 0
        
        for eval in evaluations {
            switch eval.status.lowercased() {
            case "compliant", "pass", "satisfied":
                compliant += 1
            case "in progress", "partially compliant", "under review":
                inProgress += 1
            case "non-compliant", "fail", "gap":
                nonCompliant += 1
            default:
                break
            }
        }
        
        let percentage = total > 0 ? (Double(compliant) / Double(total)) * 100.0 : 0.0
        
        return FrameworkProgressMetrics(
            totalControls: total,
            compliantCount: compliant,
            inProgressCount: inProgress,
            nonCompliantCount: nonCompliant,
            completionPercentage: min(percentage, 100.0),
            scopedFrameworksCount: scopedKeys.count
        )
    }
}


// MARK: - Extension for Fallback Tasks Ingestion
extension AuditEstimator {
    func buildAllFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        // 1. SOC 2 Controls
        tasks.append(contentsOf: buildSOC2FallbackTasks())
        
        // 2. NIST Controls
        tasks.append(contentsOf: buildNISTFallbackTasks())
        
        // 3. ISO 27001 Controls
        tasks.append(contentsOf: buildISOFallbackTasks())
        
        // 4. HIPAA Controls
        tasks.append(contentsOf: buildHIPAAFallbackTasks())
        
        // 5. SOC 1 Controls
        tasks.append(contentsOf: buildSOC1FallbackTasks())
        
        // 6. FEDRAMP Controls
        tasks.append(contentsOf: buildFedRAMPCMMCFallbackTasks())
        
        // 7. AWS Controls
        tasks.append(contentsOf: buildAWSFallbackTasks())
        
        // 8. FERPA Controls
        tasks.append(contentsOf: buildFERPAFallbackTasks())
        
        // 9. CJIS Controls
        tasks.append(contentsOf: buildCJISFallbackTasks())
        
        // 10. PCIDSS Controls
        tasks.append(contentsOf: buildPCIDSSFallbackTasks())
        
        // 11. SOC 3 Controls
        tasks.append(contentsOf: buildSOC3FallbackTasks())
        
        // 12. SOX Sarbanes Oxley Controls
        tasks.append(contentsOf: buildSOXFallbackTasks())
        
        // 13. SSAE 18 Controls
        tasks.append(contentsOf: buildSSAE18FallbackTasks())
        
        // 14. FISMA Controls
        tasks.append(contentsOf: buildFISMAFallbackTasks())
        
        // 15. HITRUST Controls
        tasks.append(contentsOf: buildHITRUSTFallbackTasks())
        
        // 16. GDPR Controls
        tasks.append(contentsOf: buildGDPRFallbackTasks())
        
        return tasks
    }
    
    func buildSSAE18FallbackTasks() -> [AuditTask] {
            var tasks: [AuditTask] = []

            let ssae18Catalog: [(String, String, String, String, String)] = [
                ("SSAE18-AT-C105", "Attestation Governance", "CPA Independence & Ethical Standards Compliance",
                 "Ensure the independent auditing firm and service organization maintain objective independence and comply with AICPA ethical standards.",
                 "Auditor Engagement Letter, CPA Independence Sign-off"),
                ("SSAE18-AT-C205", "Management Assertion", "Formal Written Assertion of Internal Controls",
                 "Management prepares and signs a written assertion stating that the description of the service organization's system is fairly presented and controls were operating effectively.",
                 "Signed Management Assertion Letter, System Description Document"),
                ("SSAE18-CUEC-01", "Subservice & User Entities", "Complementary User Entity Controls (CUECs) Evaluation",
                 "Define and document Complementary User Entity Controls (CUECs) required for user entities to implement in order to achieve control objectives.",
                 "CUEC Mapping Matrix, Customer Responsibilities Guide"),
                ("SSAE18-CSOC-01", "Subservice Organizations", "Complementary Subservice Organization Controls (CSOCs)",
                 "Assess and monitor subservice vendor SOC reports, verifying the operational effectiveness of CSOCs relied upon by the service organization.",
                 "Subservice Vendor Bridge Letters, Third-Party SOC Review Register"),
                ("SSAE18-PERIOD-01", "Audit Period & Testing", "Type II Audit Period Coverage & Testing Evidence",
                 "Maintain continuous operational evidence throughout the full audit period (typically 6-12 months) for Type II testing without control sampling gaps.",
                 "Population Manifests, Sampling Evidence Registers"),
                ("SSAE18-CHANGE-01", "System Changes", "System Description & Environment Change Disclosures",
                 "Document all significant changes to system architecture, key personnel, or software components made during the audit coverage period.",
                 "System Change Log, Architecture Update Summaries")
            ]

            for (id, category, title, statement, evidence) in ssae18Catalog {
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "SSAE_18",
                        title: title,
                        category: category,
                        blurb: "Verify compliance with AICPA SSAE 18 (AT-C 105/205) attestation standard \(id).",
                        discussion: "Refer to AICPA Codification of Statements on Standards for Attestation Engagements (SSAE No. 18) for service auditor guidelines.",
                        controlStatement: statement,
                        controlActivities: "Inspect signed assertion letters, CUEC matrices, vendor bridge letters, and audit sampling evidence.",
                        examinationObjects: [evidence, "SSAE 18 Audit Readiness Binder", "System Description Manual"],
                        interviewRoles: ["Chief Compliance Officer", "Lead Service Auditor (CPA)", "Vice President of Risk"],
                        relatedControls: ["SOC1-ITGC-01", "SOC2-CC1.1", "ISO-A.5.35"]
                    )
                )
            }

            return tasks
        }
    
    // 2. HITRUST CSF Control Catalog Builder
        func buildHITRUSTFallbackTasks() -> [AuditTask] {
            var tasks: [AuditTask] = []

            let hitrustCatalog: [(String, String, String, String, String)] = [
                ("HITRUST-01.0", "Information Protection", "Information Protection Program Governance",
                 "Establish, maintain, and approve a comprehensive information security program endorsed by executive leadership to protect sensitive healthcare data (ePHI).",
                 "HITRUST Governance Charter, Security Policy Suite"),
                ("HITRUST-02.0", "Access Control", "User Identification & Authentication Management",
                 "Uniquely identify and authenticate all system users accessing ePHI using unique user accounts and multi-factor authentication (MFA).",
                 "IdP Identity Registry Export, MFA Policy Verification"),
                ("HITRUST-03.0", "Human Resources", "Security Awareness Training & Education",
                 "Deliver mandatory security awareness training upon hire and at least annually for all personnel handling sensitive data.",
                 "Security Training Completion Log, Phishing Campaign Reports"),
                ("HITRUST-04.0", "Risk Management", "Comprehensive Risk Assessment Process",
                 "Conduct formal risk assessments annually or upon major technical changes to identify vulnerabilities, threats, and mitigation strategies.",
                 "Enterprise Risk Assessment Report, Risk Remediation Tracker"),
                ("HITRUST-05.0", "Endpoint Security", "Endpoint Device Protection & MDM Enforcement",
                 "Enforce central Mobile Device Management (MDM), disk encryption (AES-256), and remote wipe capabilities across all endpoint hardware.",
                 "MDM Encryption Compliance Export, EDR Console Status"),
                ("HITRUST-06.0", "Network Security", "Network Segmentation & Perimeter Safeguards",
                 "Segregate internal networks, cloud VPC subnets, and processing environments handling sensitive data using firewalls and WAFs.",
                 "Cloud Network Architecture Diagram, Security Group Rules"),
                ("HITRUST-07.0", "Data Protection", "Cryptographic Key Management & Data Protection",
                 "Encrypt all ePHI and sensitive data at rest and in transit using strong cryptography (AES-256 / TLS 1.3) with KMS key rotation.",
                 "KMS Key Rotation Config, TLS Protocols Audit Log"),
                ("HITRUST-08.0", "System Integrity", "Flaw Remediation & Patch Management",
                 "Identify, prioritize, and patch software flaws and OS vulnerabilities within mandated SLA windows (30 days for Critical/High).",
                 "Vulnerability Scan Reports, Automated Patch Manager Logs"),
                ("HITRUST-09.0", "Incident Management", "Security Incident Handling & Breach Escalation",
                 "Maintain incident response procedures to detect, triage, contain, and report security incidents and potential data breaches.",
                 "Incident Response Plan (IRP), Post-Mortem Incident Logs"),
                ("HITRUST-10.0", "Business Continuity", "Disaster Recovery & Data Backup Testing",
                 "Maintain automated, immutable backups and perform annual disaster recovery restoration testing to ensure business continuity.",
                 "Backup Restoration Logs, Annual DR Test Verification")
            ]

            for (id, category, title, statement, evidence) in hitrustCatalog {
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "HITRUST",
                        title: title,
                        category: category,
                        blurb: "Verify compliance with HITRUST CSF v11 security requirement statement \(id).",
                        discussion: "Refer to HITRUST Alliance CSF v11 framework specification and MyCSF Assessor testing guidelines.",
                        controlStatement: statement,
                        controlActivities: "Inspect MDM reports, KMS encryption settings, risk assessment matrices, and DR test logs.",
                        examinationObjects: [evidence, "MyCSF Readiness Workbook", "Validated Assessment Report"],
                        interviewRoles: ["Chief Information Security Officer", "HITRUST Authorized External Assessor", "Director of IT Operations"],
                        relatedControls: ["HIPAA-164.308(a)(1)", "ISO-A.5.1", "SOC2-CC6.1"]
                    )
                )
            }

            return tasks
        }
    
    // 2. FISMA Control Catalog Builder
        func buildFISMAFallbackTasks() -> [AuditTask] {
            var tasks: [AuditTask] = []

            let fismaCatalog: [(String, String, String, String, String)] = [
                ("FISMA-RMF-STEP1", "RMF Categorization", "FIPS 199 System Security Categorization",
                 "Categorize the information system and processed data according to FIPS 199 impact levels (Low, Moderate, High) for Confidentiality, Integrity, and Availability.",
                 "FIPS 199 Categorization Document, Security Impact Analysis"),
                ("FISMA-RMF-STEP2", "RMF Control Selection", "NIST SP 800-53 Control Baseline Selection & SSP",
                 "Select the minimum NIST SP 800-53 control baseline based on system impact level and document tailored controls inside the System Security Plan (SSP).",
                 "System Security Plan (SSP), Control Tailoring Matrix"),
                ("FISMA-RMF-STEP3", "RMF Implementation", "Security Control Implementation & Architecture",
                 "Implement the NIST SP 800-53 controls specified in the SSP and document implementation narratives for all system components.",
                 "Architecture Diagrams, Implementation Narratives"),
                ("FISMA-RMF-STEP4", "RMF Assessment", "Independent Security Assessment & SAR Generation",
                 "Assess system controls using an independent assessment team to verify controls are operating effectively as documented in the Security Assessment Report (SAR).",
                 "Security Assessment Report (SAR), Security Assessment Plan (SAP)"),
                ("FISMA-RMF-STEP5", "RMF Authorization", "Authorizing Official (AO) ATO Decision & POA&M Management",
                 "Obtain a formal Authorization to Operate (ATO) from the Authorizing Official (AO) and maintain an active Plan of Action and Milestones (POA&M) tracker.",
                 "Signed ATO Letter, Active Plan of Action & Milestones (POA&M) Tracker"),
                ("FISMA-RMF-STEP6", "RMF Continuous Monitoring", "Continuous Monitoring (ConMon) & Monthly Reporting",
                 "Monitor system controls on an ongoing basis through automated scans, monthly ConMon reporting, and annual security reviews.",
                 "Monthly ConMon Executive Dashboard, Annual Security Review Sign-off"),
                ("FISMA-INV-01", "Asset Inventory", "Federal System Boundary & Interconnection Inventory",
                 "Maintain a complete inventory of all hardware, software, cloud services, and external system interconnections operating within the FISMA boundary.",
                 "System Boundary Diagram, Interconnection Security Agreements (ISA)"),
                ("FISMA-IR-01", "Incident Response", "US-CERT / DHS Incident Reporting & Response",
                 "Report security incidents to the Cybersecurity and Infrastructure Security Agency (CISA/US-CERT) within required federal reporting windows.",
                 "US-CERT Incident Reporting Protocol, CISA Ticket Exports")
            ]

            for (id, category, title, statement, evidence) in fismaCatalog {
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "FISMA",
                        title: title,
                        category: category,
                        blurb: "Verify compliance with FISMA / NIST SP 800-37 Risk Management Framework requirement \(id).",
                        discussion: "Refer to NIST SP 800-37 Rev 2 (RMF) and NIST SP 800-53 Rev 5 federal compliance baselines.",
                        controlStatement: statement,
                        controlActivities: "Inspect SSP documents, ATO signed letters, POA&M spreadsheets, and CISA incident reporting records.",
                        examinationObjects: [evidence, "NIST RMF Portfolio", "Information System Security Officer (ISSO) Playbook"],
                        interviewRoles: ["Authorizing Official (AO)", "Information System Security Officer (ISSO)", "System Owner"],
                        relatedControls: ["NIST-AC-01", "FedRAMP-CMMC-AC.L2-3.1.1", "ISO-A.5.35"]
                    )
                )
            }

            return tasks
        }
    
    func buildSOXFallbackTasks() -> [AuditTask] {
            var tasks: [AuditTask] = []

            let soxCatalog: [(String, String, String, String, String)] = [
                // --- ACCESS TO PROGRAMS AND DATA ---
                ("SOX-ITGC-AC-01", "Access Controls", "User Provisioning & Management Authorization",
                 "Ensure logical access to financial systems, ERPs, and supporting databases is granted only upon formal management approval.",
                 "Approved Access Request Tickets, Role Privilege Matrix"),
                ("SOX-ITGC-AC-02", "Access Controls", "Quarterly User Access Recertification",
                 "Conduct quarterly reviews of active user accounts and privilege levels across financial applications and databases, revoking inappropriate access.",
                 "Quarterly User Access Review Sign-offs, HR Termination Cross-Check"),
                ("SOX-ITGC-AC-03", "Access Controls", "Privileged Account Governance & PAM Monitoring",
                 "Restrict and monitor administrative and privileged accounts (e.g., DBAs, domain admins) accessing financial reporting environments.",
                 "Privileged Account Inventory, PAM Audit Logs"),
                ("SOX-ITGC-AC-04", "Access Controls", "Timely Termination Access Revocation",
                 "Revoke access to financial IT infrastructure within 24 hours of employee or contractor termination.",
                 "HR Termination Log vs Active Directory Deprovisioning Timestamps"),

                // --- CHANGE MANAGEMENT ---
                ("SOX-ITGC-CM-01", "Change Management", "Program Change Authorization & Approval",
                 "Ensure changes to financial applications and infrastructure are formally requested, authorized, and approved by business owners prior to deployment.",
                 "Jira/ServiceNow Change Tickets, CAB Approval Logs"),
                ("SOX-ITGC-CM-02", "Change Management", "User Acceptance Testing (UAT) & Segregation of Environments",
                 "Require documented User Acceptance Testing (UAT) in a non-production environment prior to promoting financial software changes to production.",
                 "UAT Sign-Off Documents, Environment Isolation Config"),
                ("SOX-ITGC-CM-03", "Change Management", "Segregation of Duties in Deployment (Developer Access)",
                 "Restrict software developers from having write or deployment access to production financial application environments.",
                 "CI/CD Pipeline Permission Export, Production Access Matrix"),
                ("SOX-ITGC-CM-04", "Change Management", "Emergency Production Change Controls",
                 "Document, review, and retroactively approve emergency code fixes or database changes impacting financial processing.",
                 "Emergency Change Ticket Log, Retrospective CAB Sign-off"),

                // --- COMPUTER OPERATIONS ---
                ("SOX-ITGC-OP-01", "Computer Operations", "Batch Job Monitoring & Interface Reconciliations",
                 "Monitor automated batch processing schedules and financial interface jobs, investigating and resolving processing failures promptly.",
                 "Batch Scheduler Failure Logs, Interface Exception Tickets"),
                ("SOX-ITGC-OP-02", "Computer Operations", "Financial Database Backup & Restoration Testing",
                 "Execute automated daily backups of financial databases and perform periodic restoration tests to verify operational recovery capabilities.",
                 "Daily Backup Completion Dashboard, Bi-Annual Restore Test Verification")
            ]

            for (id, category, title, statement, evidence) in soxCatalog {
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "SOX_ITGC",
                        title: title,
                        category: category,
                        blurb: "Verify internal controls over financial reporting (ICFR) for SOX Section 404 requirement \(id).",
                        discussion: "Refer to PCAOB Auditing Standard No. 2201 (An Audit of Internal Control Over Financial Reporting That Is Integrated with An Audit of Financial Statements) and COSO framework guidelines.",
                        controlStatement: statement,
                        controlActivities: "Inspect access request sign-offs, change tickets, UAT test results, and batch job completion logs.",
                        examinationObjects: [evidence, "SOX ITGC Matrix", "PCAOB Testing Sample Log"],
                        interviewRoles: ["Chief Accounting Officer (CAO)", "IT Audit Director", "Enterprise Applications Manager"],
                        relatedControls: ["SOC1-ITGC-01", "ISO-A.8.32", "SOC2-CC6.1"]
                    )
                )
            }

            return tasks
        }
    
    func buildAWSFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let awsCatalog: [(String, String, String, String, String)] = [
            // --- IDENTITY AND ACCESS MANAGEMENT ---
            ("AWS-IAM-01", "Identity & Access Management", "Enforce Root Account MFA & Root Key Elimination",
             "Ensure AWS account root user has multi-factor authentication (MFA) enabled and root access keys are deleted.",
             "AWS IAM Credential Report, Security Hub IAM.1 finding"),
            ("AWS-IAM-02", "Identity & Access Management", "Least Privilege IAM Policies & Role Delegation",
             "Ensure IAM policies enforce least-privilege permissions and temporary credentials via AWS STS roles are used instead of long-lived access keys.",
             "IAM Access Analyzer Findings, AWS Identity Center Config"),
            ("AWS-IAM-03", "Identity & Access Management", "Unused Credential Revocation",
             "Ensure credentials and access keys unused for 90 days or more are automatically disabled.",
             "IAM Credential Report Automated Lambda Audit"),
            
            // --- DATA PROTECTION & STORAGE ---
            ("AWS-S3-01", "Data Protection & S3", "S3 Block Public Access & Default SSE-KMS",
             "Ensure S3 buckets enforce Block Public Access at the account level and use default server-side encryption with AWS KMS.",
             "S3 Account-Level Public Access Block Export, KMS Policy"),
            ("AWS-S3-02", "Data Protection & S3", "S3 Bucket Versioning & Lifecycle Management",
             "Ensure MFA Delete and object versioning are enabled for critical S3 buckets.",
             "S3 Bucket Configuration JSON Export"),
            ("AWS-RDS-01", "Data Protection & Database", "RDS Instance Encryption & Public Reachability",
             "Ensure RDS DB instances and snapshots are encrypted at rest with KMS and not publicly accessible.",
             "AWS Config Rule rds-storage-encrypted, RDS Console Export"),
            
            // --- DETECTIVE CONTROLS & LOGGING ---
            ("AWS-LOG-01", "Logging & Monitoring", "Multi-Region CloudTrail & S3 Log Validation",
             "Ensure AWS CloudTrail is enabled across all regions with log file integrity validation enabled and sending to a write-protected bucket.",
             "CloudTrail Trail Configuration Export, KMS Key Policy"),
            ("AWS-LOG-02", "Logging & Monitoring", "GuardDuty & Security Hub Activation",
             "Ensure Amazon GuardDuty threat detection and AWS Security Hub are active across all regional accounts.",
             "Security Hub Standards Subscription Output, GuardDuty Status"),
            
            // --- INFRASTRUCTURE PROTECTION & NETWORKING ---
            ("AWS-NET-01", "Network Security", "VPC Flow Logs & Default Security Group Lockdown",
             "Ensure VPC Flow Logs are enabled for all VPCs and default security groups restrict all inbound and outbound traffic.",
             "VPC Flow Log CloudWatch Subscription, Security Group Rules"),
            ("AWS-NET-02", "Network Security", "Restricted Administrative Ports (22 & 3389)",
             "Ensure no security groups allow unrestricted inbound access (0.0.0.0/0) to SSH (22) or RDP (3389).",
             "AWS Config Rule vpc-sg-open-only-to-authorized-ports"),
            
            // --- CONFIGURATION & VULNERABILITY MANAGEMENT ---
            ("AWS-CFG-01", "Configuration & Vulnerability", "AWS Config Enablement & Conformance Packs",
             "Ensure AWS Config is enabled in all regions to record resource configuration changes and evaluate compliance rules.",
             "AWS Config Recorder Status, Conformance Pack Compliance Report"),
            ("AWS-EC2-01", "System Hardening", "Amazon Inspector Automated EC2 & ECR Scans",
             "Ensure Amazon Inspector is active for automated vulnerability scanning of EC2 instances and ECR container images.",
             "Amazon Inspector Finding Export, SSM Patch Manager Status")
        ]
        
        for (id, category, title, statement, evidence) in awsCatalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "AWS_SECURITY",
                    title: title,
                    category: category,
                    blurb: "Verify compliance with AWS Foundational Security Best Practice / Well-Architected Security Pillar control \(id).",
                    discussion: "Refer to AWS Security Hub control standards and AWS Well-Architected Framework Security Pillar whitepapers.",
                    controlStatement: statement,
                    controlActivities: "Inspect AWS Config rule evaluations, Security Hub findings, IAM credential reports, and CLI configuration outputs.",
                    examinationObjects: [evidence, "AWS Security Reference Architecture (SRA)", "System Security Plan"],
                    interviewRoles: ["Cloud Security Engineer", "Lead Cloud Architect", "DevSecOps Lead"],
                    relatedControls: ["NIST-AC-02", "ISO-A.8.9", "SOC2-CC6.1"]
                )
            )
        }
        
        return tasks
    }
    
    // 2. CJIS Control Catalog Builder
    func buildCJISFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let cjisCatalog: [(String, String, String, String, String)] = [
            ("CJIS-PA01-01", "Information Exchange", "Interagency Agreements & CJIS Security Addendums",
             "Ensure all contractors, vendors, and external agencies accessing CJI execute a formal CJIS Security Addendum signed by the designated Agency Information Security Officer (AISO).",
             "Executed CJIS Security Addendums, Vendor Management Register"),
            ("CJIS-PA03-01", "Personnel Security", "Fingerprint-Based Background Checks (10-Year)",
             "Conduct state and national fingerprint-based background checks for all personnel with unescorted physical or logical access to unencrypted CJI prior to granting access.",
             "Fingerprint Clearance Audit Log, Background Check Verification Sheets"),
            ("CJIS-PA03-02", "Personnel Security", "Personnel Security Awareness Training",
             "Deliver Level 1 - Level 4 Security Awareness Training to all individuals granted access to CJI within 6 months of initial assignment and biennially thereafter.",
             "CJIS Online Security Awareness Training Certificates"),
            ("CJIS-PA05-01", "Access Control", "Advanced Authentication (Multi-Factor Authentication)",
             "Enforce Advanced Authentication (MFA) utilizing at least two distinct factors for all access to CJI originating from outside the physically secure location.",
             "FIPS 140-2/3 MFA Token Configuration, Radius/IdP Audit Exports"),
            ("CJIS-PA05-02", "Access Control", "Session Lock & Timeout Enforcements",
             "Enforce automatic system lock after 30 minutes of inactivity, requiring re-authentication to unlock screens accessing CJI.",
             "GPO Group Policy Export, Endpoint Configuration Benchmark"),
            ("CJIS-PA05-03", "Access Control", "Unsuccessful Logon Attempts & Account Lockout",
             "Enforce system lockout after no more than 5 consecutive invalid logon attempts, requiring administrator intervention or a 15-minute lock delay.",
             "Active Directory / IdP Account Lockout Threshold Policy"),
            ("CJIS-PA06-01", "Audit & Accountability", "Auditable Events & Centralized Log Generation",
             "Generate centralized audit logs recording user logons, logoffs, access attempts to CJI, administrative privilege escalation, and failed system events.",
             "SIEM Ingestion Config, Centralized Log Retention Policy"),
            ("CJIS-PA07-01", "Physical Protection", "Physical Security Perimeter & Visitor Management",
             "Restrict physical access to facilities processing CJI using keycards/locks and maintain visitor logs with mandatory escorts.",
             "Physical Badge Access Logs, Visitor Registration Manifest"),
            ("CJIS-PA08-01", "Media Protection", "Physical & Electronic Media Sanitization",
             "Sanitize or physically destroy electronic and physical media containing CJI prior to disposal or reuse in accordance with NIST SP 800-88 guidelines.",
             "NIST 800-88 Media Sanitization Logs, Physical Destruction Certificates"),
            ("CJIS-PA10-01", "System & Communications", "FIPS 140-2/3 Cryptographic Protection in Transit & at Rest",
             "Encrypt all CJI stored at rest or transmitted over public or unsecure networks using FIPS 140-2 or 140-3 validated cryptographic modules.",
             "FIPS CMVP Module Certificates, TLS 1.3 / IPsec VPN Cryptographic Audits")
        ]
        
        for (id, category, title, statement, evidence) in cjisCatalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "CJIS",
                    title: title,
                    category: category,
                    blurb: "Verify compliance with FBI CJIS Security Policy requirement \(id).",
                    discussion: "Refer to FBI CJIS Security Policy Version 5.9+ guidelines and CJIS Advisory Policy Board (APB) standards.",
                    controlStatement: statement,
                    controlActivities: "Inspect fingerprint clearance records, FIPS cryptographic validation certificates, CJIS Security Addendums, and MFA logs.",
                    examinationObjects: [evidence, "CJIS System Security Plan (SSP)", "Agency Information Security Officer (AISO) Roster"],
                    interviewRoles: ["Agency Information Security Officer (AISO)", "Terminal Agency Controller (TAC)", "CISO"],
                    relatedControls: ["NIST-AC-02", "ISO-A.8.24", "FedRAMP-CMMC-AC.L2-3.1.1"]
                )
            )
        }
        
        return tasks
    }
    
    // 2. SOC 3 Control Catalog Builder
        func buildSOC3FallbackTasks() -> [AuditTask] {
            var tasks: [AuditTask] = []

            let soc3Catalog: [(String, String, String, String, String)] = [
                ("SOC3-CC1.1", "Control Environment", "Public Security Commitment & Executive Governance",
                 "Management publishes security commitments and operational integrity guidelines available to general public stakeholders.",
                 "Public Trust Center Portal, Signed Ethics Code"),
                ("SOC3-CC2.1", "Communication & Information", "System Boundaries & Description Transparency",
                 "Maintain an up-to-date, publicly dispensable system description outlining system boundaries, operational components, and data safeguards.",
                 "System Description Document, Public Security Whitepaper"),
                ("SOC3-CC6.1", "Access Control", "Logical Access Safeguards over Public Infrastructure",
                 "Enforce identity verification and access restrictions protecting core platform infrastructure from unauthorized public modification.",
                 "IdP Access Audit Export, MFA Policy Verification"),
                ("SOC3-CC6.7", "Data Protection", "Public Data Transmission & Transport Encryption",
                 "Protect public-facing applications and data in transit using industry-standard TLS encryption algorithms.",
                 "SSL/TLS Certificate Audit Log, HTTPS Enforcement Verification"),
                ("SOC3-CC7.1", "System Operations", "Continuous Vulnerability Monitoring & Patch Management",
                 "Maintain continuous vulnerability scanning and remediation SLAs across all public-facing edge infrastructure.",
                 "Public Asset Vulnerability Scan Export, Patch SLA Metrics"),
                ("SOC3-A1.1", "Availability", "System Uptime & Public Service Level Agreements (SLAs)",
                 "Monitor system operational capacity and maintain publicly accessible service availability metrics.",
                 "Public Status Page Logs, Uptime SLA Reports"),
                ("SOC3-C1.1", "Confidentiality", "Customer Data Confidentiality & Privacy Disclosures",
                 "Disclose confidential data processing commitments and enforce privacy policies across all public interactions.",
                 "Public Privacy Policy, Customer DPA Register"),
                ("SOC3-REP-01", "Audit Reporting", "Independent Service Auditor's SOC 3 Summary Attestation",
                 "Obtain an annual independent CPA firm attestation report (SOC 3) for public distribution without disclosing sensitive operational details.",
                 "Executed SOC 3 Attestation Report, CPA Management Assertion")
            ]

            for (id, category, title, statement, evidence) in soc3Catalog {
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "SOC_3",
                        title: title,
                        category: category,
                        blurb: "Verify compliance with AICPA SOC 3 general use trust criteria control \(id).",
                        discussion: "Refer to AICPA SSAE 18 (AT-C Section 205) guidance for public-facing SOC 3 trust services reports.",
                        controlStatement: statement,
                        controlActivities: "Inspect public security whitepapers, CPA assertion letters, SSL audit reports, and status page logs.",
                        examinationObjects: [evidence, "AICPA SOC 3 Audit Guide", "Public Trust Center Export"],
                        interviewRoles: ["Chief Compliance Officer", "Lead Service Auditor (CPA)", "Public Relations Lead"],
                        relatedControls: ["SOC2-CC1.1", "ISO-A.5.1", "NIST-AC-01"]
                    )
                )
            }

            return tasks
        }
    }
    
    func buildFedRAMPCMMCFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let fedCmmcCatalog: [(String, String, String, String, String)] = [
            ("CMMC-AC.L2-3.1.1", "Access Control", "Authorized Access Enforcement",
             "Limit system access to authorized users, processes acting on behalf of authorized users, and devices.",
             "Active Directory User Export, IAM Role Matrix"),
            ("CMMC-AC.L2-3.1.2", "Access Control", "Transaction & Function Control",
             "Limit system access to the types of transactions and functions that authorized users are permitted to execute.",
             "RBAC Privilege Matrix, PIV/CAC Enforcement Configuration"),
            ("CMMC-AC.L2-3.1.12", "Access Control", "Remote Access Encryption & Control",
             "Monitor and control remote access sessions using FIPS-validated cryptographic modules.",
             "FIPS 140-2/3 Cryptographic Verification, VPN Logs"),
            ("CMMC-AT.L2-3.2.1", "Awareness & Training", "Role-Based Security Training",
             "Ensure that managers, systems administrators, and users are trained on security risks associated with CUI/FedRAMP systems.",
             "CUI Handling Training Records, Cyber Awareness Challenge Certs"),
            ("CMMC-AU.L2-3.3.1", "Audit & Accountability", "System Event Audit Logging",
             "Create and retain system audit logs and records to the extent needed to enable monitoring, analysis, and investigation of unlawful or unauthorized system activity.",
             "Centralized SIEM Ingestion Dashboard, Log Retention Spec"),
            ("CMMC-AU.L2-3.3.2", "Audit & Accountability", "Auditable Events & Analysis",
             "Ensure that the actions of individual system users can be uniquely traced to those users.",
             "Audit Record Schema, Non-Repudiation Policy"),
            ("CMMC-CM.L2-3.4.1", "Configuration Management", "Baseline Configuration Maintenance",
             "Establish and maintain baseline configurations and inventories of organizational systems throughout the software development lifecycle.",
             "Hardening Benchmarks (CIS/STIG), Infrastructure-as-Code Repos"),
            ("CMMC-CM.L2-3.4.2", "Configuration Management", "Enforce Security Configuration Settings",
             "Establish and enforce security configuration settings for information technology products employed in organizational systems.",
             "DISA STIG Automated Compliance Scan Reports"),
            ("CMMC-IA.L2-3.5.3", "Identification & Authentication", "Multi-Factor Authentication (MFA)",
             "Use multi-factor authentication (MFA) for local and network access to privileged and non-privileged accounts.",
             "Phishing-Resistant MFA Config (Hardware Tokens / WebAuthn)"),
            ("CMMC-IR.L2-3.6.1", "Incident Response", "Incident Handling & Reporting",
             "Establish an operational incident-handling capability and report incidents to US-CERT / DIBNET within mandated timelines.",
             "FedRAMP Incident Response Plan, 72-Hour Breach Notification Protocol"),
            ("CMMC-MP.L2-3.8.3", "Media Protection", "Sanitization & Destruction of CUI Media",
             "Sanitize or destroy system media containing Controlled Unclassified Information (CUI) before disposal or release for reuse.",
             "NIST 800-88 Media Sanitization Records"),
            ("CMMC-PE.L2-3.10.1", "Physical Protection", "Physical Facility Safeguards",
             "Limit physical access to organizational systems, equipment, and operating environments to authorized individuals.",
             "FedRAMP Boundary Security Assessment, Badge Log Export"),
            ("CMMC-RA.L2-3.11.2", "Risk Assessment", "Vulnerability Scanning & Remediation",
             "Scan for vulnerabilities in organizational systems and applications periodically and remediate high-risk findings in accordance with POA&M guidelines.",
             "Monthly Vulnerability Scan Export, Plan of Action & Milestones (POA&M) Tracker"),
            ("CMMC-SC.L2-3.13.11", "System & Communications", "FIPS Cryptography in Transit & at Rest",
             "Employ FIPS-validated cryptography when protecting the confidentiality of CUI.",
             "FIPS Cryptographic Module Validation Program (CMVP) Certificates"),
            ("CMMC-SI.L2-3.14.1", "System Integrity", "Flaw Remediation & Patch Management",
             "Identify, report, and correct system flaws in a timely manner according to FedRAMP SLAs (30 days for Critical/High).",
             "Automated Patch Management Logs, SLA Compliance Metrics")
        ]
        
        for (id, category, title, statement, evidence) in fedCmmcCatalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "FEDRAMP_CMMC",
                    title: title,
                    category: category,
                    blurb: "Verify compliance with FedRAMP Moderate / CMMC 2.0 Level 2 practice \(id).",
                    discussion: "Refer to NIST SP 800-171 Rev 2 / NIST SP 800-53 Rev 5 federal baseline guidance and CMMC assessment guides.",
                    controlStatement: statement,
                    controlActivities: "Inspect DISA STIG benchmarks, FIPS encryption validation, SSP/POA&M artifacts, and SIEM logs.",
                    examinationObjects: [evidence, "System Security Plan (SSP)", "Plan of Action & Milestones (POA&M)"],
                    interviewRoles: ["Information System Security Officer (ISSO)", "CISO", "Lead Cloud Architect"],
                    relatedControls: ["NIST-AC-02", "ISO-A.8.2", "SOC2-CC6.1"]
                )
            )
        }
        
        return tasks
    }
    
func buildGDPRFallbackTasks() -> [AuditTask] {
    var tasks: [AuditTask] = []

    let gdprCatalog: [(String, String, String, String, String)] = [
        ("GDPR-ART-06", "Lawfulness of Processing", "Lawful Basis & Consent Management",
         "Establish and document a legal basis (e.g., explicit consent, legitimate interest, contractual necessity) for processing personal data.",
         "Data Processing Register, Consent Banner Audit Log"),
        ("GDPR-ART-15", "Data Subject Rights", "Right of Access & DSAR Fulfillment Workflow",
         "Establish procedures to handle Data Subject Access Requests (DSARs) and provide users access to their personal data within 30 days.",
         "DSAR Workflow Manual, 30-Day SLA Completion Register"),
        ("GDPR-ART-17", "Data Subject Rights", "Right to Erasure (Right to be Forgotten)",
         "Implement technical mechanisms to permanently purge data subject records upon request across all production databases and backup archives.",
         "Data Purge Script Logs, Erasure Verification Records"),
        ("GDPR-ART-25", "Privacy by Design", "Data Protection by Design and Default",
         "Integrate pseudonymization, data minimization, and technical access safeguards into new software development lifecycles.",
         "Data Protection Impact Assessment (DPIA), SDLC Privacy Review"),
        ("GDPR-ART-32", "Security of Processing", "Technical Safeguards & Encryption Controls",
         "Implement state-of-the-art technical safeguards, including AES-256 encryption at rest, TLS 1.3 in transit, and continuous confidentiality testing.",
         "KMS Encryption Policies, Penetration Test Summary"),
        ("GDPR-ART-33", "Incident Response", "72-Hour Personal Data Breach Notification",
         "Maintain procedures to detect, document, and report personal data breaches to supervisory authorities within 72 hours of discovery.",
         "Privacy Incident Response Plan, Supervisory Breach Logs"),
        ("GDPR-ART-44", "Data Sovereignty", "International Data Transfer Safeguards",
         "Ensure international transfers of personal data outside the EEA/UK rely on valid transfer mechanisms (e.g., Standard Contractual Clauses, EU-US Data Privacy Framework).",
         "Executed SCCs / DPAs, Data Flow Architecture Diagram")
    ]

    for (id, category, title, statement, evidence) in gdprCatalog {
        tasks.append(
            AuditTask(
                id: id,
                frameworkKey: "GDPR_PRIVACY",
                title: title,
                category: category,
                blurb: "Verify compliance with GDPR / CCPA privacy regulation statement \(id).",
                discussion: "Refer to EU General Data Protection Regulation (2016/679) and California Consumer Privacy Act (CCPA/CPRA) guidelines.",
                controlStatement: statement,
                controlActivities: "Inspect DSAR logs, DPIA documents, Standard Contractual Clauses (SCCs), and encryption configs.",
                examinationObjects: [evidence, "Data Inventory & Mapping Register", "Privacy Policy"],
                interviewRoles: ["Data Protection Officer (DPO)", "Chief Privacy Officer", "Lead Backend Architect"],
                relatedControls: ["ISO-A.5.34", "HIPAA-164.308(a)(1)", "SOC2-C1.1"]
            )
        )
    }

    return tasks
}

// 3. Complete PCI DSS v4.0 Control Builder
        func buildPCIDSSFallbackTasks() -> [AuditTask] {
            var tasks: [AuditTask] = []

            let pciCatalog: [(String, String, String, String, String)] = [
                ("PCI-REQ-01", "Network Security", "Install and Maintain Network Security Controls",
                 "Configure and maintain Network Security Controls (firewalls and cloud security groups) to protect the Cardholder Data Environment (CDE).",
                 "Firewall Rule Base Export, Network Architecture Diagram"),
                ("PCI-REQ-02", "System Configuration", "Apply Secure Configurations to All System Components",
                 "Remove vendor-default passwords and apply hardened baseline configurations to all systems in the CDE.",
                 "Hardening Benchmark (CIS), Default Credential Audit"),
                ("PCI-REQ-03", "Data Protection", "Protect Stored Account Data",
                 "Protect stored primary account numbers (PAN) using strong cryptography (AES-256) and enforce key management lifecycle controls.",
                 "KMS Key Policy, PAN Storage Scan Audit Report"),
                ("PCI-REQ-04", "Data Protection", "Protect Cardholder Data in Transit",
                 "Encrypt primary account numbers during transmission over open, public networks using strong cryptography (TLS 1.2/1.3).",
                 "TLS Certificate Cipher Audit, Internal Network Scan"),
                ("PCI-REQ-05", "Malware Defense", "Protect Systems from Malicious Software",
                 "Deploy and maintain anti-malware/EDR software on all system components that actively detects and remediates threats.",
                 "EDR Central Management Console Export"),
                ("PCI-REQ-06", "Application Security", "Develop and Maintain Secure Systems and Software",
                 "Enforce secure software development lifecycles (SDLC), perform vulnerability scanning, and deploy Web Application Firewalls (WAF).",
                 "SAST/DAST Scan Reports, WAF Configuration Log"),
                ("PCI-REQ-07", "Access Control", "Restrict Access to System Components by Business Need",
                 "Restrict logical access to cardholder data based on job responsibilities and least privilege.",
                 "Role-Based Access Matrix, Access Approval Tickets"),
                ("PCI-REQ-08", "Identification & Authentication", "Authenticate Users and Secure Access",
                 "Assign unique IDs to each user and enforce Multi-Factor Authentication (MFA) for all access to the CDE.",
                 "IAM Policy Export, MFA Enforcement Logs"),
                ("PCI-REQ-09", "Physical Security", "Restrict Physical Access to Cardholder Data",
                 "Restrict physical access to facilities, data centers, and paper media containing cardholder data.",
                 "Physical Badge Logs, CCTV Retention Logs"),
                ("PCI-REQ-10", "Logging & Auditing", "Log and Monitor All Access to System Components",
                 "Log and monitor all user access to cardholder data and centralize audit logs into a write-protected SIEM.",
                 "SIEM Log Pipeline Export, Daily Audit Review Log"),
                ("PCI-REQ-11", "Security Testing", "Test Security of Systems and Networks Regularly",
                 "Perform quarterly internal/external vulnerability scans (ASV) and annual penetration testing of CDE boundaries.",
                 "Approved Scanning Vendor (ASV) Scan Reports, Pen Test Findings"),
                ("PCI-REQ-12", "Governance", "Support Information Security with Organizational Policies",
                 "Maintain comprehensive information security policies, annual risk assessments, and vendor risk management programs.",
                 "Information Security Policy Manual, Vendor Attestation of Compliance (AOC)")
            ]

            for (id, category, title, statement, evidence) in pciCatalog {
                tasks.append(
                    AuditTask(
                        id: id,
                        frameworkKey: "PCI_DSS",
                        title: title,
                        category: category,
                        blurb: "Verify compliance with PCI DSS v4.0 Requirement \(id).",
                        discussion: "Refer to PCI Security Standards Council (PCI SSC) PCI DSS v4.0 standard and Qualified Security Assessor (QSA) audit guidance.",
                        controlStatement: statement,
                        controlActivities: "Inspect ASV scan results, network diagrams, KMS key logs, and Attestations of Compliance (AOC).",
                        examinationObjects: [evidence, "Report on Compliance (ROC)", "Self-Assessment Questionnaire (SAQ-D)"],
                        interviewRoles: ["Chief Information Security Officer", "Lead QSA Assessor", "Payments Infrastructure Architect"],
                        relatedControls: ["NIST-AC-02", "ISO-A.8.24", "SOC2-CC6.1"]
                    )
                )
            }

            return tasks
        }
    
    func buildSOC2FallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let soc2FullCatalog: [(String, String, String, String, String)] = [
            ("SOC2-CC1.1", "CC1 Control Environment", "Commitment to Integrity and Ethical Values",
             "The entity demonstrates a commitment to integrity and ethical values through defined conduct standards.",
             "Code of Conduct Policy, Signed Policy Acknowledgments"),
            ("SOC2-CC1.2", "CC1 Control Environment", "Board Governance & Oversight",
             "The board of directors demonstrates independence from management and exercises oversight of internal control.",
             "Board Meeting Minutes, Charter Documents"),
            ("SOC2-CC1.3", "CC1 Control Environment", "Organizational Structure & Authority",
             "Management establishes structures, reporting lines, and appropriate authorities and responsibilities.",
             "Organizational Chart, Job Descriptions"),
            ("SOC2-CC1.4", "CC1 Control Environment", "Commitment to Competence",
             "The entity demonstrates a commitment to attract, develop, and retain competent individuals.",
             "HR Hiring Guidelines, Employee Performance Reviews"),
            ("SOC2-CC1.5", "CC1 Control Environment", "Accountability for Control Responsibilities",
             "The entity holds individuals accountable for their internal control responsibilities.",
             "Performance Evaluation Metrics, Disciplinary Policy"),
            ("SOC2-CC2.1", "CC2 Communication & Information", "Internal Quality Information Usage",
             "The entity obtains or generates and uses relevant, quality information to support internal control.",
             "System Data Quality Reports, Operational Dashboards"),
            ("SOC2-CC2.2", "CC2 Communication & Information", "Internal Security Communication",
             "The entity internally communicates security objectives and control responsibilities.",
             "All-Hands Presentation Slides, Security Slack Channel Logs"),
            ("SOC2-CC2.3", "CC2 Communication & Information", "External Party Communication",
             "The entity communicates with external parties regarding matters affecting the functioning of internal control.",
             "Customer Privacy Notice, Vendor Management Terms"),
            ("SOC2-CC3.1", "CC3 Risk Assessment", "Objective Identification & Risk Alignment",
             "The entity specifies objectives with sufficient clarity to enable the identification and assessment of risks.",
             "Enterprise Risk Management Framework"),
            ("SOC2-CC3.2", "CC3 Risk Assessment", "Risk Identification & Analysis",
             "The entity identifies risks to the achievement of its objectives across the entity and analyzes risks.",
             "Annual Risk Assessment Register"),
            ("SOC2-CC3.3", "CC3 Risk Assessment", "Fraud Risk Consideration",
             "The entity considers the potential for fraud in assessing risks to the achievement of objectives.",
             "Fraud Risk Assessment Report"),
            ("SOC2-CC3.4", "CC3 Risk Assessment", "Significant Change Analysis",
             "The entity identifies and assesses changes that could significantly impact the system of internal control.",
             "Business Impact Analysis (BIA) Document"),
            ("SOC2-CC4.1", "CC4 Monitoring Activities", "Ongoing & Separate Evaluations",
             "The entity selects, develops, and performs ongoing and/or separate evaluations of internal controls.",
             "Internal Audit Reports, Compliance Monitoring Schedule"),
            ("SOC2-CC4.2", "CC4 Monitoring Activities", "Control Deficiency Communication",
             "The entity evaluates and communicates internal control deficiencies in a timely manner.",
             "CAPA (Corrective Action Plan) Tracker"),
            ("SOC2-CC5.1", "CC5 Control Activities", "Risk Mitigation Control Selection",
             "The entity selects and develops control activities that contribute to the mitigation of risks.",
             "Internal Control Matrix"),
            ("SOC2-CC5.2", "CC5 Control Activities", "Technology Infrastructure Controls",
             "The entity selects and develops general control activities over technology to support objectives.",
             "IT General Controls (ITGC) Policy"),
            ("SOC2-CC5.3", "CC5 Control Activities", "Policy & Procedure Deployment",
             "The entity deploys control activities through policies that establish expectations and procedures.",
             "Standard Operating Procedures (SOPs) Library"),
            ("SOC2-CC6.1", "CC6 Access Control", "Logical Access Infrastructure",
             "The entity implements logical access security software, infrastructure, and architectures.",
             "SSO / IdP Configuration Export, IAM Policy"),
            ("SOC2-CC6.2", "CC6 Access Control", "User Registration & Rights Provisioning",
             "User registration, authentication, and access authorization are managed systematically.",
             "Access Request Tickets, Quarterly User Access Review Sign-offs"),
            ("SOC2-CC6.3", "CC6 Access Control", "Least Privilege & Revocation",
             "Access rights are granted based on least privilege and revoked promptly upon termination.",
             "Terminated Employee Access Revocation Audit Log"),
            ("SOC2-CC6.4", "CC6 Access Control", "Physical Access Safeguards",
             "Physical access to facilities, data centers, and storage media is restricted to authorized personnel.",
             "Data Center Access Badge Logs, Visitor Escort Logs"),
            ("SOC2-CC6.5", "CC6 Access Control", "Disposal of Physical & Logical Assets",
             "Assets containing sensitive data are sanitized or destroyed prior to disposal.",
             "Certificate of Data Sanitization / Media Destruction"),
            ("SOC2-CC6.6", "CC6 Access Control", "Perimeter Defense & Threat Protection",
             "Boundaries of the system are protected using firewalls, proxies, and intrusion prevention.",
             "WAF & Firewall Rulebase Exports"),
            ("SOC2-CC6.7", "CC6 Access Control", "Data In-Transit & At-Rest Encryption",
             "Data is protected against unauthorized transmission, alteration, or exposure during transport and storage.",
             "TLS Certificate Validation Logs, KMS Encryption Status"),
            ("SOC2-CC6.8", "CC6 Access Control", "Malware & Ransomware Safeguards",
             "The entity implements controls to prevent or detect malicious software.",
             "EDR / Antivirus Central Management Dashboard Export"),
            ("SOC2-CC7.1", "CC7 System Operations", "Vulnerability & Threat Management",
             "Infrastructure and software components are monitored for security vulnerabilities.",
             "Monthly Vulnerability Scan Results & Remediation Tickets"),
            ("SOC2-CC7.2", "CC7 System Operations", "Anomalous Activity Detection",
             "The entity monitors system execution and baseline operations to detect anomalies and security events.",
             "SIEM Alerting Rules, SOC Escalation Logs"),
            ("SOC2-CC7.3", "CC7 System Operations", "Incident Response & Triaging",
             "The entity evaluates security incidents and executes response procedures.",
             "Incident Management Post-Mortem Reports"),
            ("SOC2-CC7.4", "CC7 System Operations", "Business Continuity & Disaster Recovery Testing",
             "The entity plans and periodically tests backup and disaster recovery capabilities.",
             "Annual DR Test Summary & Backup Restoration Verification"),
            ("SOC2-CC8.1", "CC8 Change Management", "System Change Authorization & Testing",
             "Changes to infrastructure, data, and software are authorized, tested, and approved prior to release.",
             "Pull Request Code Reviews, CI/CD Pipeline Deployment Logs"),
            ("SOC2-CC9.1", "CC9 Risk Mitigation", "Vendor & Third-Party Risk Management",
             "The entity assesses and manages risks associated with vendors, subservice organizations, and partners.",
             "Vendor SOC Report Reviews, Third-Party Risk Register"),
            ("SOC2-CC9.2", "CC9 Risk Mitigation", "Vendor Contract Safeguards",
             "Contracts with vendors establish required security requirements and performance metrics.",
             "Vendor MSA Security Addendums"),
            ("SOC2-A1.1", "A1 Availability", "Capacity & Performance Management",
             "System capacity and environmental constraints are monitored to maintain availability.",
             "Load Testing Reports, Auto-scaling Monitoring Logs"),
            ("SOC2-A1.2", "A1 Availability", "Data Backup & Recovery Operations",
             "Environmental protections and backup operations maintain system operational readiness.",
             "Automated Database Backup Verification Logs"),
            ("SOC2-A1.3", "A1 Availability", "Disaster Recovery Execution Plan",
             "Disaster recovery procedures are maintained and executed during unexpected outages.",
             "Disaster Recovery Plan (DRP) Execution Log"),
            ("SOC2-C1.1", "C1 Confidentiality", "Confidential Data Classification & Handling",
             "Confidential information is identified, classified, and handled according to restrictions.",
             "Data Classification Standard, DLP Rules"),
            ("SOC2-C1.2", "C1 Confidentiality", "Confidentiality Disposal & Retention",
             "Confidential information is destroyed or returned in accordance with customer commitments.",
             "Data Retention Policy, Purge Script Logs")
        ]
        
        for (id, category, title, statement, evidence) in soc2FullCatalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "SOC_2",
                    title: title,
                    category: category,
                    blurb: "Verify operational effectiveness for SOC 2 Trust Services Criteria \(id).",
                    discussion: "Refer to AICPA Trust Services Criteria (2017 Architecture) for illustrative controls and auditor focus points.",
                    controlStatement: statement,
                    controlActivities: "Inspect administrative records, automated system exports, and sample evidence artifacts.",
                    examinationObjects: [evidence, "AICPA TSC Alignment Document", "Internal Policy Register"],
                    interviewRoles: ["CISO", "Lead Compliance Auditor", "IT Systems Owner"],
                    relatedControls: ["NIST-AC-01", "ISO-A.5.1"]
                )
            )
        }
        
        return tasks
    }
    
    // 2. FERPA Control Catalog Builder
    func buildFERPAFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let ferpaCatalog: [(String, String, String, String, String)] = [
            // --- ACCESS CONTROL & LEGITIMATE EDUCATIONAL INTEREST (34 CFR § 99.31) ---
            ("FERPA-34CFR-99.31", "Access Control & Consent", "Written Consent & Disclosure Exceptions",
             "Obtain prior written consent from parent or eligible student before disclosing PII from education records, unless permitted under statutory exceptions (e.g., school officials with legitimate educational interest).",
             "Parent/Student Written Consent Forms, Legitimate Educational Interest Policy"),
            ("FERPA-34CFR-99.32", "Disclosure Tracking", "Record of Disclosure Maintenance",
             "Maintain an accurate record of each request for access to and each disclosure of PII from education records, including party identity and legitimate interest.",
             "Centralized Disclosure Audit Log, Access Request Register"),
            ("FERPA-34CFR-99.33", "Re-Disclosure Restrictions", "Limitation on Re-Disclosure of Student Records",
             "Ensure third parties receiving student education records agree not to re-disclose PII to any other party without prior written consent.",
             "Data Sharing Agreements (DSA), Vendor Non-Redisclosure Clauses"),
            
            // --- STUDENT & PARENT RIGHTS (34 CFR § 99.10 - 99.22) ---
            ("FERPA-34CFR-99.10", "Student & Parent Rights", "Inspection & Review of Education Records",
             "Provide parents or eligible students the right to inspect and review education records within 45 days of request.",
             "Record Inspection Protocol, 45-Day Request SLA Tracker"),
            ("FERPA-34CFR-99.20", "Record Amendment", "Request to Amend Inaccurate Records",
             "Establish formal procedures allowing parents or eligible students to request amendment of records believed to be inaccurate or misleading.",
             "Record Amendment Request Workflow, Hearing Panel Minutes"),
            
            // --- TECHNICAL SAFEGUARDS & VENDOR MANAGEMENT ---
            ("FERPA-TECH-01", "Technical Safeguards", "Encryption of Student Data at Rest & in Transit",
             "Encrypt all student PII and education records at rest (AES-256) and in transit (TLS 1.2/1.3) across databases and web endpoints.",
             "KMS Encryption Verification, Endpoint TLS Audit Log"),
            ("FERPA-TECH-02", "Technical Safeguards", "Role-Based Access Control (RBAC) & School Official Access",
             "Enforce strict role-based access control (RBAC) ensuring administrative staff, faculty, and systems access student data solely based on legitimate academic need.",
             "Active Directory/IAM Role Matrix, Access Review Sign-off"),
            ("FERPA-VEN-01", "Vendor Oversight", "School Official Designation & Contractual Data Control",
             "Designate third-party software vendors and cloud providers as 'School Officials' performing institutional services, enforcing direct control over vendor data usage and prohibition on commercial profile building.",
             "Executed Vendor EdTech DPAs, School Official Governance Terms"),
            ("FERPA-DIR-01", "Directory Information", "Directory Information Designation & Opt-Out Management",
             "Provide annual notification specifying directory information elements (e.g., name, enrollment status) and honor student/parent opt-out requests.",
             "Annual FERPA Notice, Student Directory Opt-Out Database Register")
        ]
        
        for (id, category, title, statement, evidence) in ferpaCatalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "FERPA",
                    title: title,
                    category: category,
                    blurb: "Verify compliance with FERPA regulation / safeguard \(id).",
                    discussion: "Refer to U.S. Department of Education Family Policy Compliance Office (FPCO) and Privacy Technical Assistance Center (PTAC) guidelines.",
                    controlStatement: statement,
                    controlActivities: "Inspect parental consent logs, vendor EdTech DPAs, RBAC privilege exports, and annual directory opt-out registers.",
                    examinationObjects: [evidence, "FERPA Compliance Policy Manual", "Vendor DPA Register"],
                    interviewRoles: ["Registrar", "Chief Privacy Officer", "EdTech Systems Administrator"],
                    relatedControls: ["NIST-AC-02", "ISO-A.5.34", "SOC2-C1.1"]
                )
            )
        }
        
        return tasks
    }
    
    func buildSOC1FallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let soc1Catalog: [(String, String, String, String, String)] = [
            ("SOC1-ITGC-01", "IT General Controls", "Financial System User Provisioning",
             "Logical access to financial applications and supporting databases is restricted to authorized users based on management approval.",
             "Approved User Access Request Forms, Role Matrix"),
            ("SOC1-ITGC-02", "IT General Controls", "Quarterly Financial Access Reviews",
             "Management conducts quarterly reviews of user access rights to financial processing platforms and revokes unnecessary access.",
             "Quarterly Financial User Access Review Sign-Off"),
            ("SOC1-ITGC-03", "IT General Controls", "Privileged Financial System Access",
             "Administrative access to accounting databases and financial application servers is restricted and monitored.",
             "DBA & SysAdmin Privileged Account List, PAM Logs"),
            ("SOC1-ITGC-04", "IT General Controls", "Termination Access Revocation",
             "Access to financial systems is revoked immediately upon employee termination or transfer.",
             "HR Termination Log vs Active Directory Account Removal Timestamps"),
            ("SOC1-CM-01", "Change Management", "Financial System Software Change Control",
             "Changes to software code impacting financial calculations or data processing are authorized, tested, and approved before release.",
             "UAT Test Sign-Offs, Change Advisory Board (CAB) Minutes"),
            ("SOC1-CM-02", "Change Management", "Segregation of Development and Production",
             "Developers are restricted from deploying code directly into production financial application environments.",
             "CI/CD Pipeline Access Controls, Git Deployment Logs"),
            ("SOC1-CM-03", "Change Management", "Emergency Financial System Fixes",
             "Emergency production code fixes affecting financial processing are documented, reviewed, and retroactively approved.",
             "Emergency Change Tickets & Retrospective Approval Records"),
            ("SOC1-OPS-01", "Transaction Processing", "Batch Input Validation & Reconciliation",
             "Financial transaction batches are validated for completeness and accuracy prior to ledger posting.",
             "Batch Reconciliation Sheets, Interface Error Logs"),
            ("SOC1-OPS-02", "Transaction Processing", "Automated Financial Calculation Verification",
             "Automated fee, interest, or revenue recognition calculations are periodically tested and verified against contract terms.",
             "Calculation Engine Sample Audit Reports, Re-performance Calculations"),
            ("SOC1-OPS-03", "Transaction Processing", "Exception Handling & Manual Overrides",
             "Manual adjustments or override transactions posted to financial ledgers require dual managerial authorization.",
             "Manual Journal Entry Approval Sign-Offs"),
            ("SOC1-DP-01", "Data Protection", "Financial Database Encryption & Protection",
             "Financial databases containing customer transaction data are encrypted at rest and in transit.",
             "Database KMS Encryption Configuration, TLS Protocol Audit"),
            ("SOC1-DP-02", "Data Protection", "Financial Backup & Disaster Recovery",
             "Backups of financial transaction ledgers are executed daily and tested periodically to ensure restoration capabilities.",
             "Daily Backup Completion Logs, Annual Financial DR Test Summary"),
            ("SOC1-VR-01", "Vendor Risk", "Complementary User Entity Controls (CUECs)",
             "Management evaluates subservice vendor SOC 1 reports and verifies internal compliance with Complementary User Entity Controls.",
             "Subservice Vendor SOC 1 Bridge Letter & CUEC Review Matrix")
        ]
        
        for (id, category, title, statement, evidence) in soc1Catalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "SOC_1",
                    title: title,
                    category: category,
                    blurb: "Verify internal controls over financial reporting (ICFR) for SOC 1 standard \(id).",
                    discussion: "Refer to SSAE 18 guidance for service organization reporting over financial controls.",
                    controlStatement: statement,
                    controlActivities: "Inspect administrative records, sample transaction logs, journal approval sign-offs, and CUEC matrices.",
                    examinationObjects: [evidence, "ICFR Policy Manual", "Auditor Sample Testing Log"],
                    interviewRoles: ["Chief Financial Officer (CFO)", "Controller", "IT Compliance Manager"],
                    relatedControls: ["SOC2-CC6.1", "ISO-A.5.1", "NIST-AC-01"]
                )
            )
        }
        
        return tasks
    }
    
    func buildHIPAAFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let hipaaCatalog: [(String, String, String, String, String)] = [
            ("HIPAA-164.308(a)(1)", "Administrative Safeguards", "Security Management Process",
             "Conduct an accurate and thorough risk analysis of potential vulnerabilities to ePHI and implement risk management security measures.",
             "Enterprise Risk Assessment, Risk Mitigation Register"),
            ("HIPAA-164.308(a)(2)", "Administrative Safeguards", "Assigned Security Responsibility",
             "Designate a Chief Security Officer (CSO) responsible for developing and enforcing security policies.",
             "CISO Appointment Charter, Job Description"),
            ("HIPAA-164.308(a)(3)", "Administrative Safeguards", "Workforce Security",
             "Implement procedures for authorization, supervision, clearance, and termination of personnel accessing ePHI.",
             "Workforce Clearance Logs, Offboarding Checklists"),
            ("HIPAA-164.308(a)(4)", "Administrative Safeguards", "Information Access Management",
             "Enforce policies for authorizing access to ePHI based on the minimum necessary standard.",
             "Role-Based Access Matrix, Access Authorization Forms"),
            ("HIPAA-164.308(a)(5)", "Administrative Safeguards", "Security Awareness & Training",
             "Deliver periodic security training, phishing awareness, and password management guidance to all personnel.",
             "Training Completion Records, Security Reminders"),
            ("HIPAA-164.308(a)(6)", "Administrative Safeguards", "Security Incident Procedures",
             "Maintain procedures to identify, respond to, mitigate, and document security incidents.",
             "Incident Response Plan (IRP), Breach Notification Log"),
            ("HIPAA-164.308(a)(7)", "Administrative Safeguards", "Contingency Plan",
             "Establish data backup, disaster recovery, and emergency mode operation plans for ePHI systems.",
             "Disaster Recovery Test Results, Backup Audit Log"),
            ("HIPAA-164.308(a)(8)", "Administrative Safeguards", "Periodic Evaluation",
             "Perform technical and non-technical evaluations of security safeguards in response to environmental or operational changes.",
             "HIPAA Compliance Evaluation Report"),
            ("HIPAA-164.310(a)(1)", "Physical Safeguards", "Facility Access Controls",
             "Limit physical access to electronic information systems and facilities containing ePHI.",
             "Keycard Access Logs, Visitor Management Register"),
            ("HIPAA-164.310(b)", "Physical Safeguards", "Workstation Use",
             "Specify proper functions and physical surroundings for workstations accessing ePHI.",
             "Workstation Acceptable Use Policy"),
            ("HIPAA-164.310(c)", "Physical Safeguards", "Workstation Security",
             "Implement physical safeguards for workstations to prevent unauthorized viewing or access.",
             "Privacy Screen Verification, Physical Lock Inspections"),
            ("HIPAA-164.310(d)(1)", "Physical Safeguards", "Device and Media Controls",
             "Govern receipt, movement, disposal, and re-use of hardware and electronic media containing ePHI.",
             "Media Sanitization Certificates, Asset Disposal Manifest"),
            ("HIPAA-164.312(a)(1)", "Technical Safeguards", "Access Control & Emergency Access",
             "Restrict system access to authorized users and implement emergency 'break-glass' access procedures.",
             "Unique User ID Exports, Emergency Access Protocol"),
            ("HIPAA-164.312(b)", "Technical Safeguards", "Audit Controls",
             "Implement mechanisms to log, record, and examine system activity in platforms holding ePHI.",
             "EHR Audit Logs, SIEM Centralized Logging Dashboard"),
            ("HIPAA-164.312(c)(1)", "Technical Safeguards", "ePHI Integrity Protections",
             "Implement security measures to ensure ePHI is not improperly altered or destroyed.",
             "File Integrity Monitoring (FIM) Logs, Database Checksums"),
            ("HIPAA-164.312(d)", "Technical Safeguards", "Person or Entity Authentication",
             "Verify identity before granting access to ePHI.",
             "MFA System Configuration Export"),
            ("HIPAA-164.312(e)(1)", "Technical Safeguards", "Transmission Security & Encryption",
             "Protect ePHI in transit over electronic communications networks using encryption protocols.",
             "TLS 1.3 Cipher Suite Logs, VPN Infrastructure Audit"),
            ("HIPAA-164.314(a)(1)", "Organizational Safeguards", "Business Associate Agreements (BAA)",
             "Execute written contracts (BAAs) with business associates to ensure standard protection of ePHI.",
             "Executed BAA Inventory, Vendor Risk Audits")
        ]
        
        for (id, category, title, statement, evidence) in hipaaCatalog {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "HIPAA",
                    title: title,
                    category: category,
                    blurb: "Verify compliance with HIPAA Security Rule standard \(id).",
                    discussion: "Refer to HHS Office for Civil Rights (OCR) HIPAA Security Rule crosswalks and audit protocols.",
                    controlStatement: statement,
                    controlActivities: "Inspect policy documentation, technical access controls, BAA repositories, and audit logs.",
                    examinationObjects: [evidence, "HIPAA Safeguards Policy Register", "OCR Audit Checklist"],
                    interviewRoles: ["Privacy Officer", "Chief Security Officer", "Clinical IT Manager"],
                    relatedControls: ["NIST-AC-01", "ISO-A.5.1", "SOC2-CC6.1"]
                )
            )
        }
        
        return tasks
    }
    
    func buildNISTFallbackTasks() -> [AuditTask] {
        let nistControls = [
            ("NIST-AC-01", "AC", "Access Control Policy and Procedures", "Develop, document, and disseminate access control policies and procedures."),
            ("NIST-AC-02", "AC", "Account Management", "Manage information system accounts including creation, activation, modification, and disabling."),
            ("NIST-AU-02", "AU", "Event Logging", "Identify and log audit events sufficient to establish what events occurred and who initiated them."),
            ("NIST-IA-02", "IA", "Identification and Authentication", "Uniquely identify and authenticate organizational users and processes.")
        ]
        
        return nistControls.map { (id, cat, title, blurb) in
            AuditTask(
                id: id,
                frameworkKey: "NIST_800_53",
                title: title,
                category: cat,
                blurb: blurb,
                discussion: "Refer to NIST SP 800-53 Rev 5 supplemental guidance for implementation details.",
                controlStatement: "The system implements mechanisms to support \(title.lowercased()).",
                controlActivities: "Inspect active configuration settings and access lists.",
                examinationObjects: ["System Config", "Account Registry"],
                interviewRoles: ["System Administrator", "Security Officer"],
                relatedControls: ["SOC2-CC1-01", "ISO-A.8.2"]
            )
        }
    }
    
    func buildISOFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let a5Controls: [(String, String, String, String)] = [
            ("ISO-A.5.1", "Policies for information security", "Define and approve information security policy and topic-specific policies.", "Information Security Policy"),
            ("ISO-A.5.2", "Information security roles and responsibilities", "Define and allocate information security roles and responsibilities.", "Roles & Responsibilities Matrix"),
            ("ISO-A.5.3", "Segregation of duties", "Conflicting duties and areas of responsibility shall be segregated.", "Duties Segregation Matrix"),
            ("ISO-A.5.4", "Management responsibilities", "Management shall require personnel to apply security in accordance with policies.", "Management Directive"),
            ("ISO-A.5.5", "Contact with authorities", "Establish and maintain contact with relevant regulatory authorities.", "Authority Communication Log"),
            ("ISO-A.5.6", "Contact with special interest groups", "Maintain contacts with special interest groups or security forums.", "Industry Forum Membership"),
            ("ISO-A.5.7", "Threat intelligence", "Collect and analyze information relating to information security threats.", "Threat Intelligence Feed"),
            ("ISO-A.5.8", "Information security in project management", "Integrate security into project management activities.", "Project Governance Framework"),
            ("ISO-A.5.9", "Inventory of information and other associated assets", "Identify assets and maintain an inventory.", "Asset Management Register"),
            ("ISO-A.5.10", "Acceptable use of information and assets", "Define and implement acceptable use rules for assets.", "Acceptable Use Policy (AUP)"),
            ("ISO-A.5.11", "Return of assets", "Personnel shall return organizational assets upon termination.", "Offboarding Checklist"),
            ("ISO-A.5.12", "Classification of information", "Classify information according to security needs.", "Data Classification Policy"),
            ("ISO-A.5.13", "Labeling of information", "Develop procedures for information labeling in accordance with classification.", "Data Labeling Guidelines"),
            ("ISO-A.5.14", "Information transfer", "Establish rules for secure transfer of information for all types of transfer facilities.", "Data Transfer Agreement"),
            ("ISO-A.5.15", "Access control", "Establish rules to control physical and logical access to assets.", "Access Control Policy"),
            ("ISO-A.5.16", "Identity management", "Manage the full lifecycle of identities.", "Identity Lifecycle Policy"),
            ("ISO-A.5.17", "Authentication information", "Manage allocation and management of authentication information.", "Password Policy"),
            ("ISO-A.5.18", "Access rights", "Provision, modify, and revoke access rights in accordance with policy.", "Access Provisioning Records"),
            ("ISO-A.5.19", "Information security in supplier relationships", "Define security requirements for supplier relationships.", "Vendor Risk Policy"),
            ("ISO-A.5.20", "Addressing security within supplier agreements", "Incorporate security requirements into supplier agreements.", "Third-Party Contracts / MSA"),
            ("ISO-A.5.21", "Managing security in the ICT supply chain", "Define and monitor security requirements across the ICT supply chain.", "Supply Chain Risk Register"),
            ("ISO-A.5.22", "Monitoring, review and change management of supplier services", "Regularly monitor and audit supplier service performance.", "Vendor Audit Reports"),
            ("ISO-A.5.23", "Information security for use of cloud services", "Establish processes for acquisition, use, and management of cloud services.", "Cloud Security Architecture"),
            ("ISO-A.5.24", "Information security incident management planning and preparation", "Prepare for incident handling by defining roles and procedures.", "Incident Response Plan (IRP)"),
            ("ISO-A.5.25", "Assessment and decision on information security events", "Assess security events and decide if they are incidents.", "Triage Procedure"),
            ("ISO-A.5.26", "Response to information security incidents", "Respond to security incidents in accordance with documented procedures.", "Incident Post-Mortem Records"),
            ("ISO-A.5.27", "Learning from information security incidents", "Use knowledge gained from incidents to strengthen controls.", "Post-Incident Analysis Log"),
            ("ISO-A.5.28", "Collection of evidence", "Identify and collect evidence related to security incidents.", "Forensic Evidence Chain"),
            ("ISO-A.5.29", "Information security during disruption", "Plan for security continuity during adverse situations.", "Business Continuity Plan (BCP)"),
            ("ISO-A.5.30", "ICT readiness for business continuity", "Ensure ICT readiness to support business continuity objectives.", "Disaster Recovery Plan (DRP)"),
            ("ISO-A.5.31", "Legal, statutory, regulatory and contractual requirements", "Identify and document legal and regulatory requirements.", "Legal Compliance Register"),
            ("ISO-A.5.32", "Intellectual property rights", "Implement measures to protect intellectual property.", "IP Protection Guidelines"),
            ("ISO-A.5.33", "Protection of records", "Protect records from loss, destruction, falsification, and unauthorized access.", "Records Retention Policy"),
            ("ISO-A.5.34", "Privacy and protection of PII", "Ensure privacy and protection of personally identifiable information.", "Privacy Policy / DPA"),
            ("ISO-A.5.35", "Independent review of information security", "Review organizational security management independently.", "Internal Audit Reports"),
            ("ISO-A.5.36", "Compliance with policies and standards for security", "Review compliance of information processing with security policies.", "Compliance Assessment Matrix"),
            ("ISO-A.5.37", "Documented operating procedures", "Document operating procedures for information processing facilities.", "Standard Operating Procedures (SOPs)")
        ]
        
        for (id, title, statement, evidence) in a5Controls {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "ISO_27001",
                    title: title,
                    category: "A.5 Organizational Controls",
                    blurb: "Verify compliance with ISO/IEC 27001:2022 Annex A.5 organizational controls.",
                    discussion: "Refer to ISO/IEC 27002:2022 clause 5 for implementation guidance and control objectives.",
                    controlStatement: statement,
                    controlActivities: "Inspect administrative records, governance documentation, and management approval artifacts.",
                    examinationObjects: [evidence, "Organizational Policy Register", "Management Review Sign-Off"],
                    interviewRoles: ["CISO", "Compliance Manager", "Operations Director"],
                    relatedControls: ["NIST-AC-01", "SOC2-CC1-01"]
                )
            )
        }
        
        let a6Controls: [(String, String, String, String)] = [
            ("ISO-A.6.1", "Screening", "Conduct background verification checks on all candidates for employment.", "Background Check Log"),
            ("ISO-A.6.2", "Terms and conditions of employment", "Employment agreements shall state security responsibilities.", "Employment Contract Template"),
            ("ISO-A.6.3", "Information security awareness, education and training", "Personnel shall receive appropriate security awareness training.", "Security Training Records"),
            ("ISO-A.6.4", "Disciplinary process", "Formalize a disciplinary process for security policy violations.", "Disciplinary Policy"),
            ("ISO-A.6.5", "Responsibilities after termination or change of employment", "Define security responsibilities that remain valid after termination.", "Offboarding Policy"),
            ("ISO-A.6.6", "Confidentiality or non-disclosure agreements", "Enforce NDAs for personnel and external parties.", "Signed NDA Manifest"),
            ("ISO-A.6.7", "Remote working", "Protect information accessed or processed during remote work.", "Remote Work Policy"),
            ("ISO-A.6.8", "Information security event reporting", "Provide a mechanism for personnel to report security events.", "Event Reporting System")
        ]
        
        for (id, title, statement, evidence) in a6Controls {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "ISO_27001",
                    title: title,
                    category: "A.6 People Controls",
                    blurb: "Verify compliance with ISO/IEC 27001:2022 Annex A.6 personnel safeguards.",
                    discussion: "Refer to ISO/IEC 27002:2022 clause 6 for human resource security guidance.",
                    controlStatement: statement,
                    controlActivities: "Review HR files, training completion logs, and remote work agreements.",
                    examinationObjects: [evidence, "HR Onboarding Flow", "Training Completion Report"],
                    interviewRoles: ["HR Director", "Talent Acquisition Lead"],
                    relatedControls: ["NIST-PS-03", "SOC2-CC1-04"]
                )
            )
        }
        
        let a7Controls: [(String, String, String, String)] = [
            ("ISO-A.7.1", "Physical security perimeters", "Define and use physical security perimeters to protect sensitive areas.", "Perimeter Access Policy"),
            ("ISO-A.7.2", "Physical entry", "Protect entry points with suitable security controls and entry barriers.", "Badge Access Logs"),
            ("ISO-A.7.3", "Securing offices, rooms and facilities", "Design and apply physical security for offices and rooms.", "Facility Inspection Log"),
            ("ISO-A.7.4", "Physical security monitoring", "Continuously monitor physical premises for unauthorized access.", "CCTV / Camera Surveillance"),
            ("ISO-A.7.5", "Protecting against physical and environmental threats", "Protect assets from natural disasters and physical threats.", "Environmental Hazard Audit"),
            ("ISO-A.7.6", "Working in secure areas", "Apply physical security controls for working in secure areas.", "Secure Area Policy"),
            ("ISO-A.7.7", "Clear desk and clear screen", "Enforce clear desk and clear screen rules.", "Clean Desk Audit Log"),
            ("ISO-A.7.8", "Equipment siting and protection", "Site and protect equipment to reduce risks from threats.", "Datacenter Layout Map"),
            ("ISO-A.7.9", "Security of assets off-premises", "Protect off-premises assets taking into account external risks.", "Off-site Asset Registry"),
            ("ISO-A.7.10", "Storage media", "Manage storage media in accordance with classification.", "Media Destruction Certificate"),
            ("ISO-A.7.11", "Supporting utilities", "Protect equipment from power failures and utility disruptions.", "UPS Maintenance Log"),
            ("ISO-A.7.12", "Cabling security", "Protect power and telecommunications cabling from interception.", "Cabling Infrastructure Plan"),
            ("ISO-A.7.13", "Equipment maintenance", "Maintain equipment correctly to ensure availability.", "Maintenance Records"),
            ("ISO-A.7.14", "Secure disposal or re-use of equipment", "Verify that sensitive data is erased before equipment disposal.", "Sanitization Logs")
        ]
        
        for (id, title, statement, evidence) in a7Controls {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "ISO_27001",
                    title: title,
                    category: "A.7 Physical Controls",
                    blurb: "Verify compliance with ISO/IEC 27001:2022 Annex A.7 physical controls.",
                    discussion: "Refer to ISO/IEC 27002:2022 clause 7 for facility and physical perimeter security.",
                    controlStatement: statement,
                    controlActivities: "Inspect physical access logs, environmental monitoring systems, and disposal logs.",
                    examinationObjects: [evidence, "Facility Tour Logs", "Vendor Maintenance Contracts"],
                    interviewRoles: ["Facilities Lead", "Physical Security Manager"],
                    relatedControls: ["NIST-PE-02", "SOC2-CC6-04"]
                )
            )
        }
        
        let a8Controls: [(String, String, String, String)] = [
            ("ISO-A.8.1", "User endpoint devices", "Protect information stored on, processed by, or accessible via endpoint devices.", "MDM Policy Export"),
            ("ISO-A.8.2", "Privileged access rights", "Restrict and manage the allocation and use of privileged access rights.", "PAM Registry"),
            ("ISO-A.8.3", "Information access restriction", "Restrict access to information and application functions in accordance with policy.", "ACL Export"),
            ("ISO-A.8.4", "Access to source code", "Restrict read and write access to source code and related items.", "Git Repo Permissions"),
            ("ISO-A.8.5", "Secure authentication", "Control secure authentication technologies in accordance with access policy.", "MFA Configuration Log"),
            ("ISO-A.8.6", "Capacity management", "Monitor resource use and tune systems to meet capacity demands.", "Monitoring Dashboard"),
            ("ISO-A.8.7", "Protection against malware", "Implement protection against malware supported by security awareness.", "EDR Status Report"),
            ("ISO-A.8.8", "Management of technical vulnerabilities", "Obtain information about technical vulnerabilities and take appropriate measures.", "Vulnerability Scan Report"),
            ("ISO-A.8.9", "Configuration management", "Establish, document, and monitor baseline configurations.", "Infrastructure-as-Code Repo"),
            ("ISO-A.8.10", "Information deletion", "Delete information stored in systems when no longer required.", "Data Purge Logs"),
            ("ISO-A.8.11", "Data masking", "Use data masking in accordance with the topic-specific policy on access control.", "Anonymization Script Log"),
            ("ISO-A.8.12", "Data leakage prevention", "Apply data leakage prevention measures to systems processing sensitive data.", "DLP Console Policy"),
            ("ISO-A.8.13", "Information backup", "Maintain backup copies of information, software, and system images.", "Backup Verification Log"),
            ("ISO-A.8.14", "Redundancy of information processing facilities", "Implement sufficient redundancy to meet availability requirements.", "HA Architecture Diagram"),
            ("ISO-A.8.15", "Logging", "Produce, store, protect, and analyze event logs.", "SIEM Audit Pipeline"),
            ("ISO-A.8.16", "Monitoring activities", "Monitor networks, systems, and applications for anomalous behavior.", "SOC Incident Alerts"),
            ("ISO-A.8.17", "Clock synchronization", "Synchronize system clocks to approved time sources.", "NTP Config File"),
            ("ISO-A.8.18", "Use of privileged utility programs", "Restrict and tightly control utility programs capable of overriding controls.", "Utility Access Audit"),
            ("ISO-A.8.19", "Installation of software on operational systems", "Implement procedures to securely control software installations.", "Software Approval List"),
            ("ISO-A.8.20", "Networks security", "Secure and manage networks and network devices.", "Firewall Rule Base"),
            ("ISO-A.8.21", "Security of network services", "Identify and include security mechanisms of network services in service agreements.", "SLA Documentation"),
            ("ISO-A.8.22", "Segregation of networks", "Segregate groups of information services, users, and information systems.", "VLAN / Subnet Map"),
            ("ISO-A.8.23", "Web filtering", "Manage access to external websites to reduce exposure to malicious content.", "Web Gateway Config"),
            ("ISO-A.8.24", "Use of cryptography", "Define and enforce rules for effective cryptographic control implementation.", "Key Management Policy"),
            ("ISO-A.8.25", "Secure development life cycle", "Establish rules for secure software and systems development.", "SDLC Policy Document"),
            ("ISO-A.8.26", "Application security requirements", "Identify and specify security requirements when developing or acquiring apps.", "AppSec Matrix"),
            ("ISO-A.8.27", "Secure system architecture and engineering principles", "Establish, document, and apply secure system engineering principles.", "Architecture Standards"),
            ("ISO-A.8.28", "Secure coding", "Apply secure coding principles to software development.", "Static Analysis (SAST) Log"),
            ("ISO-A.8.29", "Security testing in development and acceptance", "Perform security testing during development.", "Penetration Test Report"),
            ("ISO-A.8.30", "Outsourced development", "Direct, monitor, and review outsourced system development.", "Vendor Code Audit Signoff"),
            ("ISO-A.8.31", "Separation of development, testing and operational environments", "Separate development, testing, and production environments.", "Environment Isolation Spec"),
            ("ISO-A.8.32", "Change management", "Control changes to information processing facilities and systems.", "Change Advisory Board (CAB) Log"),
            ("ISO-A.8.33", "Test information", "Select, protect, and control test information during testing.", "Sanitized Test Data Log"),
            ("ISO-A.8.34", "Protection of information systems during audit testing", "Plan and agree audit tests involving operational systems.", "Audit Testing Window Signoff")
        ]
        
        for (id, title, statement, evidence) in a8Controls {
            tasks.append(
                AuditTask(
                    id: id,
                    frameworkKey: "ISO_27001",
                    title: title,
                    category: "A.8 Technological Controls",
                    blurb: "Verify compliance with ISO/IEC 27001:2022 Annex A.8 technical safeguards.",
                    discussion: "Refer to ISO/IEC 27002:2022 clause 8 for cybersecurity and technical control implementation details.",
                    controlStatement: statement,
                    controlActivities: "Inspect technical logs, system configurations, automated scanners, and infrastructure exports.",
                    examinationObjects: [evidence, "System Admin Logs", "Technical Verification Report"],
                    interviewRoles: ["Cloud Architect", "Lead DevSecOps Engineer", "Systems Administrator"],
                    relatedControls: ["NIST-AC-02", "NIST-SI-02", "SOC2-CC6-01"]
                )
            )
        }
        
        return tasks
    }
