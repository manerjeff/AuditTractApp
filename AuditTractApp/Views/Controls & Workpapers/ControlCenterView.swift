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
    @State private var showingPolicyVault = false
    
    let availableFrameworks: [FrameworkItem] = [
        FrameworkItem(id: "NIST_800_53", title: "NIST SP 800-53", subtitle: "Security and Privacy Controls for Information Systems", icon: "shield.checkerboard", color: .blue),
        FrameworkItem(id: "FEDRAMP_CMMC", title: "FedRAMP / CMMC 2.0", subtitle: "Federal Cloud & Defense Industrial Base Safeguards (NIST 800-171)", icon: "flag.fill", color: .red),
        FrameworkItem(id: "HITRUST", title: "HITRUST CSF v11", subtitle: "Healthcare & Enterprise Common Security Framework", icon: "cross.vial.fill", color: .yellow),
        FrameworkItem(id: "FISMA", title: "FISMA / NIST RMF", subtitle: "Federal Information Security Modernization Act & Risk Management Framework", icon: "building.2.fill", color: .indigo),
        FrameworkItem(id: "PCI_DSS", title: "PCI DSS v4.0", subtitle: "Payment Card Industry Data Security Standards for Payment Processing", icon: "creditcard.fill", color: .green),
        FrameworkItem(id: "SOX_ITGC", title: "SOX Section 404", subtitle: "Sarbanes-Oxley IT General Controls (ITGC) for Financial Systems", icon: "briefcase.fill", color: .blue),
        FrameworkItem(id: "CJIS", title: "CJIS Security Policy", subtitle: "FBI Criminal Justice Information Services Security Standards", icon: "shield.checkered", color: .brown),
        FrameworkItem(id: "AWS_SECURITY", title: "AWS Security Standards", subtitle: "AWS Foundational Security Best Practices & Well-Architected Security Pillar", icon: "cloud.fill", color: .orange),
        FrameworkItem(id: "FERPA", title: "FERPA Privacy & Security", subtitle: "Family Educational Rights & Privacy Act (34 CFR Part 99) Safeguards", icon: "graduationcap.fill", color: .pink),
        FrameworkItem(id: "GDPR_PRIVACY", title: "GDPR / CCPA Privacy", subtitle: "EU Data Protection Regulation & California Consumer Privacy Act Safeguards", icon: "hand.raised.slash.fill", color: .blue),
        FrameworkItem(id: "SOC_2", title: "SOC 2 Type II", subtitle: "Trust Services Criteria (Security, Availability, Confidentiality)", icon: "checkmark.seal.fill", color: .indigo),
        FrameworkItem(id: "SSAE_18", title: "SSAE 18 Attestations", subtitle: "AICPA Attestation Standard for Service Organization Control (SOC) Audits", icon: "doc.text.fill", color: .teal),
        FrameworkItem(id: "SOC_3", title: "SOC 3 General Use", subtitle: "AICPA Trust Services Public Report Framework", icon: "doc.plaintext.fill", color: .cyan),
        FrameworkItem(id: "SOC_1", title: "SOC 1 Type II", subtitle: "SSAE 18 Internal Controls over Financial Reporting (ICFR)", icon: "dollarsign.circle.fill", color: .green),
        FrameworkItem(id: "ISO_27001", title: "ISO/IEC 27001", subtitle: "Information Security Management System Standards", icon: "globe.americas.fill", color: .purple),
        FrameworkItem(id: "HIPAA", title: "HIPAA Security Rule", subtitle: "PHI Administrative, Physical & Technical Safeguards", icon: "cross.case.fill", color: .teal)
    ]
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(selectedFrameworkKey == nil ? "Compliance Frameworks" : "Controls")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingPolicyVault = true }) {
                            Label("Policy Library", systemImage: "doc.text.fill")
                                .foregroundStyle(.yellow)
                        }
                        .tint(.yellow)
                    }
                }
                .sheet(isPresented: $showingPolicyVault) {
                    PolicyVaultView()
                }
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

