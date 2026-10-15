//
//  AuditSessionView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

struct AuditSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var evaluations: [ControlEvaluation]
    
    @State private var selectedTab: SessionTab = .controls
    
    enum SessionTab: String, CaseIterable, Identifiable {
        case controls = "Controls"
        case locker = "Evidence Locker"
        case export = "Export"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Session Mode", selection: $selectedTab) {
                    ForEach(SessionTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    switch selectedTab {
                    case .controls:
                        ControlCenterView()
                    case .locker:
                        EvidenceLockerView()
                    case .export:
                        ExportReportView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Audit Workspace")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
