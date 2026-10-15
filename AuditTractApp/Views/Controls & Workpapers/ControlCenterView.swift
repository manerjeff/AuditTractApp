//
//  ControlCenterView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

struct FrameworkItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct ControlCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var evaluations: [ControlEvaluation]
    
    @StateObject private var syncManager = ControlSyncManager()
    @State private var selectedFrameworkKey: String? = nil
    
    let availableFrameworks: [FrameworkItem] = [
        FrameworkItem(id: "NIST_800_53", title: "NIST SP 800-53", subtitle: "Security and Privacy Controls for Information Systems", icon: "shield.checkerboard", color: .blue),
        FrameworkItem(id: "SOC_2", title: "SOC 2 Type II", subtitle: "Trust Services Criteria (Security, Availability, Confidentiality)", icon: "checkmark.seal.fill", color: .indigo),
        FrameworkItem(id: "ISO_27001", title: "ISO/IEC 27001", subtitle: "Information Security Management System Standards", icon: "globe.americas.fill", color: .purple),
        FrameworkItem(id: "HIPAA", title: "HIPAA Security Rule", subtitle: "PHI Administrative, Physical & Technical Safeguards", icon: "cross.case.fill", color: .teal)
    ]
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(selectedFrameworkKey == nil ? "Compliance Frameworks" : "Controls")
                .task {
                    if syncManager.tasks.isEmpty {
                        syncManager.loadActiveControls()
                    }
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let frameworkKey = selectedFrameworkKey {
            ControlListView(
                frameworkKey: frameworkKey,
                allTasks: syncManager.tasks,
                onBack: { selectedFrameworkKey = nil }
            )
        } else {
            FrameworkSelectionGrid(
                frameworks: availableFrameworks,
                tasks: syncManager.tasks,
                evaluations: evaluations,
                onSelect: { key in selectedFrameworkKey = key }
            )
        }
    }
}

// MARK: - Level 1: Framework Selection Grid Screen
struct FrameworkSelectionGrid: View {
    let frameworks: [FrameworkItem]
    let tasks: [AuditTask]
    let evaluations: [ControlEvaluation]
    let onSelect: (String) -> Void
    
    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 16)]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(frameworks) { fw in
                        frameworkCard(fw)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SELECT AUDIT FRAMEWORK")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("Active Compliance Catalogs")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    @ViewBuilder
    private func frameworkCard(_ fw: FrameworkItem) -> some View {
        let fwTasks = tasks.filter { task in
            if fw.id == "NIST_800_53" {
                return task.frameworkKey.isEmpty || task.frameworkKey.contains("NIST")
            } else {
                return task.frameworkKey.localizedCaseInsensitiveContains(fw.id)
            }
        }
        let totalCount = fw.id == "NIST_800_53" ? (fwTasks.isEmpty ? tasks.count : fwTasks.count) : fwTasks.count
        let isInScope = (fw.id == "NIST_800_53") || evaluations.contains { $0.frameworkKey == fw.id }
        
        Button(action: { onSelect(fw.id) }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: fw.icon)
                        .font(.title)
                        .foregroundColor(fw.color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fw.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(fw.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Divider()
                
                HStack {
                    Label("\(totalCount) Controls Loaded", systemImage: "list.bullet.rectangle")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(isInScope ? "In Scope" : "Out of Scope")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isInScope ? Color.green.opacity(0.18) : Color.secondary.opacity(0.15))
                        .foregroundColor(isInScope ? .green : .secondary)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Level 2: Filtered Controls List View
struct ControlListView: View {
    let frameworkKey: String
    let allTasks: [AuditTask]
    let onBack: () -> Void
    
    @State private var searchText = ""
    
    var filteredTasks: [AuditTask] {
        let fwFiltered = allTasks.filter { task in
            if frameworkKey == "NIST_800_53" {
                return task.frameworkKey.isEmpty || task.frameworkKey.contains("NIST")
            } else {
                return task.frameworkKey.localizedCaseInsensitiveContains(frameworkKey)
            }
        }
        
        let listToSearch = frameworkKey == "NIST_800_53" && fwFiltered.isEmpty ? allTasks : fwFiltered
        
        if searchText.isEmpty {
            return listToSearch
        } else {
            return listToSearch.filter {
                $0.id.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            navigationHeader
            
            Divider()
            
            if filteredTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Controls for \(frameworkTitle)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Import control definitions for this framework.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredTasks) { task in
                    NavigationLink(destination: ControlDetailView(task: task)) {
                        taskRow(task)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search \(frameworkTitle) controls...")
            }
        }
    }
    
    private var navigationHeader: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Frameworks")
                }
                .font(.headline)
                .foregroundColor(.accentColor)
            }
            Spacer()
            Text(frameworkTitle)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            Text("Frameworks").opacity(0)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    @ViewBuilder
    private func taskRow(_ task: AuditTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.id)
                    .font(.caption)
                    .fontWeight(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(task.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(task.title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private var frameworkTitle: String {
        switch frameworkKey {
        case "SOC_2": return "SOC 2 Type II"
        case "ISO_27001": return "ISO 27001"
        case "HIPAA": return "HIPAA Security Rule"
        default: return "NIST SP 800-53"
        }
    }
}
