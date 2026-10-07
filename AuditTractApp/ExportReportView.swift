import SwiftUI
import SwiftData

struct ExportReportView: View {
    let workspace: UserWorkspace
    @ObservedObject var dataManager: AuditEstimator
    @Binding var isPresented: Bool
    
    @State private var showingShareSheet = false
    @State private var exportedCSVURL: URL? = nil
    @State private var exportSummaryText: String = ""
    @State private var isGenerating = false
    
    var activeFrameworks: [Framework] {
        dataManager.frameworks.filter { workspace.isFrameworkInScope($0.key) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                
                // Workspace Header Summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("EXECUTIVE COMPLIANCE REPORT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(TractColor.copper)
                    
                    Text(workspace.name)
                        .font(.title2)
                        .bold()
                        .foregroundColor(TractColor.ink)
                    
                    Text("Overall Readiness: \(workspace.overallReadinessScore)% • \(workspace.controlLogs.count) Controls Audited")
                        .font(.caption)
                        .foregroundColor(TractColor.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TractColor.card)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                
                // In-Scope Standards Included in Report
                VStack(alignment: .leading, spacing: 10) {
                    Text("IN-SCOPE STANDARDS INCLUDED (\(activeFrameworks.count))")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(TractColor.label)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(activeFrameworks) { fw in
                                HStack(spacing: 6) {
                                    Image(systemName: fw.icon)
                                        .foregroundColor(fw.themeColor)
                                    Text(fw.key)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(TractColor.ink)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(TractColor.card)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(TractColor.stroke, lineWidth: 1))
                            }
                        }
                    }
                }
                
                // Live Preview / Summary Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("REPORT PREVIEW & MANIFEST")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(TractColor.copper)
                    
                    ScrollView {
                        Text(exportSummaryText.isEmpty ? "Tap 'Generate Audit Export' below to compile workspace control logs and evidence links into a client report." : exportSummaryText)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(exportSummaryText.isEmpty ? TractColor.secondary : TractColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(maxHeight: 220)
                    .background(TractColor.canvas)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(TractColor.stroke, lineWidth: 1))
                }
                
                Spacer()
                
                // Export Actions
                VStack(spacing: 12) {
                    Button(action: generateCSVExport) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.black)
                                    .padding(.trailing, 6)
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                            }
                            Text(isGenerating ? "Compiling Report..." : "Generate & Share Audit CSV")
                                .font(.headline)
                                .bold()
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(TractColor.copper)
                        .cornerRadius(10)
                    }
                    .disabled(isGenerating)
                }
            }
            .padding(24)
            .background(TractColor.canvas)
            .navigationTitle("Export Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(TractColor.secondary)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedCSVURL {
                    ShareSheetView(activityItems: [url])
                }
            }
            .onAppear {
                buildSummaryPreview()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func buildSummaryPreview() {
        var preview = "AUDIT TRACT EXECUTIVE MANIFEST\n"
        preview += "Workspace: \(workspace.name)\n"
        preview += "Generated: \(Date().formatted(date: .numeric, time: .shortened))\n"
        preview += "Readiness Score: \(workspace.overallReadinessScore)%\n\n"
        preview += "CONTROL LOG BREAKDOWN:\n"
        
        if workspace.controlLogs.isEmpty {
            preview += "• No controls evaluated yet in this workspace.\n"
        } else {
            for log in workspace.controlLogs {
                preview += "• [\(log.taskID)] \(log.controlTitle)\n"
                preview += "  Status: \(log.status.uppercased()) | Evidence Files: \(log.evidenceItems.count)\n"
            }
        }
        self.exportSummaryText = preview
    }
    
    private func generateCSVExport() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let csvString = ReportExporter.generateCSV(workspace: workspace, tasks: dataManager.tasks)
            let fileName = "\(workspace.name.replacingOccurrences(of: " ", with: "_"))_Audit_Report.csv"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    self.exportedCSVURL = tempURL
                    self.isGenerating = false
                    self.showingShareSheet = true
                }
            } catch {
                print("Failed to write CSV: \(error)")
                DispatchQueue.main.async {
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - UIKit Activity Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

