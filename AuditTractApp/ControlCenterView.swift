import SwiftUI
import SwiftData

struct ControlCenterView: View {
    let activeWorkspace: UserWorkspace
    @ObservedObject var dataManager: AuditEstimator
    let initialFrameworkKey: String
    @Binding var isPresented: Bool
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedFrameworkKey: String = "SOC2"
    @State private var selectedControlID: String = ""
    @State private var searchFilter: String = ""
    
    // Status and Notes State
    @State private var currentStatus: String = "NOT EVALUATED"
    @State private var currentNotes: String = ""
    
    var currentFramework: Framework {
        dataManager.frameworks.first(where: { $0.key == selectedFrameworkKey }) ?? dataManager.frameworks[0]
    }
    
    var frameworkTasks: [AuditTask] {
        dataManager.tasks.filter { $0.frameworkKey == selectedFrameworkKey }
    }
    
    var filteredControls: [AuditTask] {
        if searchFilter.isEmpty {
            return frameworkTasks
        } else {
            return frameworkTasks.filter {
                $0.id.localizedCaseInsensitiveContains(searchFilter) ||
                $0.title.localizedCaseInsensitiveContains(searchFilter) ||
                $0.category.localizedCaseInsensitiveContains(searchFilter)
            }
        }
    }
    
    var selectedControl: AuditTask {
        if let found = frameworkTasks.first(where: { $0.id == selectedControlID }) {
            return found
        } else if let first = frameworkTasks.first {
            return first
        } else {
            return AuditTask(id: "N/A", frameworkKey: "SOC2", title: "No Control Selected", category: "General", blurb: nil, discussion: nil, controlActivities: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // MARK: - Left Sidebar: Controls List
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(TractColor.label)
                        TextField("Filter controls...", text: $searchFilter)
                            .font(.subheadline)
                            .foregroundColor(TractColor.ink)
                    }
                    .padding(10)
                    .background(TractColor.card)
                    .cornerRadius(6)
                    .padding(12)
                    
                    Divider().background(TractColor.stroke)
                    
                    List(filteredControls, id: \.id) { control in
                        let log = activeWorkspace.controlLogs.first(where: { $0.taskID == control.id })
                        let statusText = log?.status ?? "NOT EVALUATED"
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(control.id)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(control.id == selectedControl.id ? TractColor.copper : TractColor.ink)
                                
                                Text("\(control.category): \(control.title)")
                                    .font(.caption2)
                                    .foregroundColor(TractColor.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(statusText.uppercased())
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(statusColor(statusText).opacity(0.15))
                                .foregroundColor(statusColor(statusText))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            saveCurrentControlState()
                            selectedControlID = control.id
                            loadStateForSelectedControl()
                        }
                        .listRowBackground(control.id == selectedControl.id ? TractColor.card : Color.clear)
                    }
                    .listStyle(.plain)
                }
                .frame(width: 320)
                .background(TractColor.canvas)
                
                Divider().background(TractColor.stroke)
                
                // MARK: - Right Detail Panel
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentFramework.name)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(TractColor.copper)
                            
                            Text("\(selectedControl.id): \(selectedControl.title)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(TractColor.ink)
                        }
                        
                        // Status Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EVALUATION STATUS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(TractColor.label)
                            
                            HStack(spacing: 8) {
                                statusButton("Not Evaluated", status: "NOT EVALUATED")
                                statusButton("In Progress", status: "IN PROGRESS")
                                statusButton("Compliant", status: "COMPLIANT")
                                statusButton("Not Compliant", status: "NOT COMPLIANT")
                            }
                        }
                        
                        // Control Guidance & Discussion Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CONTROL GUIDANCE & DISCUSSION")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(TractColor.copper)
                            
                            Text(selectedControl.discussion ?? selectedControl.blurb ?? "The entity demonstrates commitment to integrity, security, and operational standards under AICPA Trust Services Criteria.")
                                .font(.subheadline)
                                .foregroundColor(TractColor.ink)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TractColor.card)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                        
                        // Recommended Testing Activities Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RECOMMENDED TESTING ACTIVITIES")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(TractColor.copper)
                            
                            Text(selectedControl.controlActivities ?? "1. Inspect operational policy documentation and management approval records.\n2. Verify system audit logging and annual compliance reviews.")
                                .font(.caption)
                                .foregroundColor(TractColor.ink)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TractColor.card)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                        
                        // Auditor Workpaper Notes Text Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AUDITOR WORKPAPER NOTES")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(TractColor.label)
                            
                            TextEditor(text: $currentNotes)
                                .font(.body)
                                .frame(height: 120)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(TractColor.card)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                        }
                    }
                    .padding(24)
                }
                .background(TractColor.canvas)
            }
            .navigationTitle("Assessment Workpaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        saveCurrentControlState()
                        isPresented = false
                    }
                    .foregroundColor(TractColor.copper)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            selectedFrameworkKey = initialFrameworkKey
            if let firstControl = frameworkTasks.first {
                selectedControlID = firstControl.id
            }
            loadStateForSelectedControl()
        }
    }
    
    private func statusButton(_ label: String, status: String) -> some View {
        let isSelected = currentStatus.lowercased() == status.lowercased()
        return Button(action: {
            currentStatus = status
            saveCurrentControlState()
        }) {
            Text(label)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? statusColor(status) : TractColor.card)
                .foregroundColor(isSelected ? .black : TractColor.ink)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(TractColor.stroke, lineWidth: 1))
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "compliant": return .green
        case "in progress": return .orange
        case "not compliant": return .red
        default: return TractColor.secondary
        }
    }
    
    private func loadStateForSelectedControl() {
        if let log = activeWorkspace.controlLogs.first(where: { $0.taskID == selectedControl.id }) {
            currentStatus = log.status
            currentNotes = log.notes
        } else {
            currentStatus = "NOT EVALUATED"
            currentNotes = ""
        }
    }
    
    private func saveCurrentControlState() {
        guard !selectedControl.id.isEmpty && selectedControl.id != "N/A" else { return }
        
        if let existingLog = activeWorkspace.controlLogs.first(where: { $0.taskID == selectedControl.id }) {
            existingLog.status = currentStatus
            existingLog.notes = currentNotes
        } else if currentStatus != "NOT EVALUATED" || !currentNotes.isEmpty {
            let newLog = ControlLog(
                        frameworkKey: selectedFrameworkKey,
                        controlTitle: selectedControl.title,
                        taskID: selectedControl.id,
                        status: currentStatus,
                        notes: currentNotes)
            activeWorkspace.controlLogs.append(newLog)
        }
        try? modelContext.save()
    }
}