// MARK: - Global Compliance Posture Gauge Header
struct ComplianceSummaryHeaderView: View {
    let metrics: AuditEstimator.FrameworkProgressMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OVERALL COMPLIANCE POSTURE")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(metrics.completionPercentage))%")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(progressColor(metrics.completionPercentage))
                }
                
                Spacer()
                
                // Ring Progress Gauge
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(metrics.completionPercentage / 100.0))
                        .stroke(
                            progressColor(metrics.completionPercentage),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: metrics.completionPercentage)
                    
                    Image(systemName: "shield.checkmark.fill")
                        .font(.title2)
                        .foregroundColor(progressColor(metrics.completionPercentage))
                }
                .frame(width: 64, height: 64)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor(metrics.completionPercentage))
                        .frame(width: max(0, geo.size.width * CGFloat(metrics.completionPercentage / 100.0)), height: 8)
                }
            }
            .frame(height: 8)
            
            Divider()
            
            // Sub-metrics Grid
            HStack(spacing: 12) {
                metricTile(title: "Compliant", count: metrics.compliantCount, icon: "checkmark.circle.fill", color: .green)
                metricTile(title: "In Progress", count: metrics.inProgressCount, icon: "clock.fill", color: .orange)
                metricTile(title: "Non-Compliant", count: metrics.nonCompliantCount, icon: "exclamationmark.triangle.fill", color: .red)
                metricTile(title: "Active Frameworks", count: metrics.scopedFrameworksCount, icon: "square.stack.3d.up.fill", color: .accentColor)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func metricTile(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func progressColor(_ percentage: Double) -> Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .orange }
        return .accentColor
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
                let metrics = AuditEstimator.calculateGlobalMetrics(
                    tasks: tasks,
                    evaluations: evaluations,
                    frameworks: frameworks
                )
                
                ComplianceSummaryHeaderView(metrics: metrics)
                    .padding(.top)
                
                headerView
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(frameworks) { fw in
                        frameworkCard(fw)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.primary.opacity(0.03))
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
    }
    
    @ViewBuilder
    private func frameworkCard(_ fw: FrameworkItem) -> some View {
        let target = fw.id.uppercased()
        
        let fwTasks = tasks.filter { task in
            let taskFw = task.frameworkKey.uppercased()
            let taskId = task.id.uppercased()
            
            if target.contains("GDPR") {
                return taskFw.contains("GDPR") || taskId.hasPrefix("GDPR")
            } else if target.contains("HITRUST") {
                return taskFw.contains("HITRUST") || taskId.hasPrefix("HITRUST")
            } else if target.contains("FISMA") {
                return taskFw.contains("FISMA") || taskId.hasPrefix("FISMA")
            } else if target.contains("SSAE") {
                return taskFw.contains("SSAE") || taskId.hasPrefix("SSAE")
            } else if target.contains("SOX") {
                return taskFw.contains("SOX") || taskId.hasPrefix("SOX")
            } else if target.contains("PCI") {
                return taskFw.contains("PCI") || taskId.hasPrefix("PCI")
            } else if target.contains("CJIS") {
                return taskFw.contains("CJIS") || taskId.hasPrefix("CJIS")
            } else if target.contains("AWS") {
                return taskFw.contains("AWS") || taskId.hasPrefix("AWS")
            } else if target.contains("FERPA") {
                return taskFw.contains("FERPA") || taskId.hasPrefix("FERPA")
            } else if target == "SOC_3" || target == "SOC3" {
                return taskFw == "SOC_3" || taskFw == "SOC3" || taskId.hasPrefix("SOC3")
            } else if target == "SOC_1" || target == "SOC1" {
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
            .background(Color.secondary.opacity(0.12))
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
            
            if target.contains("GDPR") {
                return taskFw.contains("GDPR") || taskId.hasPrefix("GDPR")
            } else if target.contains("HITRUST") {
                return taskFw.contains("HITRUST") || taskId.hasPrefix("HITRUST")
            } else if target.contains("FISMA") {
                return taskFw.contains("FISMA") || taskId.hasPrefix("FISMA")
            } else if target.contains("SSAE") {
                return taskFw.contains("SSAE") || taskId.hasPrefix("SSAE")
            } else if target.contains("SOX") {
                return taskFw.contains("SOX") || taskId.hasPrefix("SOX")
            } else if target.contains("PCI") {
                return taskFw.contains("PCI") || taskId.hasPrefix("PCI")
            } else if target.contains("CJIS") {
                return taskFw.contains("CJIS") || taskId.hasPrefix("CJIS")
            } else if target.contains("AWS") {
                return taskFw.contains("AWS") || taskId.hasPrefix("AWS")
            } else if target.contains("FERPA") {
                return taskFw.contains("FERPA") || taskId.hasPrefix("FERPA")
            } else if target == "SOC_3" || target == "SOC3" {
                return taskFw == "SOC_3" || taskFw == "SOC3" || taskId.hasPrefix("SOC3")
            } else if target == "SOC_1" || target == "SOC1" {
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
            } else {
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
        .background(Color.secondary.opacity(0.12))
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
        let target = frameworkKey.uppercased()
        if target.contains("GDPR") { return "GDPR / CCPA Data Privacy" }
        if target.contains("HITRUST") { return "HITRUST CSF v11" }
        if target.contains("FISMA") { return "FISMA / NIST RMF" }
        if target.contains("SSAE") { return "SSAE 18 Attestations" }
        if target.contains("SOX") { return "SOX Section 404 ITGC" }
        if target.contains("PCI") { return "PCI DSS v4.0" }
        if target.contains("CJIS") { return "CJIS Security Policy" }
        if target.contains("AWS") { return "AWS Security Standards" }
        if target.contains("FERPA") { return "FERPA Privacy & Security" }
        if target == "SOC_3" || target == "SOC3" { return "SOC 3 General Use Report" }
        if target.contains("FEDRAMP") || target.contains("CMMC") { return "FedRAMP / CMMC 2.0" }
        if target.contains("SOC_1") || target == "SOC1" { return "SOC 1 Type II" }
        if target.contains("SOC_2") || target == "SOC2" { return "SOC 2 Type II" }
        if target.contains("ISO") { return "ISO 27001" }
        if target.contains("HIPAA") { return "HIPAA Security Rule" }
        return "NIST SP 800-53"
    }
}

// MARK: - Unbranded Policy Vault & Preview Screen
struct PolicyVaultView: View {
    @Environment(\.dismiss) private var dismiss
    let policies = AuditEstimator().buildDefaultPolicies()
    @State private var searchText = ""
    @State private var selectedPolicy: CompliancePolicy? = nil
    
    var filteredPolicies: [CompliancePolicy] {
        if searchText.isEmpty { return policies }
        return policies.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            $0.documentID.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredPolicies) { policy in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(policy.documentID)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(policy.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(policy.title)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        ForEach(policy.frameworkMapping, id: \.self) { mapping in
                            Text(mapping)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPolicy = policy
                }
            }
            .searchable(text: $searchText, prompt: "Search policies & standards...")
            .navigationTitle("Client Policy Library")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedPolicy) { policy in
                PolicyDetailSheet(policy: policy)
            }
        }
    }
}

// MARK: - Policy Reader & Markdown Export Sheet
struct PolicyDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let policy: CompliancePolicy
    @State private var showShareSheet = false
    @State private var exportedURL: URL?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(policy.contentMarkdown)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
            .navigationTitle(policy.documentID)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: exportPolicy) {
                        Label("Export Template", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheetView(activityItems: [url])
                }
            }
        }
    }
    
    private func exportPolicy() {
        let fileName = "\(policy.documentID)_Template.md"
        if let url = ReportExporter.shared.saveReportToDocuments(content: policy.contentMarkdown, fileName: fileName) {
            self.exportedURL = url
            self.showShareSheet = true
        }
    }
}
