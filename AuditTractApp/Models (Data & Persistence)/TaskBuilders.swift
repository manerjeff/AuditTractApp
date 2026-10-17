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
        
        // 4. HIPPA Controls
        tasks.append(contentsOf: buildHIPAAFallbackTasks())
        
        // 5. SOC 1 Controls
        tasks.append(contentsOf: buildSOC1FallbackTasks())
        
        // 6. FEDRAMP Controls
        tasks.append(contentsOf: buildFedRAMPCMMCFallbackTasks())
        
        return tasks
    }
    
    func buildFedRAMPCMMCFallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let fedCmmcCatalog: [(String, String, String, String, String)] = [
            // --- ACCESS CONTROL (AC) ---
            ("CMMC-AC.L2-3.1.1", "Access Control", "Authorized Access Enforcement",
             "Limit system access to authorized users, processes acting on behalf of authorized users, and devices.",
             "Active Directory User Export, IAM Role Matrix"),
            ("CMMC-AC.L2-3.1.2", "Access Control", "Transaction & Function Control",
             "Limit system access to the types of transactions and functions that authorized users are permitted to execute.",
             "RBAC Privilege Matrix, PIV/CAC Enforcement Configuration"),
            ("CMMC-AC.L2-3.1.12", "Access Control", "Remote Access Encryption & Control",
             "Monitor and control remote access sessions using FIPS-validated cryptographic modules.",
             "FIPS 140-2/3 Cryptographic Verification, VPN Logs"),

            // --- AWARENESS AND TRAINING (AT) ---
            ("CMMC-AT.L2-3.2.1", "Awareness & Training", "Role-Based Security Training",
             "Ensure that managers, systems administrators, and users are trained on security risks associated with CUI/FedRAMP systems.",
             "CUI Handling Training Records, Cyber Awareness Challenge Certs"),

            // --- AUDIT AND ACCOUNTABILITY (AU) ---
            ("CMMC-AU.L2-3.3.1", "Audit & Accountability", "System Event Audit Logging",
             "Create and retain system audit logs and records to the extent needed to enable monitoring, analysis, and investigation of unlawful or unauthorized system activity.",
             "Centralized SIEM Ingestion Dashboard, Log Retention Spec"),
            ("CMMC-AU.L2-3.3.2", "Audit & Accountability", "Auditable Events & Analysis",
             "Ensure that the actions of individual system users can be uniquely traced to those users.",
             "Audit Record Schema, Non-Repudiation Policy"),

            // --- CONFIGURATION MANAGEMENT (CM) ---
            ("CMMC-CM.L2-3.4.1", "Configuration Management", "Baseline Configuration Maintenance",
             "Establish and maintain baseline configurations and inventories of organizational systems throughout the software development lifecycle.",
             "Hardening Benchmarks (CIS/STIG), Infrastructure-as-Code Repos"),
            ("CMMC-CM.L2-3.4.2", "Configuration Management", "Enforce Security Configuration Settings",
             "Establish and enforce security configuration settings for information technology products employed in organizational systems.",
             "DISA STIG Automated Compliance Scan Reports"),

            // --- IDENTIFICATION AND AUTHENTICATION (IA) ---
            ("CMMC-IA.L2-3.5.3", "Identification & Authentication", "Multi-Factor Authentication (MFA)",
             "Use multi-factor authentication (MFA) for local and network access to privileged and non-privileged accounts.",
             "Phishing-Resistant MFA Config (Hardware Tokens / WebAuthn)"),

            // --- INCIDENT RESPONSE (IR) ---
            ("CMMC-IR.L2-3.6.1", "Incident Response", "Incident Handling & Reporting",
             "Establish an operational incident-handling capability and report incidents to US-CERT / DIBNET within mandated timelines.",
             "FedRAMP Incident Response Plan, 72-Hour Breach Notification Protocol"),

            // --- MEDIA PROTECTION (MP) ---
            ("CMMC-MP.L2-3.8.3", "Media Protection", "Sanitization & Destruction of CUI Media",
             "Sanitize or destroy system media containing Controlled Unclassified Information (CUI) before disposal or release for reuse.",
             "NIST 800-88 Media Sanitization Records"),

            // --- PHYSICAL PROTECTION (PE) ---
            ("CMMC-PE.L2-3.10.1", "Physical Protection", "Physical Facility Safeguards",
             "Limit physical access to organizational systems, equipment, and operating environments to authorized individuals.",
             "FedRAMP Boundary Security Assessment, Badge Log Export"),

            // --- RISK ASSESSMENT (RA) ---
            ("CMMC-RA.L2-3.11.2", "Risk Assessment", "Vulnerability Scanning & Remediation",
             "Scan for vulnerabilities in organizational systems and applications periodically and remediate high-risk findings in accordance with POA&M guidelines.",
             "Monthly Vulnerability Scan Export, Plan of Action & Milestones (POA&M) Tracker"),

            // --- SYSTEM AND COMMUNICATIONS PROTECTION (SC) ---
            ("CMMC-SC.L2-3.13.11", "System & Communications", "FIPS Cryptography in Transit & at Rest",
             "Employ FIPS-validated cryptography when protecting the confidentiality of CUI.",
             "FIPS Cryptographic Module Validation Program (CMVP) Certificates"),

            // --- SYSTEM AND INFORMATION INTEGRITY (SI) ---
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

    
    func buildSOC2FallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let soc2FullCatalog: [(String, String, String, String, String)] = [
            // --- CC1: CONTROL ENVIRONMENT ---
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

            // --- CC2: COMMUNICATION & INFORMATION ---
            ("SOC2-CC2.1", "CC2 Communication & Information", "Internal Quality Information Usage",
             "The entity obtains or generates and uses relevant, quality information to support internal control.",
             "System Data Quality Reports, Operational Dashboards"),
            ("SOC2-CC2.2", "CC2 Communication & Information", "Internal Security Communication",
             "The entity internally communicates security objectives and control responsibilities.",
             "All-Hands Presentation Slides, Security Slack Channel Logs"),
            ("SOC2-CC2.3", "CC2 Communication & Information", "External Party Communication",
             "The entity communicates with external parties regarding matters affecting the functioning of internal control.",
             "Customer Privacy Notice, Vendor Management Terms"),

            // --- CC3: RISK ASSESSMENT ---
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

            // --- CC4: MONITORING ACTIVITIES ---
            ("SOC2-CC4.1", "CC4 Monitoring Activities", "Ongoing & Separate Evaluations",
             "The entity selects, develops, and performs ongoing and/or separate evaluations of internal controls.",
             "Internal Audit Reports, Compliance Monitoring Schedule"),
            ("SOC2-CC4.2", "CC4 Monitoring Activities", "Control Deficiency Communication",
             "The entity evaluates and communicates internal control deficiencies in a timely manner.",
             "CAPA (Corrective Action Plan) Tracker"),

            // --- CC5: CONTROL ACTIVITIES ---
            ("SOC2-CC5.1", "CC5 Control Activities", "Risk Mitigation Control Selection",
             "The entity selects and develops control activities that contribute to the mitigation of risks.",
             "Internal Control Matrix"),
            ("SOC2-CC5.2", "CC5 Control Activities", "Technology Infrastructure Controls",
             "The entity selects and develops general control activities over technology to support objectives.",
             "IT General Controls (ITGC) Policy"),
            ("SOC2-CC5.3", "CC5 Control Activities", "Policy & Procedure Deployment",
             "The entity deploys control activities through policies that establish expectations and procedures.",
             "Standard Operating Procedures (SOPs) Library"),

            // --- CC6: LOGICAL & PHYSICAL ACCESS CONTROLS ---
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

            // --- CC7: SYSTEM OPERATIONS ---
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

            // --- CC8: CHANGE MANAGEMENT ---
            ("SOC2-CC8.1", "CC8 Change Management", "System Change Authorization & Testing",
             "Changes to infrastructure, data, and software are authorized, tested, and approved prior to release.",
             "Pull Request Code Reviews, CI/CD Pipeline Deployment Logs"),

            // --- CC9: RISK MITIGATION ---
            ("SOC2-CC9.1", "CC9 Risk Mitigation", "Vendor & Third-Party Risk Management",
             "The entity assesses and manages risks associated with vendors, subservice organizations, and partners.",
             "Vendor SOC Report Reviews, Third-Party Risk Register"),
            ("SOC2-CC9.2", "CC9 Risk Mitigation", "Vendor Contract Safeguards",
             "Contracts with vendors establish required security requirements and performance metrics.",
             "Vendor MSA Security Addendums"),

            // --- ADDITIONAL TRUST SERVICES CRITERIA ---
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
    
    func buildSOC1FallbackTasks() -> [AuditTask] {
        var tasks: [AuditTask] = []
        
        let soc1Catalog: [(String, String, String, String, String)] = [
            // --- IT GENERAL CONTROLS (ITGC) FOR FINANCIAL SYSTEMS ---
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

            // --- FINANCIAL CHANGE MANAGEMENT ---
            ("SOC1-CM-01", "Change Management", "Financial System Software Change Control",
             "Changes to software code impacting financial calculations or data processing are authorized, tested, and approved before release.",
             "UAT Test Sign-Offs, Change Advisory Board (CAB) Minutes"),
            ("SOC1-CM-02", "Change Management", "Segregation of Development and Production",
             "Developers are restricted from deploying code directly into production financial application environments.",
             "CI/CD Pipeline Access Controls, Git Deployment Logs"),
            ("SOC1-CM-03", "Change Management", "Emergency Financial System Fixes",
             "Emergency production code fixes affecting financial processing are documented, reviewed, and retroactively approved.",
             "Emergency Change Tickets & Retrospective Approval Records"),

            // --- TRANSACTION PROCESSING & RECONCILIATION ---
            ("SOC1-OPS-01", "Transaction Processing", "Batch Input Validation & Reconciliation",
             "Financial transaction batches are validated for completeness and accuracy prior to ledger posting.",
             "Batch Reconciliation Sheets, Interface Error Logs"),
            ("SOC1-OPS-02", "Transaction Processing", "Automated Financial Calculation Verification",
             "Automated fee, interest, or revenue recognition calculations are periodically tested and verified against contract terms.",
             "Calculation Engine Sample Audit Reports, Re-performance Calculations"),
            ("SOC1-OPS-03", "Transaction Processing", "Exception Handling & Manual Overrides",
             "Manual adjustments or override transactions posted to financial ledgers require dual managerial authorization.",
             "Manual Journal Entry Approval Sign-Offs"),

            // --- FINANCIAL DATA PROTECTION & BACKUP ---
            ("SOC1-DP-01", "Data Protection", "Financial Database Encryption & Protection",
             "Financial databases containing customer transaction data are encrypted at rest and in transit.",
             "Database KMS Encryption Configuration, TLS Protocol Audit"),
            ("SOC1-DP-02", "Data Protection", "Financial Backup & Disaster Recovery",
             "Backups of financial transaction ledgers are executed daily and tested periodically to ensure restoration capabilities.",
             "Daily Backup Completion Logs, Annual Financial DR Test Summary"),

            // --- SUBSERVICE ORGANIZATIONS & VENDORS ---
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
            // --- ADMINISTRATIVE SAFEGUARDS (45 CFR § 164.308) ---
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

            // --- PHYSICAL SAFEGUARDS (45 CFR § 164.310) ---
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

            // --- TECHNICAL SAFEGUARDS (45 CFR § 164.312) ---
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

            // --- ORGANIZATIONAL REQUIREMENTS (45 CFR § 164.314) ---
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
        
        // --- A.5 ORGANIZATIONAL CONTROLS (37 Controls) ---
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
        
        // --- A.6 PEOPLE CONTROLS (8 Controls) ---
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
        
        // --- A.7 PHYSICAL CONTROLS (14 Controls) ---
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
        
        // --- A.8 TECHNOLOGICAL CONTROLS (34 Controls) ---
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
}
