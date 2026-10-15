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
    let name: String = "AuditEnvelopeManager"
    
    private init() {}
    
    func exportAssessmentEnvelope(for assessment: Assessment) -> URL? {
        let dto = AuditEnvelopeDTO(assessment: assessment)
        guard let data = try? JSONEncoder().encode(dto) else { return nil }
        
        let fileName = "AuditPackage_\(assessment.frameworkKey)_\(Int(Date().timeIntervalSince1970)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
    
    func exportEvaluationsEnvelope(title: String, evaluations: [ControlEvaluation]) -> URL? {
        let dto = AuditEnvelopeDTO(title: title, evaluations: evaluations)
        guard let data = try? JSONEncoder().encode(dto) else { return nil }
        
        let fileName = "AuditEvaluationsExport_\(Int(Date().timeIntervalSince1970)).json"
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
        
        try? context.save()
        return true
    }
}

// MARK: - Core Report Exporter
final class ReportExporter {
    static let shared = ReportExporter()
    
    private init() {}
    
    func generateAssessmentCSV(for assessment: Assessment) -> String {
        var csvString = "Control ID,Framework,Status,Evidence Location,Auditor Notes,Last Updated\n"
        
        for eval in assessment.evaluations {
            let cleanNotes = eval.auditorNotes
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            
            let cleanLocation = eval.evidenceLocation
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            
            let row = "\"\(eval.controlID)\",\"\(eval.frameworkKey)\",\"\(eval.status)\",\"\(cleanLocation)\",\"\(cleanNotes)\",\"\(eval.lastUpdated.formatted())\"\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
    func generateEvaluationsCSV(from evaluations: [ControlEvaluation]) -> String {
        var csvString = "Control ID,Framework,Status,Evidence Location,Auditor Notes,Last Updated\n"
        
        for eval in evaluations {
            let cleanNotes = eval.auditorNotes
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            
            let cleanLocation = eval.evidenceLocation
                .replacingOccurrences(of: "\"", with: "\"\"")
                .replacingOccurrences(of: "\n", with: " ")
            
            let row = "\"\(eval.controlID)\",\"\(eval.frameworkKey)\",\"\(eval.status)\",\"\(cleanLocation)\",\"\(cleanNotes)\",\"\(eval.lastUpdated.formatted())\"\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
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
}
