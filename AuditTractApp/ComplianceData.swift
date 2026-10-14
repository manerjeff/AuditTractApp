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

// MARK: - Audit Task Model
struct AuditTask: Identifiable, Codable {
    var id: String
    var frameworkKey: String
    var title: String
    var category: String
    var blurb: String?
    var discussion: String?
    var controlStatement: String?
    var controlActivities: String?
    var examinationObjects: [String]?
    var interviewRoles: [String]?
    var relatedControls: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, category, description, guidance, frameworkKey, blurb, discussion
        case controlStatement, controlActivities, examinationObjects, interviewRoles, relatedControls
    }

    init(id: String, frameworkKey: String, title: String, category: String, blurb: String? = nil, discussion: String? = nil, controlStatement: String? = nil, controlActivities: String? = nil, examinationObjects: [String]? = nil, interviewRoles: [String]? = nil, relatedControls: [String]? = nil) {
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? "N/A"
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Untitled Control"
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "General"
        
        if let fwKey = try? container.decode(String.self, forKey: .frameworkKey) {
            self.frameworkKey = fwKey
        } else {
            let prefix = self.id.components(separatedBy: "-").first?.uppercased() ?? "SOC2"
            self.frameworkKey = prefix.contains("NIST") ? "NIST" : "SOC2"
        }
        
        self.blurb = (try? container.decode(String.self, forKey: .blurb)) ?? (try? container.decode(String.self, forKey: .description))
        self.discussion = (try? container.decode(String.self, forKey: .discussion)) ?? (try? container.decode(String.self, forKey: .guidance))
        self.controlStatement = try? container.decode(String.self, forKey: .controlStatement)
        self.controlActivities = try? container.decode(String.self, forKey: .controlActivities)
        self.examinationObjects = try? container.decode([String].self, forKey: .examinationObjects)
        self.interviewRoles = try? container.decode([String].self, forKey: .interviewRoles)
        self.relatedControls = try? container.decode([String].self, forKey: .relatedControls)
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

// MARK: - Audit Estimator Engine
final class AuditEstimator: ObservableObject {
    @Published var frameworks: [Framework] = []
    @Published var tasks: [AuditTask] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.frameworks = [
            Framework(id: "1", key: "SOC2", name: "SOC 2 Type II", blurb: "AICPA Trust Services Criteria.", icon: "shield.checkered", totalControls: 64),
            Framework(id: "2", key: "NIST", name: "NIST SP 800-53 Rev 5", blurb: "NVD Security and Privacy Controls.", icon: "building.columns.fill", totalControls: 147)
        ]
        
        // Subscribe to ControlSyncManager for live/bundled task ingestion
        ControlSyncManager.shared.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] syncedTasks in
                guard let self = self else { return }
                let fallbacks = buildAllFallbackTasks()
                
                if syncedTasks.isEmpty {
                    self.tasks = fallbacks
                } else {
                    // Combine converted NIST tasks with default SOC 2 fallbacks from TaskBuilders
                    let soc2Fallbacks = fallbacks.filter { $0.frameworkKey.uppercased().contains("SOC") }
                    self.tasks = syncedTasks + soc2Fallbacks
                }
            }
            .store(in: &cancellables)
    }
}

