//
//  Employee.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//


import Foundation
import SwiftData

// MARK: - 1. Employee Model
@Model
final class Employee {
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var role: String
    var department: String
    
    init(id: String = UUID().uuidString, name: String, email: String, role: String, department: String) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.department = department
    }
}

// MARK: - 2. Facility / Location Model
@Model
final class Location {
    @Attribute(.unique) var id: String
    var name: String
    var address: String
    var facilityType: String // e.g., "Data Center", "Corporate HQ", "Branch Office"
    
    init(id: String = UUID().uuidString, name: String, address: String, facilityType: String) {
        self.id = id
        self.name = name
        self.address = address
        self.facilityType = facilityType
    }
}

// MARK: - 3. Asset / Host Inventory Model
@Model
final class AssetItem {
    @Attribute(.unique) var id: String
    var name: String
    var ipAddress: String
    var assetType: String // e.g., "Server", "Workstation", "Cloud Router", "Database"
    var criticality: String // e.g., "High", "Medium", "Low"
    
    // Relationships
    var location: Location?
    var assignedOwner: Employee?
    
    init(id: String = UUID().uuidString, name: String, ipAddress: String, assetType: String, criticality: String = "Medium") {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.assetType = assetType
        self.criticality = criticality
    }
}

// MARK: - 4. Master Assessment Session
@Model
final class Assessment {
    @Attribute(.unique) var id: String
    var title: String
    var frameworkKey: String // "NIST", "SOC2", etc.
    var createdDate: Date
    var isCompleted: Bool
    
    // Relationships
    var scopedLocation: Location?
    var leadAuditor: Employee?
    
    @Relationship(deleteRule: .cascade) 
    var evaluations: [ControlEvaluation] = []
    
    init(id: String = UUID().uuidString, title: String, frameworkKey: String, createdDate: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.frameworkKey = frameworkKey
        self.createdDate = createdDate
        self.isCompleted = isCompleted
    }
}

// MARK: - 5. Control Evaluation Workpaper Record
@Model
final class ControlEvaluation {
    @Attribute(.unique) var id: String
    var controlID: String // e.g., "AC-01", "CC1.1"
    var frameworkKey: String
    var status: String // "Not Evaluated", "In Progress", "Compliant", "Not Compliant"
    var auditorNotes: String
    var lastUpdated: Date
    
    // Relationships
    var assessment: Assessment?
    
    @Relationship(deleteRule: .cascade)
    var evidenceArtifacts: [EvidenceArtifact] = []
    
    init(id: String = UUID().uuidString, controlID: String, frameworkKey: String, status: String = "Not Evaluated", auditorNotes: String = "", lastUpdated: Date = Date()) {
        self.id = id
        self.controlID = controlID
        self.frameworkKey = frameworkKey
        self.status = status
        self.auditorNotes = auditorNotes
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 6. Evidence Artifact Attachment Model
@Model
final class EvidenceArtifact {
    @Attribute(.unique) var id: String
    var title: String
    var fileName: String
    var relativeFilePath: String? // Path on iPad local storage
    var addedDate: Date
    
    // Relationship
    var evaluation: ControlEvaluation?
    
    init(id: String = UUID().uuidString, title: String, fileName: String, relativeFilePath: String? = nil, addedDate: Date = Date()) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.relativeFilePath = relativeFilePath
        self.addedDate = addedDate
    }
}
