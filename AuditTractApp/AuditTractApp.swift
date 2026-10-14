import SwiftUI
import SwiftData

@main
struct AuditTractApp: App {
    @StateObject private var estimator = AuditEstimator()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(estimator)
        }
        // Attach Full SQLite Model Container
        .modelContainer(for: [
            Employee.self,
            Location.self,
            AssetItem.self,
            Assessment.self,
            ControlEvaluation.self,
            EvidenceArtifact.self,
            ScanExecution.self,
            VulnerabilityFinding.self,
            SecurityNewsArticle.self
        ])
    }
}
