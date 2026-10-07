import SwiftUI
import Combine

// MARK: - Core Framework & Task Data Models

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
        if k.contains("ISO") { return .blue }
        if k.contains("NIST") { return .green }
        if k.contains("HIPAA") { return .teal }
        if k.contains("PCI") { return .red }
        if k.contains("SOC1") { return .purple }
        if k.contains("FEDRAMP") { return .indigo }
        if k.contains("GDPR") { return .mint }
        return TractColor.copper
    }
}

struct AuditTask: Identifiable, Codable {
    var id: String
    var frameworkKey: String
    var title: String
    var category: String
    var blurb: String?
    var discussion: String?
    var controlActivities: String?
}

// MARK: - Audit Estimator Engine

final class AuditEstimator: ObservableObject {
    @Published var frameworks: [Framework] = []
    @Published var tasks: [AuditTask] = []
    
    init() {
        self.frameworks = [
            Framework(id: "1", key: "SOC2", name: "SOC 2 Type II", blurb: "AICPA Trust Services Criteria for Security, Availability, and Confidentiality.", icon: "shield.checkered", totalControls: 64),
            Framework(id: "2", key: "ISO27001", name: "ISO/IEC 27001:2022", blurb: "International standard for Information Security Management Systems (ISMS).", icon: "globe.americas.fill", totalControls: 93),
            Framework(id: "3", key: "NIST", name: "NIST SP 800-53 Rev 5", blurb: "Federal security and privacy controls for systems and organizations.", icon: "building.columns.fill", totalControls: 287),
            Framework(id: "4", key: "HIPAA", name: "HIPAA Security Rule", blurb: "Protection of electronic Protected Health Information (ePHI).", icon: "cross.case.fill", totalControls: 42),
            Framework(id: "5", key: "PCIDSS", name: "PCI DSS v4.0", blurb: "Payment Card Industry Data Security Standard for cardholder data.", icon: "creditcard.fill", totalControls: 252),
            Framework(id: "6", key: "SOC1", name: "SOC 1 / SSAE 18", blurb: "Reporting on controls relevant to user entities' internal control over financial reporting.", icon: "doc.text.fill", totalControls: 38),
            Framework(id: "7", key: "FEDRAMP", name: "FedRAMP Moderate", blurb: "US Federal Risk and Authorization Management Program baseline.", icon: "flag.fill", totalControls: 325),
            Framework(id: "8", key: "GDPR", name: "EU GDPR", blurb: "General Data Protection Regulation for personal privacy and data rights.", icon: "lock.doc.fill", totalControls: 99)
        ]
        
        loadTasks()
    }
    
    private func loadTasks() {
        // Attempt clean JSON decoding first
        if let fileURL = Bundle.main.url(forResource: "controls", withExtension: "json"),
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([AuditTask].self, from: data),
           !decoded.isEmpty {
            self.tasks = decoded
            return
        }
        
        // Fallback tasks from extension builder
        self.tasks = buildAllFallbackTasks()
    }
}

// MARK: - Subscription Manager

final class SubscriptionManager: ObservableObject {
    @AppStorage("firstLaunchTimestamp") private var firstLaunchTimestamp: Double = 0.0
    @AppStorage("isProSubscribed") var isProSubscribed: Bool = false
    
    init() {
        if firstLaunchTimestamp == 0.0 {
            firstLaunchTimestamp = Date().timeIntervalSince1970
        }
    }
    
    var isTrialActive: Bool {
        let trialDuration: TimeInterval = 7 * 24 * 60 * 60
        let elapsed = Date().timeIntervalSince1970 - firstLaunchTimestamp
        return elapsed < trialDuration
    }
    
    var daysRemainingInTrial: Int {
        let trialDuration: TimeInterval = 7 * 24 * 60 * 60
        let elapsed = Date().timeIntervalSince1970 - firstLaunchTimestamp
        let remainingSeconds = max(0, trialDuration - elapsed)
        return Int(ceil(remainingSeconds / (24 * 60 * 60)))
    }
    
    var hasAccess: Bool {
        return isProSubscribed || isTrialActive
    }
}

