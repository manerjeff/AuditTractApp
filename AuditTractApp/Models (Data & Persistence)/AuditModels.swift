//
// AuditModels.swift
// AuditTractApp
//
// Created by Jeff Maner on 10/14/26.
//

import Foundation
import SwiftData

// MARK: - Assessment Parent Model
struct Assessment: Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var frameworkKey: String = "NIST_800_53"
    var leadAuditor: String = "Internal Compliance Lead"
    var status: String = "In Progress"
    var evaluations: [ControlEvaluation] = []
    var dateCreated: Date = Date()
}

// MARK: - Core SwiftData Control Evaluation
@Model
final class ControlEvaluation {
    @Attribute(.unique) var id: String
    var controlID: String
    var frameworkKey: String
    var status: String
    var auditorNotes: String
    var evidenceLocation: String
    var lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        controlID: String,
        frameworkKey: String = "NIST_800_53",
        status: String = "Not Evaluated",
        auditorNotes: String = "",
        evidenceLocation: String = "",
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.controlID = controlID
        self.frameworkKey = frameworkKey
        self.status = status
        self.auditorNotes = auditorNotes
        self.evidenceLocation = evidenceLocation
        self.lastUpdated = lastUpdated
    }
}

// MARK: - SwiftData Evidence Artifact Model
@Model
final class EvidenceArtifact {
    @Attribute(.unique) var id: String
    var title: String
    var controlID: String
    var filePath: String
    var fileType: String
    var addedDate: Date
    var notes: String
    
    init(
        id: String = UUID().uuidString,
        title: String,
        controlID: String = "",
        filePath: String = "",
        fileType: String = "PDF",
        addedDate: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.controlID = controlID
        self.filePath = filePath
        self.fileType = fileType
        self.addedDate = addedDate
        self.notes = notes
    }
}

// MARK: - Inventory & Asset Models (Clean Stored Relationships for SwiftData)
@Model
final class AssetItem {
    @Attribute(.unique) var id: String
    var name: String
    var serialNumber: String
    var ipAddress: String
    var assetType: String
    var criticality: String
    var dateAdded: Date
    
    // Explicit model references
    var location: Location?
    var assignedOwner: Employee?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        serialNumber: String = "",
        ipAddress: String = "",
        assetType: String = "Hardware",
        criticality: String = "Medium",
        location: Location? = nil,
        assignedOwner: Employee? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.serialNumber = serialNumber
        self.ipAddress = ipAddress
        self.assetType = assetType
        self.criticality = criticality
        self.location = location
        self.assignedOwner = assignedOwner
        self.dateAdded = dateAdded
    }
}

@Model
final class Location {
    @Attribute(.unique) var id: String
    var name: String
    var address: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        address: String = ""
    ) {
        self.id = id
        self.name = name
        self.address = address
    }
}

@Model
final class Employee {
    @Attribute(.unique) var id: String
    var name: String
    var role: String
    var department: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        role: String = "Staff",
        department: String = "IT"
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.department = department
    }
}
