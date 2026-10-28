//
//  AuditEnvelopeDTO.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation

// MARK: - 1. Control Evaluation DTO
struct ControlEvaluationDTO: Codable {
    var id: String
    var controlID: String
    var frameworkKey: String
    var status: String
    var auditorNotes: String
    var evidenceLocation: String
    var lastUpdated: Date
    
    init(from model: ControlEvaluation) {
        self.id = model.id
        self.controlID = model.controlID
        self.frameworkKey = model.frameworkKey
        self.status = model.status
        self.auditorNotes = model.auditorNotes
        self.evidenceLocation = model.evidenceLocation
        self.lastUpdated = model.lastUpdated
    }
}

// MARK: - 2. Inventory Item DTO
struct InventoryItemDTO: Codable {
    var id: UUID
    var name: String
    var assetType: String
    var owner: String
    var assignedEmployeeName: String?
    var ipAddressOrURL: String?
    var status: String
    var classification: String
    var criticality: String
    var linkedControlIDs: [String]
    var isEncrypted: Bool
    var lastScanDate: Date?
    var decommissionedDate: Date?
    var sanitizationCertificateID: String?
    var notes: String
    
    init(from model: InventoryItem) {
        self.id = model.id
        self.name = model.name
        self.assetType = model.assetType
        self.owner = model.owner
        self.assignedEmployeeName = model.assignedEmployee?.name
        self.ipAddressOrURL = model.ipAddressOrURL
        self.status = model.statusRaw
        self.classification = model.classificationRaw
        self.criticality = model.criticalityRaw
        self.linkedControlIDs = model.linkedControlIDs
        self.isEncrypted = model.isEncrypted
        self.lastScanDate = model.lastScanDate
        self.decommissionedDate = model.decommissionedDate
        self.sanitizationCertificateID = model.sanitizationCertificateID
        self.notes = model.notes
    }
}

// MARK: - 3. Vulnerability Finding DTO
struct VulnerabilityFindingDTO: Codable {
    var id: String
    var cveIdentifier: String
    var title: String
    var severity: String
    var cvssScore: Double
    var affectedIP: String
    var remediationSummary: String
    var mappedControlID: String?
    var isRemediated: Bool
    var discoveredDate: Date
    var targetAssetName: String?
    
    init(from model: VulnerabilityFinding) {
        self.id = model.id
        self.cveIdentifier = model.cveIdentifier
        self.title = model.title
        self.severity = model.severity
        self.cvssScore = model.cvssScore
        self.affectedIP = model.affectedIP
        self.remediationSummary = model.remediationSummary
        self.mappedControlID = model.mappedControlID
        self.isRemediated = model.isRemediated
        self.discoveredDate = model.discoveredDate
        self.targetAssetName = model.targetAsset?.name
    }
}

// MARK: - 4. Scan Execution Run DTO
struct ScanExecutionDTO: Codable {
    var id: String
    var scanTitle: String
    var executedDate: Date
    var status: String
    var targetRange: String
    var isInventoryScan: Bool
    
    init(from model: ScanExecution) {
        self.id = model.id
        self.scanTitle = model.scanTitle
        self.executedDate = model.executedDate
        self.status = model.status
        self.targetRange = model.targetRange
        self.isInventoryScan = model.isInventoryScan
    }
}

// MARK: - 5. Master Audit Envelope
struct AuditEnvelopeDTO: Codable {
    var assessmentID: String
    var title: String
    var frameworkKey: String
    var exportDate: Date
    var applicationVersion: String
    var evaluations: [ControlEvaluationDTO]
    var inventory: [InventoryItemDTO]
    var vulnerabilities: [VulnerabilityFindingDTO]
    var scans: [ScanExecutionDTO]
    
    init(
        title: String,
        frameworkKey: String = "NIST_800_53",
        evaluations: [ControlEvaluation],
        inventory: [InventoryItem] = [],
        vulnerabilities: [VulnerabilityFinding] = [],
        scans: [ScanExecution] = []
    ) {
        self.assessmentID = UUID().uuidString
        self.title = title
        self.frameworkKey = frameworkKey
        self.exportDate = Date()
        self.applicationVersion = "AuditTract 1.0 (2026)"
        self.evaluations = evaluations.map { ControlEvaluationDTO(from: $0) }
        self.inventory = inventory.map { InventoryItemDTO(from: $0) }
        self.vulnerabilities = vulnerabilities.map { VulnerabilityFindingDTO(from: $0) }
        self.scans = scans.map { ScanExecutionDTO(from: $0) }
    }
    
    // Legacy assessment convenience initializer
    init(assessment: Assessment) {
        self.assessmentID = assessment.id
        self.title = assessment.title
        self.frameworkKey = assessment.frameworkKey
        self.exportDate = Date()
        self.applicationVersion = "AuditTract 1.0 (2026)"
        self.evaluations = assessment.evaluations.map { ControlEvaluationDTO(from: $0) }
        self.inventory = []
        self.vulnerabilities = []
        self.scans = []
    }
}
