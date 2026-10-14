import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ControlCenterView: View {
    @EnvironmentObject var estimator: AuditEstimator
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = ControlSyncManager.shared
    
    // Live SwiftData Queries for evaluations & evidence
    @Query private var allEvaluations: [ControlEvaluation]
    @Query private var allEvidence: [EvidenceArtifact]
    
    // Active framework scope (Defaults to NIST)
    var activeFrameworkKey: String = "NIST"
    @State private var selectedControlID: String? = nil
    @State private var searchText: String = ""
    
    // Active Workpaper Form State
    @State private var currentNotes: String = ""
    @State private var currentStatus: String = "Not Evaluated"
    
    // File Importer State
    @State private var showingFileImporter: Bool = false
    
    // MARK: - Single-Framework Scope Filtering
    var filteredControls: [AuditTask] {
        estimator.tasks.filter { task in
            let taskKey = task.frameworkKey.uppercased()
            let scopeKey = activeFrameworkKey.uppercased()
            
            let matchesScope = taskKey.contains(scopeKey) || scopeKey.contains(taskKey)
            
            if searchText.isEmpty {
                return matchesScope
            } else {
                return matchesScope && (
                    task.id.localizedCaseInsensitiveContains(searchText) ||
                    task.title.localizedCaseInsensitiveContains(searchText) ||
                    (task.controlStatement?.localizedCaseInsensitiveContains(searchText) ?? false)
                )
            }
        }
    }
    
    var evaluatedCount: Int {
        filteredControls.filter { getLogStatus(for: $0.id) != "Not Evaluated" }.count
    }
    
    var completionPercentage: Double {
        guard !filteredControls.isEmpty else { return 0.0 }
        return Double(evaluatedCount) / Double(filteredControls.count)
    }
    
    var selectedControl: AuditTask? {
        if let id = selectedControlID {
            return filteredControls.first(where: { $0.id == id })
        }
        return filteredControls.first
    }
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar List
            VStack(spacing: 0) {
                // Header & Progress Ring
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(activeFrameworkKey) AUDIT SCOPE")
                                .font(.caption2)
                                .fontWeight(.black)
                                .foregroundColor(.accentColor)
                                .tracking(1)
                            
                            Text("Controls (\(filteredControls.count))")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // Mini Progress Ring
                        ZStack {
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: completionPercentage)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionPercentage)
                            Text("\(Int(completionPercentage * 100))%")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .frame(width: 36, height: 36)
                    }
                    
                    // Glassmorphic Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                        TextField("Search \(activeFrameworkKey) controls...", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                
                Divider()
                
                // Controls Sidebar List
                List(filteredControls, id: \.id) { control in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedControlID = control.id
                        }
                        loadWorkpaperState(for: control.id)
                    }) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(control.id)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text(cleanTitle(for: control))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            // Status Badge
                            let status = getLogStatus(for: control.id)
                            Text(status)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(status).opacity(0.18))
                                .foregroundColor(statusColor(status))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(statusColor(status).opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: statusColor(status).opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        selectedControlID == control.id
                        ? Color.accentColor.opacity(0.15)
                        : Color.clear
                    )
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(activeFrameworkKey)
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            // MARK: - Detail Workpaper View
            if let control = selectedControl {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Hero Header Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("\(control.frameworkKey) • \(control.category)", systemImage: "shield.checkered")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                            
                            Text("\(control.id): \(cleanTitle(for: control))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [Color(uiColor: .secondarySystemGroupedBackground), Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                        
                        // 1. Control Statement Card
                        if let statement = control.controlStatement ?? control.blurb, !statement.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Control Statement", systemImage: "doc.text.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                                
                                Text(statement)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .foregroundColor(.primary)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                        }
                        
                        // 2. Official Guidance / Discussion
                        if let discussion = control.discussion, !discussion.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("NVD Guidance & Discussion", systemImage: "info.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Text(discussion)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .foregroundColor(.primary)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                        }
                        
                        // 3. Related Controls Cross-Reference
                        if let related = control.relatedControls, !related.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("RELATED CONTROLS")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(related, id: \.self) { item in
                                            Button(action: { searchText = item }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "link")
                                                        .font(.caption2)
                                                    Text(item)
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.accentColor.opacity(0.12))
                                                .foregroundColor(.accentColor)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        // 4. Interactive Status Selector Block
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EVALUATION STATUS")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 10) {
                                ForEach(["Not Evaluated", "In Progress", "Compliant", "Not Compliant"], id: \.self) { st in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            currentStatus = st
                                        }
                                        saveWorkpaperState(for: control.id)
                                    }) {
                                        Text(st)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(currentStatus == st ? statusColor(st) : Color(uiColor: .tertiarySystemGroupedBackground))
                                            .foregroundColor(currentStatus == st ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            .shadow(color: currentStatus == st ? statusColor(st).opacity(0.35) : Color.clear, radius: 8, x: 0, y: 3)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        // 5. Auditor Workpaper Notes Card
                        VStack(alignment: .leading, spacing: 10) {
                            Label("AUDITOR WORKPAPER NOTES", systemImage: "square.and.pencil")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $currentNotes)
                                .frame(minHeight: 120)
                                .padding(10)
                                .scrollContentBackground(.hidden)
                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                                .onChange(of: currentNotes) { _, _ in
                                    saveWorkpaperState(for: control.id)
                                }
                        }
                        .padding(18)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        // 6. Evidence Locker Card with Native File Picker
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("ATTACHED EVIDENCE LOCKER", systemImage: "paperclip")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { showingFileImporter = true }) {
                                    Label("Attach File", systemImage: "doc.badge.plus")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            let evidenceForControl = getEvidenceForControl(control.id)
                            if evidenceForControl.isEmpty {
                                Text("No evidence items attached to this control standard yet.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(evidenceForControl) { artifact in
                                        HStack {
                                            Image(systemName: "doc.text.fill")
                                                .foregroundColor(.accentColor)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(artifact.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text(artifact.fileName)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Button(action: { removeEvidence(artifact) }) {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(20)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.pdf, .image, .plainText],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        guard let sourceURL = urls.first, let control = selectedControl else { return }
                        if sourceURL.startAccessingSecurityScopedResource() {
                            defer { sourceURL.stopAccessingSecurityScopedResource() }
                            saveImportedFile(from: sourceURL, for: control.id)
                        }
                    case .failure(let error):
                        print("❌ File import failed: \(error.localizedDescription)")
                    }
                }
                .onAppear {
                    loadWorkpaperState(for: control.id)
                }
                .onChange(of: selectedControlID) { _, newID in
                    if let newID = newID { loadWorkpaperState(for: newID) }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a control from the sidebar to begin evaluation.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    }
    
    // MARK: - SwiftData Helpers
    private func cleanTitle(for control: AuditTask) -> String {
        control.title.replacingOccurrences(of: "\(control.id): ", with: "")
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Compliant": return .green
        case "In Progress": return .orange
        case "Not Compliant": return .red
        default: return .secondary
        }
    }
    
    private func getEvaluationRecord(for id: String) -> ControlEvaluation? {
        allEvaluations.first(where: { $0.controlID == id && $0.frameworkKey == activeFrameworkKey })
    }
    
    private func getLogStatus(for id: String) -> String {
        getEvaluationRecord(for: id)?.status ?? "Not Evaluated"
    }
    
    private func getEvidenceForControl(_ id: String) -> [EvidenceArtifact] {
        guard let eval = getEvaluationRecord(for: id) else { return [] }
        return eval.evidenceArtifacts
    }
    
    private func loadWorkpaperState(for id: String) {
        if let record = getEvaluationRecord(for: id) {
            currentStatus = record.status
            currentNotes = record.auditorNotes
        } else {
            currentStatus = "Not Evaluated"
            currentNotes = ""
        }
    }
    
    private func saveWorkpaperState(for id: String) {
        if let existingRecord = getEvaluationRecord(for: id) {
            existingRecord.status = currentStatus
            existingRecord.auditorNotes = currentNotes
            existingRecord.lastUpdated = Date()
        } else {
            let newRecord = ControlEvaluation(
                controlID: id,
                frameworkKey: activeFrameworkKey,
                status: currentStatus,
                auditorNotes: currentNotes
            )
            modelContext.insert(newRecord)
        }
        try? modelContext.save()
    }
    
    private func saveImportedFile(from url: URL, for controlID: String) {
        let fileName = url.lastPathComponent
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let destinationURL = documentsURL.appendingPathComponent(fileName)
        try? fileManager.copyItem(at: url, to: destinationURL)
        
        let evalRecord: ControlEvaluation
        if let existing = getEvaluationRecord(for: controlID) {
            evalRecord = existing
        } else {
            let newRecord = ControlEvaluation(
                controlID: controlID,
                frameworkKey: activeFrameworkKey,
                status: currentStatus,
                auditorNotes: currentNotes
            )
            modelContext.insert(newRecord)
            evalRecord = newRecord
        }
        
        let artifact = EvidenceArtifact(
            title: fileName,
            fileName: fileName,
            relativeFilePath: destinationURL.path
        )
        artifact.evaluation = evalRecord
        evalRecord.evidenceArtifacts.append(artifact)
        modelContext.insert(artifact)
        try? modelContext.save()
    }
    
    private func removeEvidence(_ artifact: EvidenceArtifact) {
        modelContext.delete(artifact)
        try? modelContext.save()
    }
}
