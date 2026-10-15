//
//  UserManualView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI

struct UserManualView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("User Manual & Guidance")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Welcome to AuditTract. Use this application to conduct compliance readiness reviews across frameworks like SOC2, ISO27001, and NIST.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Group {
                        Text("1. Control Evaluation")
                            .font(.headline)
                        Text("Select a framework and filter controls from the sidebar. Evaluate status and maintain auditor workpaper notes directly in the detail view.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        Text("2. Evidence & Reports")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("Attach evidence files and generate executive summary reports using the corresponding tabs.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("User Manual")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
