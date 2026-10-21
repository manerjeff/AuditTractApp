// === File: ./Models (Data & Persistence)/InventoryItem.swift ===
//
//  InventoryItem.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/20/26.
//

import Foundation
import SwiftData

// MARK: - Data Classification Enums
enum DataClassification: String, Codable, CaseIterable {
    case publicData = "Public"
    case internalData = "Internal"
    case confidential = "Confidential"
    case cardholderData = "Cardholder Data (PAN)" // PCI DSS
    case phi = "ePHI"                             // HIPAA / HITRUST
    case cui = "CUI"                              // FedRAMP / CMMC
    case cji = "CJI"                              // CJIS
    case studentData = "Student PII"             // FERPA
    case personalData = "Personal Data"           // GDPR / CCPA
}

// MARK: - Asset Criticality Enums
enum AssetCriticality: String, Codable, CaseIterable {
    case tier1 = "Tier 1 - Mission Critical"
    case tier2 = "Tier 2 - Business Operational"
    case tier3 = "Tier 3 - Non-Production"
}

// MARK: - SwiftData Inventory Model
@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var assetType: String              // e.g., "AWS EC2", "PostgreSQL DB", "MacBook Pro", "GitHub Repo"
    var owner: String                  // System Owner / Custodian
    var ipAddressOrURL: String?
    
    // Scope Binding & Evidence Properties
    var classificationRaw: String      // Maps to DataClassification
    var criticalityRaw: String         // Maps to AssetCriticality
    var linkedControlIDs: [String]     // e.g., ["PCI-REQ-03", "HIPAA-164.312(b)", "SOC2-CC6.1"]
    var isEncrypted: Bool
    var lastScanDate: Date?
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        assetType: String,
        owner: String,
        ipAddressOrURL: String? = nil,
        classification: DataClassification = .internalData,
        criticality: AssetCriticality = .tier2,
        linkedControlIDs: [String] = [],
        isEncrypted: Bool = true,
        lastScanDate: Date? = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.assetType = assetType
        self.owner = owner
        self.ipAddressOrURL = ipAddressOrURL
        self.classificationRaw = classification.rawValue
        self.criticalityRaw = criticality.rawValue
        self.linkedControlIDs = linkedControlIDs
        self.isEncrypted = isEncrypted
        self.lastScanDate = lastScanDate
        self.notes = notes
    }
    
    // Convenient Accessors
    var classification: DataClassification {
        get { DataClassification(rawValue: classificationRaw) ?? .internalData }
        set { classificationRaw = newValue.rawValue }
    }
    
    var criticality: AssetCriticality {
        get { AssetCriticality(rawValue: criticalityRaw) ?? .tier2 }
        set { criticalityRaw = newValue.rawValue }
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
                classification: .phi,
                criticality: .tier1,
                linkedControlIDs: ["HIPAA-164.312(a)(1)", "HIPAA-164.312(e)(1)", "HITRUST-07.0"],
                isEncrypted: true,
                notes: "Encrypted S3 bucket with default KMS key holding patient record PDF exports."
            ),
            InventoryItem(
                name: "fedramp-cui-app-cluster-01",
                assetType: "Kubernetes Cluster (EKS)",
                owner: "DevSecOps Lead",
                ipAddressOrURL: "10.140.12.50",
                classification: .cui,
                criticality: .tier1,
                linkedControlIDs: ["CMMC-AC.L2-3.1.1", "CMMC-SC.L2-3.13.11", "NIST-AC-02"],
                isEncrypted: true,
                notes: "FedRAMP Moderate isolation boundary cluster running FIPS 140-3 cryptography."
            ),
            InventoryItem(
                name: "student-portal-db-primary",
                assetType: "Database (MySQL)",
                owner: "EdTech Systems Administrator",
                ipAddressOrURL: "sis-db.edu.internal",
                classification: .studentData,
                criticality: .tier2,
                linkedControlIDs: ["FERPA-34CFR-99.31", "FERPA-TECH-01"],
                isEncrypted: true,
                notes: "Primary student education record system storing transcripts and enrollment records."
            ),
            InventoryItem(
                name: "corp-macbook-pro-m5-dev42",
                assetType: "Endpoint Device (MacBook Pro)",
                owner: "Senior Software Engineer",
                ipAddressOrURL: "192.168.1.105",
                classification: .internalData,
                criticality: .tier3,
                linkedControlIDs: ["ISO-A.8.1", "HITRUST-05.0", "SOC2-CC6.4"],
                isEncrypted: true,
                notes: "Enrolled in MDM with FileVault enabled and EDR active."
            )
        ]
    }
}
