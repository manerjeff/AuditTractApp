import SwiftUI
import SwiftData

@Model
final class UserWorkspace {
    var id: UUID
    var name: String
    var createdDate: Date
    var scopedFrameworkKeys: [String] = []
    @Relationship(deleteRule: .cascade) var controlLogs: [ControlLog] = []
    
    init(name: String = "Corporate Audit Workspace", scopedFrameworkKeys: [String] = []) {
        self.id = UUID()
        self.name = name.isEmpty ? "New Audit Workspace" : name
        self.createdDate = Date()
        self.scopedFrameworkKeys = scopedFrameworkKeys
        self.controlLogs = []
    }
    
    var overallReadinessScore: Int {
        guard !controlLogs.isEmpty else { return 0 }
        let compliantCount = controlLogs.filter { 
            let s = $0.status.lowercased()
            return s == "compliant" || s == "implemented" 
        }.count
        return Int((Double(compliantCount) / Double(controlLogs.count)) * 100)
    }
    
    func isFrameworkInScope(_ key: String) -> Bool {
        !scopedFrameworkKeys.contains(key.uppercased())
    }
    
    func toggleFrameworkScope(_ key: String) {
        let normalized = key.uppercased()
        if scopedFrameworkKeys.contains(normalized) {
            scopedFrameworkKeys.removeAll { $0 == normalized }
        } else {
            scopedFrameworkKeys.append(normalized)
        }
    }
    
    // MARK: - Reset Actions
    
    /// Clears evaluation statuses, notes, and evidence for a specific framework (e.g. "SOC1")
    func resetFrameworkData(_ frameworkKey: String) {
        let normalized = frameworkKey.uppercased()
        controlLogs.removeAll { log in
            log.frameworkKey.uppercased().contains(normalized) ||
            log.taskID.uppercased().hasPrefix(normalized)
        }
    }
    
    /// Wipes all evaluations, notes, evidence, and scope settings across the entire workspace
    func resetMasterWorkspace() {
        controlLogs.removeAll()
        scopedFrameworkKeys.removeAll()
    }
}

@Model
final class ControlLog {
    var id: UUID
    var frameworkKey: String
    var controlTitle: String
    var taskID: String
    var status: String
    var notes: String
    var lastUpdated: Date
    @Relationship(deleteRule: .cascade) var evidenceItems: [EvidenceItem] = []
    
    init(frameworkKey: String, controlTitle: String, taskID: String, status: String = "Not Evaluated", notes: String = "") {
        self.id = UUID()
        self.frameworkKey = frameworkKey
        self.controlTitle = controlTitle
        self.taskID = taskID
        self.status = status
        self.notes = notes
        self.lastUpdated = Date()
        self.evidenceItems = []
    }
}
