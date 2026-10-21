//
//  ComplianceData.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import Combine

// MARK: - Core Framework Model
struct Framework: Identifiable, Codable {
    var id: String
    var key: String
    var name: String
    var blurb: String
    var icon: String
    var totalControls: Int
    
    var themeColor: Color {
        let k = key.uppercased()
        if k.contains("SOC2") { return .orange }
        if k.contains("NIST") { return .green }
        if k.contains("ISO") { return .blue }
        return .orange
    }
}

struct CompliancePolicy: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let frameworkMapping: [String]
    let documentID: String
    let contentMarkdown: String
}

// MARK: - Audit Task Model
struct AuditTask: Identifiable, Codable {
    let id: String
    var frameworkKey: String
    let title: String
    let category: String
    
    // Catalog detail fields
    let blurb: String?
    let discussion: String?
    let controlStatement: String?
    let controlActivities: String?
    let examinationObjects: [String]?
    let interviewRoles: [String]?
    let relatedControls: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case frameworkKey
        case title
        case category
        case blurb
        case discussion
        case controlStatement
        case controlActivities
        case examinationObjects
        case interviewRoles
        case relatedControls
    }

    init(
        id: String,
        frameworkKey: String,
        title: String,
        category: String,
        blurb: String? = nil,
        discussion: String? = nil,
        controlStatement: String? = nil,
        controlActivities: String? = nil,
        examinationObjects: [String]? = nil,
        interviewRoles: [String]? = nil,
        relatedControls: [String]? = nil
    ) {
        self.id = id
        self.frameworkKey = frameworkKey
        self.title = title
        self.category = category
        self.blurb = blurb
        self.discussion = discussion
        self.controlStatement = controlStatement
        self.controlActivities = controlActivities
        self.examinationObjects = examinationObjects
        self.interviewRoles = interviewRoles
        self.relatedControls = relatedControls
    }

    init(from decoder: Decoder) throws {
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        let standardContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try standardContainer.decode(String.self, forKey: .id)
        self.title = try standardContainer.decode(String.self, forKey: .title)
        self.category = try standardContainer.decode(String.self, forKey: .category)
        
        if let fwKey = try? standardContainer.decode(String.self, forKey: .frameworkKey) {
            self.frameworkKey = fwKey
        } else {
            let prefix = self.id.components(separatedBy: "-").first?.uppercased() ?? "SOC2"
            self.frameworkKey = prefix.contains("NIST") ? "NIST" : "SOC2"
        }

        self.blurb = dynamicContainer.decodeAnyString(forKeys: ["blurb", "description"])
        self.discussion = dynamicContainer.decodeAnyString(forKeys: ["discussion", "guidance"])
        self.controlStatement = dynamicContainer.decodeAnyString(forKeys: ["controlStatement", "statement"])
        self.controlActivities = dynamicContainer.decodeAnyString(forKeys: ["controlActivities", "activities", "assessment_objective", "objective"])
        
        // 1. Decode Examination Objects / Assessment Evidence (Handles arrays or nested structures)
        self.examinationObjects = dynamicContainer.decodeFlexibleStringArray(forKeys: [
            "examinationObjects", "examination_objects", "objects", "assessment_objects", "evidence"
        ])
        
        // 2. Decode Interview Roles (Handles arrays or nested structures)
        self.interviewRoles = dynamicContainer.decodeFlexibleStringArray(forKeys: [
            "interviewRoles", "interview_roles", "roles", "interviewees"
        ])
            
        // 3. Decode Related Controls
        self.relatedControls = dynamicContainer.decodeFlexibleStringArray(forKeys: [
            "relatedControls", "related"
        ])
        
        if let container = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            print("📋 [DEBUG] Decoding task '\(self.id)' - Keys present: \(container.allKeys.map { $0.stringValue })")
        }

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(frameworkKey, forKey: .frameworkKey)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        
        try container.encodeIfPresent(blurb, forKey: .blurb)
        try container.encodeIfPresent(discussion, forKey: .discussion)
        try container.encodeIfPresent(controlStatement, forKey: .controlStatement)
        try container.encodeIfPresent(controlActivities, forKey: .controlActivities)
        try container.encodeIfPresent(examinationObjects, forKey: .examinationObjects)
        try container.encodeIfPresent(interviewRoles, forKey: .interviewRoles)
        try container.encodeIfPresent(relatedControls, forKey: .relatedControls)
    }
}

