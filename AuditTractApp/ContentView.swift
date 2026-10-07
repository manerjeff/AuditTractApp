import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserWorkspace.createdDate, order: .reverse) private var workspaces: [UserWorkspace]
    
    @StateObject private var dataManager = AuditEstimator()
    @StateObject private var subManager = SubscriptionManager()
    @StateObject private var feedManager = IntelligenceFeedManager()
    
    // MARK: - In-Scope Framework State
    @State private var inScopeFrameworkKeys: Set<String> = [
        "SOC2", "ISO27001", "NIST", "HIPAA", "PCIDSS", "SOC1", "FEDRAMP", "GDPR"
    ]
    
    // MARK: - View Presentation State
    @State private var showingControlCenter = false
    @State private var showingPaywall = false
    @State private var showingUserManual = false
    @State private var showingExportCenter = false
    @State private var showingNewWorkspaceSheet = false
    @State private var showingMasterResetAlert = false
    
    @State private var selectedWorkspaceID: UUID?
    @State private var newWorkspaceName: String = ""
    @State private var selectedFrameworkKey: String = "SOC2"
    
    // Search & Category Filter State
    @State private var searchQuery: String = ""
    @State private var selectedCategoryFilter: String = "ALL"
    @State private var scopeFilter: ScopeFilterMode = .inScope
    
    enum ScopeFilterMode: String, CaseIterable, Identifiable {
        case inScope = "IN SCOPE"
        case outOfScope = "OUT OF SCOPE"
        case all = "ALL"
        
        var id: String { self.rawValue }
    }
    
    var currentWorkspace: UserWorkspace {
        if let selectedID = selectedWorkspaceID, let found = workspaces.first(where: { $0.id == selectedID }) {
            return found
        } else if let first = workspaces.first {
            return first
        } else {
            let defaultWS = UserWorkspace(name: "Corporate Audit Workspace")
            modelContext.insert(defaultWS)
            try? modelContext.save()
            return defaultWS
        }
    }
    
    // Calculated Compliance Score Text (Fixes String comparisons for status)
    var complianceScoreText: String {
        let activeLogs = currentWorkspace.controlLogs
        guard !activeLogs.isEmpty else { return "0%" }
        
        let compliantCount = activeLogs.filter { $0.status.lowercased() == "compliant" }.count
        let percentage = Int((Double(compliantCount) / Double(activeLogs.count)) * 100)
        return "\(percentage)%"
    }
    
    var filteredFrameworks: [Framework] {
        dataManager.frameworks.filter { fw in
            let matchesSearch = searchQuery.isEmpty ||
                fw.name.localizedCaseInsensitiveContains(searchQuery) ||
                fw.key.localizedCaseInsensitiveContains(searchQuery)
            
            let isInScope = inScopeFrameworkKeys.contains(fw.key)
            let matchesScope: Bool
            switch scopeFilter {
            case .inScope: matchesScope = isInScope
            case .outOfScope: matchesScope = !isInScope
            case .all: matchesScope = true
            }
            
            return matchesSearch && matchesScope
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    dashboardHeaderView
                    trialStatusBanner
                    informationCenterBanner
                    metricsOverviewRow
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(TractColor.canvas)
                
                Divider().background(TractColor.stroke)
                
                ScrollView {
                    frameworkGridSection
                        .padding(24)
                }
            }
            .background(TractColor.canvas)
            .navigationTitle("Audit Tract")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingUserManual = true }) {
                            Label("Manual", systemImage: "book.fill")
                        }
                        Button(action: { showingExportCenter = true }) {
                            Label("Export", systemImage: "square.and.arrow.up.fill")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingControlCenter) {
                ControlCenterView(
                    activeWorkspace: currentWorkspace,
                    dataManager: dataManager,
                    initialFrameworkKey: selectedFrameworkKey,
                    isPresented: $showingControlCenter
                )
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(isSubscribed: $subManager.isProSubscribed)
            }
            .sheet(isPresented: $showingUserManual) {
                UserManualView(isPresented: $showingUserManual)
            }
            .sheet(isPresented: $showingExportCenter) {
                ExportReportView(
                    workspace: currentWorkspace,
                    dataManager: dataManager,
                    isPresented: $showingExportCenter
                )
            }
            .sheet(isPresented: $showingNewWorkspaceSheet) {
                createNewWorkspaceModal
            }
            .alert("Master Reset '\(currentWorkspace.name)'?", isPresented: $showingMasterResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Perform Master Reset", role: .destructive) {
                    currentWorkspace.controlLogs.removeAll()
                    inScopeFrameworkKeys = [
                        "SOC2", "ISO27001", "NIST", "HIPAA", "PCIDSS", "SOC1", "FEDRAMP", "GDPR"
                    ]
                    try? modelContext.save()
                }
            } message: {
                Text("ARE YOU SURE? This action cannot be undone. All compliance evaluations and auditor notes in '\(currentWorkspace.name)' will be permanently wiped.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedWorkspaceID == nil, let first = workspaces.first {
                selectedWorkspaceID = first.id
            }
        }
    }
    
    private var dashboardHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GOVERNANCE • RISK • COMPLIANCE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(TractColor.copper)
                
                Menu {
                    Section("ACTIVE WORKSPACES") {
                        ForEach(workspaces) { ws in
                            Button(action: {
                                selectedWorkspaceID = ws.id
                            }) {
                                HStack {
                                    Text(ws.name)
                                    if ws.id == currentWorkspace.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            newWorkspaceName = ""
                            showingNewWorkspaceSheet = true
                        }) {
                            Label("Create New Workspace", systemImage: "plus.circle.fill")
                        }
                    }
                    
                    Section("DANGER ZONE") {
                        Button(role: .destructive, action: { showingMasterResetAlert = true }) {
                            Label("Reset Current Workspace...", systemImage: "arrow.clockwise.circle.fill")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentWorkspace.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(TractColor.ink)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(TractColor.copper)
                    }
                }
            }
            
            Spacer()
            
            Button(action: { showingPaywall = true }) {
                HStack(spacing: 6) {
                    Image(systemName: subManager.isProSubscribed ? "checkmark.seal.fill" : "crown.fill")
                        .foregroundColor(subManager.isProSubscribed ? .green : .yellow)
                    Text(subManager.isProSubscribed ? "ACTIVE" : "UPGRADE")
                        .font(.caption)
                        .bold()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(TractColor.card)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(TractColor.stroke, lineWidth: 1))
            }
        }
    }
    
    private var informationCenterBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "newspaper.fill")
                .foregroundColor(TractColor.copper)
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("INFORMATION CENTER • REGULATORY FEED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(TractColor.copper)
                
                Text("PCI DSS v4.0 enforcement active. NIST SP 800-53 Rev 5 guidance updated.")
                    .font(.caption)
                    .foregroundColor(TractColor.ink)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("LIVE UPDATE")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(4)
        }
        .padding(10)
        .background(TractColor.card)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(TractColor.stroke, lineWidth: 1))
    }
    
    private var createNewWorkspaceModal: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("WORKSPACE NAME")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(TractColor.copper)
                
                TextField("e.g. Client Alpha Q3 Audit", text: $newWorkspaceName)
                    .font(.headline)
                    .padding(12)
                    .background(TractColor.card)
                    .cornerRadius(8)
                    .foregroundColor(TractColor.ink)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                
                Text("Create dedicated workspaces to isolate framework scopes, auditor notes, and evidence files per client or environment.")
                    .font(.caption)
                    .foregroundColor(TractColor.secondary)
                
                Spacer()
                
                Button(action: createWorkspace) {
                    Text("Create Workspace")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(newWorkspaceName.trimmingCharacters(in: .whitespaces).isEmpty ? TractColor.secondary : TractColor.copper)
                        .cornerRadius(10)
                }
                .disabled(newWorkspaceName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(24)
            .background(TractColor.canvas)
            .navigationTitle("New Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingNewWorkspaceSheet = false
                    }
                    .foregroundColor(TractColor.secondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func createWorkspace() {
        let trimmed = newWorkspaceName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let newWS = UserWorkspace(name: trimmed)
        modelContext.insert(newWS)
        try? modelContext.save()
        
        selectedWorkspaceID = newWS.id
        showingNewWorkspaceSheet = false
        newWorkspaceName = ""
    }
    
    @ViewBuilder
    private var trialStatusBanner: some View {
        if !subManager.isProSubscribed && subManager.isTrialActive {
            HStack {
                Image(systemName: "clock.badge.checkmark.fill")
                    .foregroundColor(TractColor.copper)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("7-DAY TRIAL ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(TractColor.ink)
                    Text("\(subManager.daysRemainingInTrial) days remaining in trial period. Unrestricted framework access.")
                        .font(.caption2)
                        .foregroundColor(TractColor.secondary)
                }
                
                Spacer()
                
                Button("Upgrade Now") {
                    showingPaywall = true
                }
                .font(.caption)
                .bold()
                .foregroundColor(TractColor.copper)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(TractColor.copper.opacity(0.15))
                .cornerRadius(4)
            }
            .padding(12)
            .background(TractColor.card)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.copper.opacity(0.4), lineWidth: 1))
        } else if !subManager.isProSubscribed && !subManager.isTrialActive {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRIAL EXPIRED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    Text("Your 7-day trial has ended. Subscribe to unlock workpapers and evidence tools.")
                        .font(.caption2)
                        .foregroundColor(TractColor.secondary)
                }
                
                Spacer()
                
                Button("Unlock") {
                    showingPaywall = true
                }
                .font(.caption)
                .bold()
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .cornerRadius(4)
            }
            .padding(12)
            .background(TractColor.card)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.5), lineWidth: 1))
        }
    }
    
    private var metricsOverviewRow: some View {
        HStack(spacing: 16) {
            metricCard(title: "COMPLIANCE SCORE", value: complianceScoreText, subtitle: "In-Scope Coverage", color: TractColor.copper)
            metricCard(title: "IN-SCOPE STANDARDS", value: "\(inScopeFrameworkKeys.count) / \(dataManager.frameworks.count)", subtitle: "Active Frameworks", color: Color.blue)
            metricCard(title: "CONTROLS AUDITED", value: "\(currentWorkspace.controlLogs.count)", subtitle: "In Active Workspace", color: Color.green)
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(TractColor.label)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(TractColor.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TractColor.card)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
    }
    
    private var frameworkGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(TractColor.label)
                    TextField("Search frameworks...", text: $searchQuery)
                        .font(.subheadline)
                        .foregroundColor(TractColor.ink)
                }
                .padding(10)
                .background(TractColor.card)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(TractColor.stroke, lineWidth: 1))
                
                Picker("Scope Filter", selection: $scopeFilter) {
                    ForEach(ScopeFilterMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredFrameworks) { fw in
                    let isInScope = inScopeFrameworkKeys.contains(fw.key)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: fw.icon)
                                .font(.title2)
                                .foregroundColor(isInScope ? fw.themeColor : TractColor.secondary)
                                .frame(width: 40, height: 40)
                                .background(isInScope ? fw.themeColor.opacity(0.15) : TractColor.canvas)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fw.name)
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(isInScope ? TractColor.ink : TractColor.secondary)
                                
                                Text(fw.key)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(isInScope ? fw.themeColor : TractColor.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if inScopeFrameworkKeys.contains(fw.key) {
                                    inScopeFrameworkKeys.remove(fw.key)
                                } else {
                                    inScopeFrameworkKeys.insert(fw.key)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isInScope ? "checkmark.circle.fill" : "circle")
                                        .font(.caption2)
                                    Text(isInScope ? "IN SCOPE" : "OUT OF SCOPE")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isInScope ? fw.themeColor.opacity(0.15) : TractColor.canvas)
                                .foregroundColor(isInScope ? fw.themeColor : TractColor.secondary)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(isInScope ? fw.themeColor.opacity(0.4) : TractColor.stroke, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(fw.blurb)
                            .font(.caption)
                            .foregroundColor(TractColor.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Divider().background(TractColor.stroke)
                        
                        HStack {
                            Text("\(fw.totalControls) CONTROLS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(TractColor.label)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(isInScope ? "OPEN WORKPAPER" : "OUT OF SCOPE")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                if isInScope {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 8, weight: .bold))
                                }
                            }
                            .foregroundColor(isInScope ? fw.themeColor : TractColor.secondary)
                        }
                    }
                    .padding(16)
                    .background(TractColor.card)
                    .cornerRadius(8)
                    .opacity(isInScope ? 1.0 : 0.5)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(TractColor.stroke, lineWidth: 1))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isInScope {
                            if subManager.hasAccess {
                                selectedFrameworkKey = fw.key
                                showingControlCenter = true
                            } else {
                                showingPaywall = true
                            }
                        }
                    }
                }
            }
        }
    }
}

