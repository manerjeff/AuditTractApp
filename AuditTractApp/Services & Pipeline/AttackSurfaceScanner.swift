//
//  AttackSurfaceScanner.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/24/26.
//

import Foundation
import SwiftData

final class AttackSurfaceScanner {
    static let shared = AttackSurfaceScanner()
    private init() {}
    
    // MARK: - 1. Audit Entire Inventory
    @MainActor
    func scanInventory(items: [InventoryItem], context: ModelContext) async -> ScanExecution {
        // Fallback fetch directly from context if passed array is empty
        var activeItems = items
        if activeItems.isEmpty {
            let descriptor = FetchDescriptor<InventoryItem>()
            if let fetched = try? context.fetch(descriptor), !fetched.isEmpty {
                activeItems = fetched
            }
        }
        
        let execution = ScanExecution(
            scanTitle: "Inventory Vulnerability Audit",
            targetRange: "\(activeItems.count) Assets in Scope",
            status: "Completed",
            isInventoryScan: true
        )
        context.insert(execution)
        
        if activeItems.isEmpty {
            upsertFinding(
                cveIdentifier: "AUDIT-EMPTY-INVENTORY",
                title: "Zero Inventory Assets Detected",
                severity: "Low",
                cvssScore: 1.0,
                affectedIP: "Local Scope",
                remediationSummary: "Add assets in the Inventory tab or load sample assets to run full heuristics.",
                mappedControlID: "CM-08",
                execution: execution,
                asset: nil,
                context: context
            )
        } else {
            for item in activeItems {
                let itemFindings = await evaluateAsset(item)
                for prototype in itemFindings {
                    upsertFinding(
                        cveIdentifier: prototype.cveIdentifier,
                        title: prototype.title,
                        severity: prototype.severity,
                        cvssScore: prototype.cvssScore,
                        affectedIP: prototype.affectedIP,
                        remediationSummary: prototype.remediationSummary,
                        mappedControlID: prototype.mappedControlID,
                        execution: execution,
                        asset: item,
                        context: context
                    )
                }
                item.lastScanDate = Date()
            }
        }
        
        try? context.save()
        return execution
    }
    
    // MARK: - 2. Audit Ad-Hoc Target (IP or URL)
    @MainActor
    func scanTarget(rawTarget: String, context: ModelContext) async -> ScanExecution {
        let cleaned = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        let execution = ScanExecution(
            scanTitle: "Audit: \(cleaned)",
            targetRange: cleaned,
            status: "Completed",
            isInventoryScan: false
        )
        context.insert(execution)
        
        // Correlate with inventory: if this IP/host matches an inventory item, link it!
        let matchedAsset = findMatchingAsset(for: cleaned, context: context)
        
        var generatedPrototypes: [VulnerabilityFinding] = []
        let isIP = isIPv4Address(cleaned)
        
        if isIP {
            generatedPrototypes = evaluateIPAddress(cleaned)
        } else {
            let urlString = (cleaned.hasPrefix("http://") || cleaned.hasPrefix("https://")) ? cleaned : "https://\(cleaned)"
            if let url = URL(string: urlString) {
                generatedPrototypes = await checkWebEndpoint(url: url)
            } else {
                generatedPrototypes = evaluateIPAddress(cleaned)
            }
        }
        
        for prototype in generatedPrototypes {
            upsertFinding(
                cveIdentifier: prototype.cveIdentifier,
                title: prototype.title,
                severity: prototype.severity,
                cvssScore: prototype.cvssScore,
                affectedIP: prototype.affectedIP,
                remediationSummary: prototype.remediationSummary,
                mappedControlID: prototype.mappedControlID,
                execution: execution,
                asset: matchedAsset,
                context: context
            )
        }
        
        try? context.save()
        return execution
    }
    
    // MARK: - Correlate Target to Inventory
    @MainActor
    private func findMatchingAsset(for target: String, context: ModelContext) -> InventoryItem? {
        let descriptor = FetchDescriptor<InventoryItem>()
        guard let items = try? context.fetch(descriptor) else { return nil }
        
        return items.first { item in
            if let ip = item.ipAddressOrURL, !ip.isEmpty {
                return ip.localizedCaseInsensitiveContains(target) || target.localizedCaseInsensitiveContains(ip)
            }
            return item.name.localizedCaseInsensitiveContains(target)
        }
    }
    
