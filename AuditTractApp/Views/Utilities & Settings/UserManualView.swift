//
//  UserManualView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI

struct HelpTopic: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let icon: String
    let iconColor: Color
    let summary: String
    let steps: [String]
    let auditorTip: String?
}

struct UserManualView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    
    let topics: [HelpTopic] = [
        // --- GETTING STARTED ---
        HelpTopic(
            category: "Getting Started",
            title: "Auditing Compliance Frameworks",
            icon: "shield.checkerboard",
            iconColor: .blue,
            summary: "Learn how to select a catalog, evaluate requirements, and track overall compliance posture.",
            steps: [
                "Select any framework card on the main dashboard (NIST SP 800-53 is free; Pro unlocks the remaining 15 catalogs).",
                "Browse or search the control catalog by family prefix (e.g., AC, SC, CC).",
                "Tap a control to inspect its statutory requirement statement, supplemental guidance, and examination checklist.",
                "Set the compliance status (e.g., Compliant, In Progress, Non-Compliant) and record working notes.",
                "Changes auto-save immediately to your local device sandbox and update the main posture ring."
            ],
            auditorTip: "Use 'Evidence Collected' when artifacts are staged in the manifest but final management sign-off is pending."
        ),
        
        // --- ATTACK SURFACE SCANNING ---
        HelpTopic(
            category: "Attack Surface",
            title: "Automated Diagnostics & CVE Audits",
            icon: "network",
            iconColor: .red,
            summary: "Execute passive perimeter inspections, TLS cipher checks, and heuristic vulnerability detection.",
            steps: [
                "Navigate to the 'Attack Surface' tab from the top navigation bar.",
                "Tap 'Scan Target' to enter an ad-hoc public IP address or web endpoint URL.",
                "AuditTract passively checks SSL/TLS reachability, HSTS transport headers, CSP policies, and known OpenSSH exposures.",
                "Tap 'Scan Inventory' to automatically batch-evaluate all registered servers, databases, and storage assets in scope.",
                "Any discovered flaws automatically cross-reference with related controls (e.g., NIST SI-02, SC-08, SC-13)."
            ],
            auditorTip: "Opening a correlated control in the Controls tab displays active vs. remediated flaws with one-tap evidence attachment."
        ),
        
        // --- ASSET & CUSTODY ---
        HelpTopic(
            category: "Asset Inventory",
            title: "Scoping Assets & Employee Custody",
            icon: "server.rack",
            iconColor: .green,
            summary: "Maintain hardware, cloud, and data repositories mapped to data classifications and custodians.",
            steps: [
                "Open the 'Inventory' tab to review total active, critical (Tier 1), and decommissioned systems.",
                "Tap '+' to register a new system. Enter the asset name, type, and optional IP address or host URL.",
                "Assign an employee custodian using the Employee Picker or toggle 'Create New Employee Record' on the fly.",
                "Tag statutory classifications (e.g., ePHI, Cardholder Data, CUI) and toggle encryption at rest/transit.",
                "Record NIST SP 800-88 sanitization certificates when retiring decommissioned assets."
            ],
            auditorTip: "Linking control IDs (e.g., PCI-REQ-03) tags the asset directly to relevant framework evaluations."
        ),
        
        // --- THREAT INTELLIGENCE ---
        HelpTopic(
            category: "Threat Intelligence",
            title: "Live CISA & NIST Advisories",
            icon: "antenna.radiowaves.left.and.right",
            iconColor: .orange,
            summary: "Monitor active cybersecurity advisories and critical vulnerability alerts in real time.",
            steps: [
                "Navigate to the 'Intelligence' tab to stream real-time alerts parsed from CISA and NIST RSS feeds.",
                "Filter articles by CISA Alerts, NIST NVD, or saved Bookmarks.",
                "Tap 'Read Official Advisory' to launch an authenticated Safari view directly inside AuditTract.",
                "Tap the bookmark icon on any bulletin to flag it for executive risk reviews."
            ],
            auditorTip: "Pull down on the list anytime to trigger an asynchronous live feed refresh across federal repositories."
        ),
        
        // --- REPORTING & EXPORTS ---
        HelpTopic(
            category: "Exports & Handoff",
            title: "Generating Audit Binders & Packages",
            icon: "doc.zipper",
            iconColor: .accentColor,
            summary: "Export multi-section CSV workpapers or complete JSON cryptographic packages for external auditors.",
            steps: [
                "Tap the Export & Share icon (square.and.arrow.up.circle) in the top right toolbar.",
                "Choose 'Export Comprehensive Audit CSV' to bundle control evaluations, asset inventories, and CVE findings into one master spreadsheet.",
                "Choose 'Export Master JSON Audit Envelope' to generate a portable, structured JSON archive.",
                "Use the iOS/iPadOS Share Sheet to AirDrop, save to Files, or email directly to external CPAs and QSAs."
            ],
            auditorTip: "The Master JSON Envelope preserves complete system state and can be imported directly into other AuditTract instances."
        )
    ]
    
    var categories: [String] {
        ["All", "Getting Started", "Attack Surface", "Asset Inventory", "Threat Intelligence", "Exports & Handoff"]
    }
    
    var filteredTopics: [HelpTopic] {
        topics.filter { topic in
            let matchesCategory = (selectedCategory == "All") || (topic.category == selectedCategory)
            let matchesSearch = searchText.isEmpty ||
                topic.title.localizedCaseInsensitiveContains(searchText) ||
                topic.summary.localizedCaseInsensitiveContains(searchText) ||
                topic.steps.joined().localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat)
                                    .font(.caption)
                                    .fontWeight(selectedCategory == cat ? .bold : .medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color.accentColor : Color.secondary.opacity(0.12))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color.secondary.opacity(0.08))
                
                Divider()
                
                // Content List
                List {
                    ForEach(filteredTopics) { topic in
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: topic.icon)
                                        .font(.title2)
                                        .foregroundColor(topic.iconColor)
                                        .frame(width: 32, height: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(topic.title)
                                            .font(.headline)
                                        Text(topic.category)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(topic.summary)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Divider()
                                
                                Text("WORKFLOW PROCEDURE:")
                                    .font(.caption2)
                                    .fontWeight(.black)
                                    .foregroundColor(.secondary)
                                
                                ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(index + 1).")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentColor)
                                            .frame(width: 16, alignment: .leading)
                                        
                                        Text(step)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineSpacing(2)
                                    }
                                }
                                
                                if let tip = topic.auditorTip {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                            .padding(.top, 1)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("AUDITOR PRO TIP")
                                                .font(.system(size: 9, weight: .black))
                                                .foregroundColor(.yellow)
                                            Text(tip)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(10)
                                    .background(Color.yellow.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color.primary.opacity(0.03))
            .navigationTitle("AuditTract Field Manual")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search workflows, controls, exports...")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

