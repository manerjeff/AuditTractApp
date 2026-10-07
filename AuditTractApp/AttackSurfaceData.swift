import Foundation
import SwiftData
import Combine
import Combine

@Model
final class ExternalAsset {
    var id: UUID
    var domainOrIP: String
    var assetType: String
    var openPorts: [Int]
    var discoveredTechnologies: [String]
    var lastScanned: Date
    
    @Relationship(deleteRule: .cascade) 
    var findings: [SecurityFinding]
    
    init(domainOrIP: String, assetType: String = "Domain/API", openPorts: [Int] = [80, 443], discoveredTechnologies: [String] = []) {
        self.id = UUID()
        self.domainOrIP = domainOrIP
        self.assetType = assetType
        self.openPorts = openPorts
        self.discoveredTechnologies = discoveredTechnologies
        self.lastScanned = Date()
        self.findings = []
    }
}

@Model
final class SecurityFinding {
    var id: UUID
    var title: String
    var severity: String
    var findingDescription: String
    var remediationGuidance: String
    var status: String
    
    init(title: String, severity: String = "High", description: String, remediationGuidance: String, status: String = "Open") {
        self.id = UUID()
        self.title = title
        self.severity = severity
        self.findingDescription = description
        self.remediationGuidance = remediationGuidance
        self.status = status
    }
}

class AttackSurfaceEngine: ObservableObject {
    @Published var isScanning: Bool = false
}
