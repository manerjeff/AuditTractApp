import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserWorkspace.self, ControlLog.self, EvidenceItem.self])
    }
    @main
    struct AuditTractApp: App {
        @StateObject private var syncManager = ControlSyncManager.shared

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .task {
                        // Triggers silent background check without blocking UI launch
                        await syncManager.checkForUpdates()
                    }
            }
        }
    }

}


