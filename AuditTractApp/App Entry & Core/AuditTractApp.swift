//
//  AuditTractApp.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

@main
struct AuditTractApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            ControlEvaluation.self,
            EvidenceArtifact.self,
            AssetItem.self,
            Location.self,
            Employee.self
        ])
    }
}