    // MARK: - Upsert / Deduplication Engine
    @MainActor
    private func upsertFinding(
        cveIdentifier: String,
        title: String,
        severity: String,
        cvssScore: Double,
        affectedIP: String,
        remediationSummary: String,
        mappedControlID: String?,
        execution: ScanExecution,
        asset: InventoryItem?,
        context: ModelContext
    ) {
        let descriptor = FetchDescriptor<VulnerabilityFinding>(
            predicate: #Predicate { finding in
                finding.cveIdentifier == cveIdentifier && finding.affectedIP == affectedIP
            }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            existing.title = title
            existing.severity = severity
            existing.cvssScore = cvssScore
            existing.remediationSummary = remediationSummary
            existing.mappedControlID = mappedControlID
            existing.discoveredDate = Date()
            existing.scanExecution = execution
            if let asset = asset {
                existing.targetAsset = asset
            }
        } else {
            let newFinding = VulnerabilityFinding(
                cveIdentifier: cveIdentifier,
                title: title,
                severity: severity,
                cvssScore: cvssScore,
                affectedIP: affectedIP,
                remediationSummary: remediationSummary,
                mappedControlID: mappedControlID,
                discoveredDate: Date(),
                targetAsset: asset
            )
            newFinding.scanExecution = execution
            context.insert(newFinding)
        }
    }
    
    // MARK: - Unified Asset Evaluation
    private func evaluateAsset(_ item: InventoryItem) async -> [VulnerabilityFinding] {
        var findings: [VulnerabilityFinding] = []
        let typeLower = item.assetType.lowercased()
        let host = (item.ipAddressOrURL?.isEmpty ?? true) ? item.name : item.ipAddressOrURL!
        
        // 1. Data at Rest & Storage Encryption Checks
        if !item.isEncrypted && (typeLower.contains("database") || typeLower.contains("storage") || typeLower.contains("cloud") || typeLower.contains("server")) {
            findings.append(
                VulnerabilityFinding(
                    cveIdentifier: "AUDIT-UNENCRYPTED-STORAGE",
                    title: "Unencrypted Storage / Data Repository",
                    severity: "High",
                    cvssScore: 7.5,
                    affectedIP: host,
                    remediationSummary: "Enable encryption at rest (AES-256 / AWS KMS) per NIST SC-13 & PCI DSS Req 3.",
                    mappedControlID: "SC-13"
                )
            )
        }
        
        // 2. Sanitization Certificate on Decommission
        if item.status == .decommissioned && item.sanitizationCertificateID == nil {
            findings.append(
                VulnerabilityFinding(
                    cveIdentifier: "AUDIT-MISSING-SANITIZATION",
                    title: "Decommissioned Asset Missing NIST 800-88 Certificate",
                    severity: "Medium",
                    cvssScore: 5.3,
                    affectedIP: host,
                    remediationSummary: "Obtain and record cryptographic erase or media destruction certificate before disposal.",
                    mappedControlID: "MP-06"
                )
            )
        }
        
        // 3. Known Legacy Component Vulnerabilities
        if item.name.lowercased().contains("legacy") || typeLower.contains("oracle") {
            findings.append(
                VulnerabilityFinding(
                    cveIdentifier: "CVE-2023-21839",
                    title: "Oracle WebLogic Remote Code Execution Vulnerability",
                    severity: "Critical",
                    cvssScore: 9.8,
                    affectedIP: host,
                    remediationSummary: "Apply Oracle Critical Patch Update (CPU) or isolate network segment from ingress.",
                    mappedControlID: "SI-02"
                )
            )
        }
        
        // 4. Live Endpoint & Network Surface Scan for the Asset
        if let target = item.ipAddressOrURL, !target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleaned = target.trimmingCharacters(in: .whitespacesAndNewlines)
            if isIPv4Address(cleaned) {
                findings.append(contentsOf: evaluateIPAddress(cleaned))
            } else if cleaned.hasPrefix("http://") || cleaned.hasPrefix("https://") || cleaned.contains(".") {
                let urlString = (cleaned.hasPrefix("http://") || cleaned.hasPrefix("https://")) ? cleaned : "https://\(cleaned)"
                if let url = URL(string: urlString) {
                    let webFindings = await checkWebEndpoint(url: url)
                    findings.append(contentsOf: webFindings)
                }
            }
        }
        
        return findings
    }
    
    // MARK: - Live Web Endpoint Checks
    private func checkWebEndpoint(url: URL) async -> [VulnerabilityFinding] {
        var findings: [VulnerabilityFinding] = []
        let hostName = url.host ?? url.absoluteString
        
        if url.scheme?.lowercased() == "http" {
            findings.append(
                VulnerabilityFinding(
                    cveIdentifier: "SEC-CLEARTEXT-HTTP",
                    title: "Insecure Cleartext Transport (HTTP)",
                    severity: "High",
                    cvssScore: 7.4,
                    affectedIP: hostName,
                    remediationSummary: "Enforce HTTPS with TLS 1.3 and deploy an HTTP Strict Transport Security (HSTS) header.",
                    mappedControlID: "SC-08"
                )
            )
            return findings
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 8.0
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AuditTract/1.0", forHTTPHeaderField: "User-Agent")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                let headers = http.allHeaderFields
                
                let hasHSTS = headers.keys.contains { "\($0)".caseInsensitiveCompare("Strict-Transport-Security") == .orderedSame }
                let hasCSP = headers.keys.contains { "\($0)".caseInsensitiveCompare("Content-Security-Policy") == .orderedSame }
                let hasXContentType = headers.keys.contains { "\($0)".caseInsensitiveCompare("X-Content-Type-Options") == .orderedSame }
                let hasXFrame = headers.keys.contains { "\($0)".caseInsensitiveCompare("X-Frame-Options") == .orderedSame }
                
                if !hasHSTS {
                    findings.append(
                        VulnerabilityFinding(
                            cveIdentifier: "SEC-HDR-NO-HSTS",
                            title: "Missing HTTP Strict Transport Security (HSTS)",
                            severity: "Medium",
                            cvssScore: 5.3,
                            affectedIP: hostName,
                            remediationSummary: "Add 'Strict-Transport-Security: max-age=31536000; includeSubDomains' to enforce encrypted channels.",
                            mappedControlID: "SC-08"
                        )
                    )
                }
                
                if !hasCSP {
                    findings.append(
                        VulnerabilityFinding(
                            cveIdentifier: "SEC-HDR-NO-CSP",
                            title: "Missing Content-Security-Policy (CSP)",
                            severity: "Medium",
                            cvssScore: 5.0,
                            affectedIP: hostName,
                            remediationSummary: "Configure Content-Security-Policy header to prevent Cross-Site Scripting (XSS) and injection attacks.",
                            mappedControlID: "SI-10"
                        )
                    )
                }
                
                if !hasXContentType {
                    findings.append(
                        VulnerabilityFinding(
                            cveIdentifier: "SEC-HDR-NO-SNIFF",
                            title: "Missing X-Content-Type-Options Header",
                            severity: "Low",
                            cvssScore: 3.1,
                            affectedIP: hostName,
                            remediationSummary: "Add 'X-Content-Type-Options: nosniff' to prevent MIME-type confusion attacks.",
                            mappedControlID: "SI-11"
                        )
                    )
                }
                
                if !hasXFrame && !hasCSP {
                    findings.append(
                        VulnerabilityFinding(
                            cveIdentifier: "SEC-HDR-NO-XFRAME",
                            title: "Clickjacking Protection Incomplete",
                            severity: "Low",
                            cvssScore: 3.4,
                            affectedIP: hostName,
                            remediationSummary: "Add 'X-Frame-Options: SAMEORIGIN' or a 'frame-ancestors' CSP directive.",
                            mappedControlID: "AC-04"
                        )
                    )
                }
                
                if findings.isEmpty {
                    findings.append(
                        VulnerabilityFinding(
                            cveIdentifier: "AUDIT-ENDPOINT-VERIFIED",
                            title: "TLS & Core Security Headers Verified (Pass)",
                            severity: "Low",
                            cvssScore: 0.0,
                            affectedIP: hostName,
                            remediationSummary: "Endpoint correctly enforces HTTPS and provides required security transport headers.",
                            mappedControlID: "SC-08",
                            isRemediated: true
                        )
                    )
                }
            }
        } catch {
            findings.append(
                VulnerabilityFinding(
                    cveIdentifier: "SEC-TLS-UNREACHABLE",
                    title: "Endpoint Handshake or Connection Refused",
                    severity: "Medium",
                    cvssScore: 5.0,
                    affectedIP: hostName,
                    remediationSummary: "Ensure service port 443 is exposed, DNS is resolving, and modern TLS cipher suites are supported.",
                    mappedControlID: "CA-07"
                )
            )
        }
        
        return findings
    }
    
    // MARK: - IP Target Evaluation
    private func evaluateIPAddress(_ ip: String) -> [VulnerabilityFinding] {
        return [
            VulnerabilityFinding(
                cveIdentifier: "AUDIT-INGRESS-PORT-AUDIT",
                title: "Perimeter Ingress Exposure Review Required",
                severity: "Medium",
                cvssScore: 5.3,
                affectedIP: ip,
                remediationSummary: "Ensure host interface has security group/firewall boundaries restricting remote administration (ports 22, 3389).",
                mappedControlID: "SC-07"
            ),
            VulnerabilityFinding(
                cveIdentifier: "CVE-2024-6387",
                title: "OpenSSH RegreSSHion Remote Code Execution Vulnerability",
                severity: "High",
                cvssScore: 8.1,
                affectedIP: ip,
                remediationSummary: "Verify listening SSH services and update OpenSSH to version 9.8p1 or newer.",
                mappedControlID: "SI-02"
            )
        ]
    }
    
    private func isIPv4Address(_ string: String) -> Bool {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return false }
        for part in parts {
            guard let intVal = Int(part), intVal >= 0 && intVal <= 255 else { return false }
        }
        return true
    }
}
