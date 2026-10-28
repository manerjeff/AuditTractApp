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
    @Query private var inventoryItems: [InventoryItem]
    @Query private var vulnerabilities: [VulnerabilityFinding]
    @Query private var scans: [ScanExecution]
    
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var exportStatusMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Summary Metrics of the package
                Section("Package Inclusions") {
                    LabeledContent("Evaluated Controls", value: "\(evaluations.count)")
                    LabeledContent("Registered Inventory Assets", value: "\(inventoryItems.count)")
                    LabeledContent("Attack Surface Findings", value: "\(vulnerabilities.count)")
                    LabeledContent("Recorded Audit Scans", value: "\(scans.count)")
                }
                
                // Comprehensive Binder
                Section("Comprehensive Audit Binder (CSV)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("All-In-One Audit Manifest")
                            .font(.headline)
                        Text("Exports a structured CSV combining control workpapers, full asset inventory with custodians, and attack surface CVE findings for executive or regulatory handoff.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: generateComprehensiveCSV) {
                        HStack {
                            Image(systemName: "doc.richtext.fill")
                                .foregroundColor(.accentColor)
                            Text("Export Comprehensive Audit CSV")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Focused Workpapers Export
                Section("Control Workpapers Only (CSV)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Framework Evaluations")
                            .font(.headline)
                        Text("Export control IDs, status determinations, auditor notes, and evidence location pointers.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: generateWorkpaperCSV) {
                        HStack {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundColor(.blue)
                            Text("Export Controls Workpaper CSV")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Master JSON Package
                Section("Portable Audit Package (JSON Envelope)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full System State Envelope")
                            .font(.headline)
                        Text("Exports a complete cryptographic snapshot including controls, asset metadata, scan records, and vulnerability findings to migrate or archive.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: generateEnvelopeExport) {
                        HStack {
                            Image(systemName: "doc.zipper")
                                .foregroundColor(.orange)
                            Text("Export Master JSON Audit Envelope")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                if !exportStatusMessage.isEmpty {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(exportStatusMessage)
                                .font(.subheadline)
                                .fontWeight(.medium)
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
    
    // MARK: - Export Generators
    
    private func generateComprehensiveCSV() {
        let content = ReportExporter.shared.generateComprehensiveAuditCSV(
            evaluations: evaluations,
            inventory: inventoryItems,
            vulnerabilities: vulnerabilities
        )
        let fileName = "AuditTract_ComprehensiveBinder_\(Int(Date().timeIntervalSince1970)).csv"
        
        if let url = ReportExporter.shared.saveReportToDocuments(content: content, fileName: fileName) {
            self.exportedFileURL = url
            self.exportStatusMessage = "Comprehensive Binder CSV ready."
            self.showShareSheet = true
        }
    }
    
    private func generateWorkpaperCSV() {
        let content = ReportExporter.shared.generateEvaluationsCSV(from: evaluations)
        let fileName = "AuditTract_Controls_\(Int(Date().timeIntervalSince1970)).csv"
        
        if let url = ReportExporter.shared.saveReportToDocuments(content: content, fileName: fileName) {
            self.exportedFileURL = url
            self.exportStatusMessage = "Controls Workpaper CSV ready."
            self.showShareSheet = true
        }
    }
    
    private func generateEnvelopeExport() {
        if let url = AuditEnvelopeManager.shared.exportCompleteAuditPackage(
            title: "Comprehensive Audit Snapshot",
            evaluations: evaluations,
            inventory: inventoryItems,
            vulnerabilities: vulnerabilities,
            scans: scans
        ) {
            self.exportedFileURL = url
            self.exportStatusMessage = "Master JSON Package ready."
            self.showShareSheet = true
        }
    }
}

// MARK: - UIKit Activity View Sheet Wrapper with iPad Popover Support
#if canImport(UIKit)
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        if let popover = controller.popoverPresentationController {
            popover.permittedArrowDirections = .any
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
// MARK: - macOS Fallback View
struct ShareSheetView: View {
    var activityItems: [Any]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Report Export Complete")
                .font(.headline)
            Text("File saved to Documents folder.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}
#endif
