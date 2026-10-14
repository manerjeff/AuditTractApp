import SwiftUI

struct ControlCenterView: View {
    @EnvironmentObject var estimator: AuditEstimator
    @StateObject private var syncManager = ControlSyncManager.shared
    
    // Active framework scope (Defaults to NIST)
    @State private var activeFrameworkKey: String = "NIST"
    @State private var selectedControlID: String? = nil
    @State private var searchText: String = ""
    
    // Workpaper State
    @State private var currentNotes: String = ""
    @State private var currentStatus: String = "Not Evaluated"
    @State private var evidenceItems: [String] = []
    
    // Modal Sheets
    @State private var showingAddEvidenceSheet: Bool = false
    @State private var newEvidenceName: String = ""
    
    // AppStorage Persistence
    @AppStorage("control_statuses_json") private var savedStatusesData: Data = Data()
    @AppStorage("control_notes_json") private var savedNotesData: Data = Data()
    @AppStorage("control_evidence_json") private var savedEvidenceData: Data = Data()
    
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
    
    var selectedControl: AuditTask? {
        if let id = selectedControlID {
            return filteredControls.first(where: { $0.id == id })
        }
        return filteredControls.first
    }
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Dedicated Scope Sidebar List
            VStack(spacing: 0) {
                // Scope Header Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(activeFrameworkKey) Audit Scope")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Controls (\(filteredControls.count))")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        if syncManager.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search \(activeFrameworkKey) controls...", text: $searchText)
                            .font(.subheadline)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
                
                Divider()
                
                // Controls List
                List(filteredControls, id: \.id) { control in
                    Button(action: {
                        selectedControlID = control.id
                        loadWorkpaperState(for: control.id)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(control.id)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text(cleanTitle(for: control))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }
                            Spacer()
                            let status = getLogStatus(for: control.id)
                            Text(status)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor(status).opacity(0.15))
                                .foregroundColor(statusColor(status))
                                .cornerRadius(4)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(activeFrameworkKey)
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            // MARK: - Detail Workpaper View
            if let control = selectedControl {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(control.frameworkKey) • \(control.category)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            
                            Text("\(control.id): \(cleanTitle(for: control))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        // 1. Control Statement Box
                        if let statement = control.controlStatement ?? control.blurb, !statement.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Control Statement")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(statement)
                                    .font(.body)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.primary.opacity(0.04))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // 2. Official Discussion / Guidance
                        if let discussion = control.discussion, !discussion.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Discussion")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(discussion)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // 3. Related To Cross-Reference Chips
                        if let related = control.relatedControls, !related.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Related To")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(related, id: \.self) { item in
                                            Button(action: { searchText = item }) {
                                                Text(item)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.accentColor)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.accentColor.opacity(0.12))
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 4. Repositioned Evaluation Status (Below Related To)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EVALUATION STATUS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(["Not Evaluated", "In Progress", "Compliant", "Not Compliant"], id: \.self) { st in
                                    Button(action: {
                                        currentStatus = st
                                        saveWorkpaperState(for: control.id)
                                    }) {
                                        Text(st)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(currentStatus == st ? statusColor(st) : Color.primary.opacity(0.06))
                                            .foregroundColor(currentStatus == st ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 5. Restored Auditor Notes Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AUDITOR WORKPAPER NOTES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $currentNotes)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color.primary.opacity(0.02))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                                .onChange(of: currentNotes) { _, _ in
                                    saveWorkpaperState(for: control.id)
                                }
                        }
                        
                        // 6. Restored Evidence Locker Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ATTACHED EVIDENCE LOCKER")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { showingAddEvidenceSheet = true }) {
                                    Label("Attach Evidence", systemImage: "paperclip")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            if evidenceItems.isEmpty {
                                Text("No evidence items attached to this control standard yet.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(evidenceItems, id: \.self) { item in
                                        HStack {
                                            Image(systemName: "doc.text.fill")
                                                .foregroundColor(.accentColor)
                                            Text(item)
                                                .font(.subheadline)
                                            Spacer()
                                            Button(action: { removeEvidence(item, for: control.id) }) {
                                                Image(systemName: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                        .padding(10)
                                        .background(Color.primary.opacity(0.04))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    loadWorkpaperState(for: control.id)
                }
                .onChange(of: selectedControlID) { _, newID in
                    if let newID = newID { loadWorkpaperState(for: newID) }
                }
            } else {
                Text("Select a control from the sidebar to begin evaluation.")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingAddEvidenceSheet) {
            NavigationStack {
                Form {
                    Section("Evidence Artifact") {
                        TextField("Document or Asset Title", text: $newEvidenceName)
                    }
                }
                .navigationTitle("Attach Evidence")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddEvidenceSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            if let control = selectedControl, !newEvidenceName.isEmpty {
                                evidenceItems.append(newEvidenceName)
                                saveWorkpaperState(for: control.id)
                                newEvidenceName = ""
                                showingAddEvidenceSheet = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
    }
    
    // MARK: - State & Helpers
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
    
    private func getLogStatus(for id: String) -> String {
        let dict = (try? JSONDecoder().decode([String: String].self, from: savedStatusesData)) ?? [:]
        return dict[id] ?? "Not Evaluated"
    }
    
    private func loadWorkpaperState(for id: String) {
        let statusDict = (try? JSONDecoder().decode([String: String].self, from: savedStatusesData)) ?? [:]
        let notesDict = (try? JSONDecoder().decode([String: String].self, from: savedNotesData)) ?? [:]
        let evidenceDict = (try? JSONDecoder().decode([String: [String]].self, from: savedEvidenceData)) ?? [:]
        
        currentStatus = statusDict[id] ?? "Not Evaluated"
        currentNotes = notesDict[id] ?? ""
        evidenceItems = evidenceDict[id] ?? []
    }
    
    private func saveWorkpaperState(for id: String) {
        var statusDict = (try? JSONDecoder().decode([String: String].self, from: savedStatusesData)) ?? [:]
        var notesDict = (try? JSONDecoder().decode([String: String].self, from: savedNotesData)) ?? [:]
        var evidenceDict = (try? JSONDecoder().decode([String: [String]].self, from: savedEvidenceData)) ?? [:]
        
        statusDict[id] = currentStatus
        notesDict[id] = currentNotes
        evidenceDict[id] = evidenceItems
        
        savedStatusesData = (try? JSONEncoder().encode(statusDict)) ?? savedStatusesData
        savedNotesData = (try? JSONEncoder().encode(notesDict)) ?? savedNotesData
        savedEvidenceData = (try? JSONEncoder().encode(evidenceDict)) ?? savedEvidenceData
    }
    
    private func removeEvidence(_ item: String, for id: String) {
        evidenceItems.removeAll(where: { $0 == item })
        saveWorkpaperState(for: id)
    }
}

