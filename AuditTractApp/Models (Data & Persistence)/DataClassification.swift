// === File: ./Models (Data & Persistence)/DataClassification.swift ===
//
//  DataClassification.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/20/26.
//

import Foundation

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

// MARK: - Asset Lifecycle Status Enum
enum AssetStatus: String, Codable, CaseIterable {
    case active = "Active"
    case maintenance = "Maintenance / In Repair"
    case decommissioned = "Decommissioned"
    case disposed = "Disposed / Sanitized"
}
