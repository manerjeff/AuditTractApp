//
//  ReportExporter.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation
import SwiftData

// MARK: - Audit Envelope Manager for Package Export & Import
final class AuditEnvelopeManager {
    static let shared = AuditEnvelopeManager()
    private init() {}
    
    func exportCompleteAuditPackage(
        title: String,
        evaluations: [ControlEvaluation],
        inventory: [InventoryItem],
        vulnerabilities: [VulnerabilityFinding],
        scans: [ScanExecution]
    ) -> URL? {
        let dto = AuditEnvelopeDTO(
            title: title,
            evaluations: evaluations,
            inventory: inventory,
            vulnerabilities: vulnerabilities,
            scans: scans
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(dto) else { return nil }
        
        let fileName = "AuditTract_Package_\(Int(Date().timeIntervalSince1970)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
    
    func importAndMergeEnvelope(from url: URL, into context: ModelContext) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let dto = try? JSONDecoder().decode(AuditEnvelopeDTO.self, from: data) else {
            return false
        }
        
        // 1. Merge Control Evaluations
        for evalDTO in dto.evaluations {
            let newEval = ControlEvaluation(
                id: evalDTO.id,
                controlID: evalDTO.controlID,
                frameworkKey: evalDTO.frameworkKey,
                status: evalDTO.status,
                auditorNotes: evalDTO.auditorNotes,
                evidenceLocation: evalDTO.evidenceLocation,
                lastUpdated: evalDTO.lastUpdated
            )
            context.insert(newEval)
        }
        
        // 2. Merge Inventory Items
        for itemDTO in dto.inventory {
            let item = InventoryItem(
                id: itemDTO.id,
                name: itemDTO.name,
                assetType: itemDTO.assetType,
                owner: itemDTO.owner,
                ipAddressOrURL: itemDTO.ipAddressOrURL,
                status: AssetStatus(rawValue: itemDTO.status) ?? .active,
                classification: DataClassification(rawValue: itemDTO.classification) ?? .internalData,
                criticality: AssetCriticality(rawValue: itemDTO.criticality) ?? .tier2,
                linkedControlIDs: itemDTO.linkedControlIDs,
                isEncrypted: itemDTO.isEncrypted,
                lastScanDate: itemDTO.lastScanDate,
                decommissionedDate: itemDTO.decommissionedDate,
                sanitizationCertificateID: itemDTO.sanitizationCertificateID,
                notes: itemDTO.notes
            )
            context.insert(item)
        }
        
        // 3. Merge Vulnerabilities
        for vDTO in dto.vulnerabilities {
            let finding = VulnerabilityFinding(
                id: vDTO.id,
                cveIdentifier: vDTO.cveIdentifier,
                title: vDTO.title,
                severity: vDTO.severity,
                cvssScore: vDTO.cvssScore,
                affectedIP: vDTO.affectedIP,
                remediationSummary: vDTO.remediationSummary,
                mappedControlID: vDTO.mappedControlID,
                isRemediated: vDTO.isRemediated,
                discoveredDate: vDTO.discoveredDate
            )
            context.insert(finding)
        }
        
        try? context.save()
        return true
    }
}

// MARK: - Core Report Exporter
final class ReportExporter {
    static let shared = ReportExporter()
    private init() {}
    