// MARK: - Helper for Flexible JSON Key Decoding
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { return nil }
    init?(intValue: Int) { return nil }
}

private extension KeyedDecodingContainer where K == DynamicCodingKey {
    func decodeAnyString(forKeys keys: [String]) -> String? {
        for keyStr in keys {
            if let key = DynamicCodingKey(stringValue: keyStr) {
                if let val = try? self.decode(String.self, forKey: key), !val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return val
                }
            }
        }
        return nil
    }
    
    func decodeFlexibleStringArray(forKeys keys: [String]) -> [String]? {
        for keyStr in keys {
            guard let key = DynamicCodingKey(stringValue: keyStr) else { continue }
            
            // Try decoding flat array: ["item1", "item2"]
            if let arrayVal = try? self.decode([String].self, forKey: key), !arrayVal.isEmpty {
                return arrayVal
            }
            
            // Try decoding single string: "item1"
            if let singleVal = try? self.decode(String.self, forKey: key), !singleVal.isEmpty {
                return [singleVal]
            }
            
            // Try decoding array of objects: [{"name": "item1"}, {"title": "item2"}]
            if let objectArray = try? self.decode([[String: String]].self, forKey: key) {
                let extracted = objectArray.compactMap { dict in
                    dict["name"] ?? dict["title"] ?? dict["label"] ?? dict["id"]
                }
                if !extracted.isEmpty { return extracted }
            }
        }
        return nil
    }
}


    // MARK: - Compliance Manager Engine
    class ComplianceManager: ObservableObject {
        @Published var frameworks: [Framework] = []
        @Published var tasks: [AuditTask] = []
        
        private var cancellables = Set<AnyCancellable>()
        
        init() {
            self.frameworks = [
                Framework(id: "1", key: "SOC2", name: "SOC 2 Type II", blurb: "AICPA Trust Services Criteria.", icon: "shield.checkered", totalControls: 64),
                Framework(id: "2", key: "NIST", name: "NIST SP 800-53 Rev 5", blurb: "NVD Security and Privacy Controls.", icon: "building.columns.fill", totalControls: 147)
            ]
            
            ControlSyncManager.shared.$tasks
                .receive(on: DispatchQueue.main)
                .sink { [weak self] syncedTasks in
                    guard let self = self else { return }
                    if !syncedTasks.isEmpty {
                        self.tasks = syncedTasks
                    } else {
                        self.tasks = self.buildAllFallbackTasks()
                    }
                }
                .store(in: &cancellables)
        }
        
        func buildAllFallbackTasks() -> [AuditTask] {
            return [
                AuditTask(id: "NIST-AC-01", frameworkKey: "NIST", title: "Policy and Procedures", category: "AC", blurb: "Establish access control policy."),
                AuditTask(id: "NIST-AC-02", frameworkKey: "NIST", title: "Account Management", category: "AC", blurb: "Manage system accounts.")
            ]
        }
        
        // MARK: - Audit Estimator Engine
        struct AuditEstimator {
            static func estimateHours(for tasks: [AuditTask]) -> Int {
                return tasks.count * 2
            }
            
            static func calculateProgress(evaluations: [ControlEvaluation], totalTasks: Int) -> Double {
                guard totalTasks > 0 else { return 0.0 }
                let completed = evaluations.filter { $0.status != "Not Evaluated" }.count
                return Double(completed) / Double(totalTasks)
            }
        }
        
    }
