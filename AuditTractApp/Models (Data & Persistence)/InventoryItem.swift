//
//  InventoryItem.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/20/26.
//

import Foundation
import SwiftData

// MARK: - SwiftData Inventory Model
@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var assetType: String              // e.g., "AWS EC2", "PostgreSQL DB", "MacBook Pro"
    var owner: String                  // Fallback owner string or department name
    var ipAddressOrURL: String?
    
    // SwiftData Relational Link to Employee
    @Relationship var assignedEmployee: Employee?
    
    // Lifecycle & Scope Properties
    var statusRaw: String              // Maps to AssetStatus
    var classificationRaw: String      // Maps to DataClassification
    var criticalityRaw: String         // Maps to AssetCriticality
    var linkedControlIDs: [String]     // e.g., ["PCI-REQ-03", "HIPAA-164.312(b)"]
    var isEncrypted: Bool
    var lastScanDate: Date?
    var decommissionedDate: Date?      // Decommissioned timestamp
    var sanitizationCertificateID: String? // NIST 800-88 evidence ID
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        assetType: String,
        owner: String = "",
        assignedEmployee: Employee? = nil,
        ipAddressOrURL: String? = nil,
        status: AssetStatus = .active,
        classification: DataClassification = .internalData,
        criticality: AssetCriticality = .tier2,
        linkedControlIDs: [String] = [],
        isEncrypted: Bool = true,
        lastScanDate: Date? = Date(),
        decommissionedDate: Date? = nil,
        sanitizationCertificateID: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.assetType = assetType
        self.owner = owner
        self.assignedEmployee = assignedEmployee
        self.ipAddressOrURL = ipAddressOrURL
        self.statusRaw = status.rawValue
        self.classificationRaw = classification.rawValue
        self.criticalityRaw = criticality.rawValue
        self.linkedControlIDs = linkedControlIDs
        self.isEncrypted = isEncrypted
        self.lastScanDate = lastScanDate
        self.decommissionedDate = decommissionedDate
        self.sanitizationCertificateID = sanitizationCertificateID
        self.notes = notes
    }
    
    // Convenient Enum Accessors
    var status: AssetStatus {
        get { AssetStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
    
    var classification: DataClassification {
        get { DataClassification(rawValue: classificationRaw) ?? .internalData }
        set { classificationRaw = newValue.rawValue }
    }
    
    var criticality: AssetCriticality {
        get { AssetCriticality(rawValue: criticalityRaw) ?? .tier2 }
        set { criticalityRaw = newValue.rawValue }
    }
    
    // Display helper for owner name
    var ownerDisplayName: String {
        if let emp = assignedEmployee {
            return emp.name
        }
        return owner.isEmpty ? "Unassigned" : owner
    }
}

// MARK: - Default Seed Data Builder
extension InventoryItem {
    static func buildDefaultInventory() -> [InventoryItem] {
        return [
            InventoryItem(
                name: "prod-aws-rds-postgres-cde",
                assetType: "Database (AWS RDS)",
                owner: "Lead Database Engineer",
                ipAddressOrURL: "db.prod.internal.aws",
                status: .active,
                classification: .cardholderData,
                criticality: .tier1,
                linkedControlIDs: ["PCI-REQ-03", "PCI-REQ-08", "SOC2-CC6.1", "ISO-A.8.24"],
                isEncrypted: true,
                notes: "Primary payment gateway processing database storing tokenized primary account numbers."
            ),
            InventoryItem(
                name: "ehr-phi-s3-vault-us-east",
                assetType: "Cloud Object Storage (S3)",
                owner: "Health Data Operations Lead",
                ipAddressOrURL: "s3://phi-patient-records-vault",
                status: .active,
                classification: .phi,
                criticality: .tier1,
                linkedControlIDs: ["HIPAA-164.312(a)(1)", "HIPAA-164.312(e)(1)", "HITRUST-07.0"],
                isEncrypted: true,
                notes: "Encrypted S3 bucket with default KMS key holding patient record PDF exports."
            ),
            InventoryItem(
                name: "legacy-oracle-db-01",
                assetType: "Database (On-Prem Server)",
                owner: "Former Database Admin",
                ipAddressOrURL: "10.0.4.12",
                status: .decommissioned,
                classification: .confidential,
                criticality: .tier3,
                linkedControlIDs: ["NIST-MP-06", "ISO-A.7.14"],
                isEncrypted: true,
                decommissionedDate: Date().addingTimeInterval(-86400 * 90),
                sanitizationCertificateID: "NIST-SAN-2026-0894",
                notes: "Decommissioned database server. Drives wiped per NIST 800-88 guidelines."
            )
        ]
    }
}
