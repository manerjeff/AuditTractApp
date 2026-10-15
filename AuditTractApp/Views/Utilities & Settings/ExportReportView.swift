//
//  ExportReportView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

struct ExportReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var evaluations: [ControlEvaluation]
    
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var exportStatusMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Audit Workpapers") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Audit Manifest & Notes")
                            .font(.headline)
                        Text("Generates a structured CSV file containing control statuses, evidence file path locations, and internal workpaper notes for auditor handoff.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: generateCSVReport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export CSV Workpaper Report")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section("Export Audit Package (JSON Envelope)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Audit State Package")
                            .font(.headline)
                        Text("Export all control evaluations and evidence manifest pointers as a portable JSON envelope that can be imported into another AuditTract instance.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: generateEnvelopeExport) {
                        HStack {
                            Image(systemName: "doc.zipper")
                            Text("Export JSON Audit Envelope")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                if !exportStatusMessage.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(exportStatusMessage)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Export & Share")
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheetView(activityItems: [url])
                }
            }
        }
    }
    
    private func generateCSVReport() {
        let csvData = ReportExporter.shared.generateEvaluationsCSV(from: evaluations)
        let fileName = "AuditTract_Workpapers_\(Int(Date().timeIntervalSince1970)).csv"
        
        if let url = ReportExporter.shared.saveReportToDocuments(content: csvData, fileName: fileName) {
            self.exportedFileURL = url
            self.exportStatusMessage = "CSV exported successfully."
            self.showShareSheet = true
        }
    }
    
    private func generateEnvelopeExport() {
        if let url = AuditEnvelopeManager.shared.exportEvaluationsEnvelope(title: "Audit Export", evaluations: evaluations) {
            self.exportedFileURL = url
            self.exportStatusMessage = "Audit JSON Envelope created successfully."
            self.showShareSheet = true
        }
    }
}

// MARK: - UIKit Activity View Sheet Wrapper
struct ShareSheetView: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
