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
    
    @ObservedObject private var syncManager = ControlSyncManager.shared
    @State private var selectedFrameworkKey: String? = nil
    
    let availableFrameworks: [FrameworkItem] = [
        FrameworkItem(id: "NIST_800_53", title: "NIST SP 800-53", subtitle: "Security and Privacy Controls for Information Systems", icon: "shield.checkerboard", color: .blue),
        FrameworkItem(id: "FEDRAMP_CMMC", title: "FedRAMP / CMMC 2.0", subtitle: "Federal Cloud & Defense Industrial Base Safeguards (NIST 800-171)", icon: "flag.fill", color: .red),
        FrameworkItem(id: "SOC_2", title: "SOC 2 Type II", subtitle: "Trust Services Criteria (Security, Availability, Confidentiality)", icon: "checkmark.seal.fill", color: .indigo),
        FrameworkItem(id: "SOC_1", title: "SOC 1 Type II", subtitle: "SSAE 18 Internal Controls over Financial Reporting (ICFR)", icon: "dollarsign.circle.fill", color: .green),
        FrameworkItem(id: "ISO_27001", title: "ISO/IEC 27001", subtitle: "Information Security Management System Standards", icon: "globe.americas.fill", color: .purple),
        FrameworkItem(id: "HIPAA", title: "HIPAA Security Rule", subtitle: "PHI Administrative, Physical & Technical Safeguards", icon: "cross.case.fill", color: .teal)
    ]
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(selectedFrameworkKey == nil ? "Compliance Frameworks" : "Controls")
                .onAppear {
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
        let target = fw.id.uppercased()
        
        let fwTasks = tasks.filter { task in
            let taskFw = task.frameworkKey.uppercased()
            let taskId = task.id.uppercased()
            
            if target == "SOC_1" || target == "SOC1" {
                return taskFw == "SOC_1" || taskFw == "SOC1" || taskId.hasPrefix("SOC1")
            } else if target == "SOC_2" || target == "SOC2" {
                return taskFw == "SOC_2" || taskFw == "SOC2" || taskId.hasPrefix("SOC2")
            } else if target.contains("NIST") {
                return taskFw.contains("NIST") || taskId.hasPrefix("NIST") || taskFw.isEmpty
            } else if target.contains("ISO") {
                return taskFw.contains("ISO") || taskId.hasPrefix("ISO")
            } else if target.contains("HIPAA") {
                return taskFw.contains("HIPAA") || taskId.hasPrefix("HIPAA")
            } else {
                return taskFw.contains(target)
            }
        }
        
        let totalCount = fwTasks.count
        let isInScope = evaluations.contains { $0.frameworkKey == fw.id } || (fw.id == "NIST_800_53")
        
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
        let target = frameworkKey.uppercased()
        
        let fwFiltered = allTasks.filter { task in
            let taskFw = task.frameworkKey.uppercased()
            let taskId = task.id.uppercased()
            
            if target == "SOC_1" || target == "SOC1" {
                return taskFw == "SOC_1" || taskFw == "SOC1" || taskId.hasPrefix("SOC1")
            } else if target == "SOC_2" || target == "SOC2" {
                return taskFw == "SOC_2" || taskFw == "SOC2" || taskId.hasPrefix("SOC2")
            } else if target.contains("NIST") {
                return taskFw.contains("NIST") || taskId.hasPrefix("NIST") || taskFw.isEmpty
            } else if target.contains("ISO") {
                return taskFw.contains("ISO") || taskId.hasPrefix("ISO")
            } else if target.contains("HIPAA") {
                return taskFw.contains("HIPAA") || taskId.hasPrefix("HIPAA")
            } else if target.contains("FEDRAMP") || target.contains("CMMC") {
                return taskFw.contains("FEDRAMP") || taskFw.contains("CMMC") || taskId.hasPrefix("CMMC") || taskId.hasPrefix("FED")
            }
            else {
                return taskFw.contains(target)
            }
        }
        
        if searchText.isEmpty {
            return fwFiltered
        } else {
            return fwFiltered.filter {
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
                    Text("Total tasks loaded in memory: \(allTasks.count)")
                        .font(.caption)
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
    
    // Inside frameworkTitle helper in ControlListView
    private var frameworkTitle: String {
        let target = frameworkKey.uppercased()
        if target.contains("FEDRAMP") || target.contains("CMMC") { return "FedRAMP / CMMC 2.0" }
        if target.contains("SOC_1") || target == "SOC1" { return "SOC 1 Type II" }
        if target.contains("SOC_2") || target == "SOC2" { return "SOC 2 Type II" }
        if target.contains("ISO") { return "ISO 27001" }
        if target.contains("HIPAA") { return "HIPAA Security Rule" }
        return "NIST SP 800-53"
    }
}
