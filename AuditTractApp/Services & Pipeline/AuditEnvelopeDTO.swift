//
//  AuditEnvelopeDTO.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import Foundation

// MARK: - Decoupled Data Transfer Object for JSON Export/Import
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

struct AuditEnvelopeDTO: Codable {
    var assessmentID: String
    var title: String
    var frameworkKey: String
    var exportDate: Date
    var evaluations: [ControlEvaluationDTO]
    
    init(assessment: Assessment) {
        self.assessmentID = assessment.id
        self.title = assessment.title
        self.frameworkKey = assessment.frameworkKey
        self.exportDate = Date()
        self.evaluations = assessment.evaluations.map { ControlEvaluationDTO(from: $0) }
    }
    
    init(title: String, frameworkKey: String = "NIST_800_53", evaluations: [ControlEvaluation]) {
        self.assessmentID = UUID().uuidString
        self.title = title
        self.frameworkKey = frameworkKey
        self.exportDate = Date()
        self.evaluations = evaluations.map { ControlEvaluationDTO(from: $0) }
    }
}