    // MARK: - Comprehensive Multi-Module CSV Export
    func generateComprehensiveAuditCSV(
        evaluations: [ControlEvaluation],
        inventory: [InventoryItem],
        vulnerabilities: [VulnerabilityFinding]
    ) -> String {
        var csv = "# AUDITTRACT AUDIT READINESS COMPREHENSIVE BINDER\n"
        csv += "# Export Date: \(Date().formatted())\n\n"
        
        // --- Section 1: Control Evaluations ---
        csv += "=== SECTION 1: CONTROL EVALUATIONS & WORKPAPERS ===\n"
        csv += "Control ID,Framework,Status,Evidence Pointer,Auditor Notes,Last Updated\n"
        for eval in evaluations {
            let cleanNotes = escapeCSV(eval.auditorNotes)
            let cleanLocation = escapeCSV(eval.evidenceLocation)
            csv += "\"\(eval.controlID)\",\"\(eval.frameworkKey)\",\"\(eval.status)\",\"\(cleanLocation)\",\"\(cleanNotes)\",\"\(eval.lastUpdated.formatted())\"\n"
        }
        csv += "\n"
        
        // --- Section 2: Asset Inventory Manifest ---
        csv += "=== SECTION 2: REGISTERED ASSET INVENTORY ===\n"
        csv += "Asset Name,Asset Type,Custodian,Host/IP,Status,Classification,Criticality,Encrypted,Linked Controls\n"
        for item in inventory {
            let cleanName = escapeCSV(item.name)
            let cleanOwner = escapeCSV(item.ownerDisplayName)
            let cleanHost = escapeCSV(item.ipAddressOrURL ?? "None")
            let linked = escapeCSV(item.linkedControlIDs.joined(separator: "; "))
            csv += "\"\(cleanName)\",\"\(item.assetType)\",\"\(cleanOwner)\",\"\(cleanHost)\",\"\(item.status.rawValue)\",\"\(item.classification.rawValue)\",\"\(item.criticality.rawValue)\",\"\(item.isEncrypted ? "YES" : "NO")\",\"\(linked)\"\n"
        }
        csv += "\n"
        
        // --- Section 3: Attack Surface & CVE Findings ---
        csv += "=== SECTION 3: ATTACK SURFACE & CVE FINDINGS ===\n"
        csv += "CVE / Identifier,Severity,CVSS Score,Target Host,Linked Asset,Audit Control,Status,Remediation Guidance\n"
        for finding in vulnerabilities {
            let cleanRemediation = escapeCSV(finding.remediationSummary)
            let assetName = escapeCSV(finding.targetAsset?.name ?? "External/Unlinked")
            let control = escapeCSV(finding.mappedControlID ?? "SI-02")
            csv += "\"\(finding.cveIdentifier)\",\"\(finding.severity)\",\"\(String(format: "%.1f", finding.cvssScore))\",\"\(finding.affectedIP)\",\"\(assetName)\",\"\(control)\",\"\(finding.isRemediated ? "REMEDIATED" : "OPEN")\",\"\(cleanRemediation)\"\n"
        }
        
        return csv
    }
    
    // MARK: - Evaluations Only CSV
    func generateEvaluationsCSV(from evaluations: [ControlEvaluation]) -> String {
        var csvString = "Control ID,Framework,Status,Evidence Location,Auditor Notes,Last Updated\n"
        for eval in evaluations {
            let cleanNotes = escapeCSV(eval.auditorNotes)
            let cleanLocation = escapeCSV(eval.evidenceLocation)
            csvString += "\"\(eval.controlID)\",\"\(eval.frameworkKey)\",\"\(eval.status)\",\"\(cleanLocation)\",\"\(cleanNotes)\",\"\(eval.lastUpdated.formatted())\"\n"
        }
        return csvString
    }
    
    // MARK: - Inventory Only CSV
    func generateInventoryCSV(from items: [InventoryItem]) -> String {
        var csv = "Asset Name,Type,Custodian,IP/URL,Status,Classification,Criticality,Encrypted,Linked Controls,Sanitization Cert\n"
        for item in items {
            let cleanName = escapeCSV(item.name)
            let cleanOwner = escapeCSV(item.ownerDisplayName)
            let cleanHost = escapeCSV(item.ipAddressOrURL ?? "")
            let linked = escapeCSV(item.linkedControlIDs.joined(separator: "; "))
            let cert = escapeCSV(item.sanitizationCertificateID ?? "N/A")
            csv += "\"\(cleanName)\",\"\(item.assetType)\",\"\(cleanOwner)\",\"\(cleanHost)\",\"\(item.status.rawValue)\",\"\(item.classification.rawValue)\",\"\(item.criticality.rawValue)\",\"\(item.isEncrypted ? "YES" : "NO")\",\"\(linked)\",\"\(cert)\"\n"
        }
        return csv
    }
    
    // MARK: - Save Utility
    func saveReportToDocuments(content: String, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
    
    private func escapeCSV(_ text: String) -> String {
        return text.replacingOccurrences(of: "\"", with: "\"\"")
                   .replacingOccurrences(of: "\n", with: " ")
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
