//
//  InventoryView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/14/26.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.name) private var items: [InventoryItem]
    
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var showingAddAssetSheet: Bool = false
    @State private var showingEmployeeDirectory: Bool = false
    @State private var selectedItemForDetail: InventoryItem? = nil
    
    let filterOptions = ["All", "Tier 1 Critical", "Confidential / PHI", "Unencrypted", "Decommissioned"]
    
    var filteredItems: [InventoryItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.assetType.localizedCaseInsensitiveContains(searchText) ||
                (item.ipAddressOrURL?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.ownerDisplayName.localizedCaseInsensitiveContains(searchText))
            
            let matchesFilter: Bool
            switch selectedFilter {
            case "Tier 1 Critical":
                matchesFilter = (item.criticality == .tier1)
            case "Confidential / PHI":
                matchesFilter = (item.classification == .confidential || item.classification == .phi || item.classification == .cardholderData)
            case "Unencrypted":
                matchesFilter = !item.isEncrypted
            case "Decommissioned":
                matchesFilter = (item.status == .decommissioned)
            default:
                matchesFilter = true
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Posture / Inventory Metrics Bar
                inventoryMetricsHeader
                
                // Filter Chips
                filterChipsBar
                
                Divider()
                
                // Asset List
                if items.isEmpty {
                    emptyInventoryPlaceholder
                } else if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Assets Match '\(searchText)'")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            Button {
                                selectedItemForDetail = item
                            } label: {
                                assetRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteAssets)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Asset Inventory")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search assets, IPs, custodians...")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showingEmployeeDirectory = true
                    } label: {
                        Label("Employee Directory", systemImage: "person.2.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                    
                    Button {
                        showingAddAssetSheet = true
                    } label: {
                        Label("Add Asset", systemImage: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingEmployeeDirectory) {
                EmployeeDirectoryView()
            }
            .sheet(isPresented: $showingAddAssetSheet) {
                AddInventoryItemSheet()
            }
            .sheet(item: $selectedItemForDetail) { item in
                InventoryItemDetailSheet(item: item)
            }
        }
    }
    
    // MARK: - Inventory Summary Header
    private var inventoryMetricsHeader: some View {
        let total = items.count
        let criticalCount = items.filter { $0.criticality == .tier1 }.count
        let unencryptedCount = items.filter { !$0.isEncrypted }.count
        let decommissionedCount = items.filter { $0.status == .decommissioned }.count
        
        return HStack(spacing: 12) {
            headerMetricTile(title: "Total Assets", count: total, icon: "server.rack", color: .accentColor)
            headerMetricTile(title: "Critical (Tier 1)", count: criticalCount, icon: "exclamationmark.shield.fill", color: .red)
            headerMetricTile(title: "Unencrypted", count: unencryptedCount, icon: "lock.open.trianglebadge.exclamationmark.fill", color: .orange)
            headerMetricTile(title: "Retired", count: decommissionedCount, icon: "archivebox.fill", color: .secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private func headerMetricTile(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Filter Chips
    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { opt in
                    Button {
                        selectedFilter = opt
                    } label: {
                        Text(opt)
                            .font(.caption)
                            .fontWeight(selectedFilter == opt ? .bold : .medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFilter == opt ? Color.accentColor : Color.secondary.opacity(0.12))
                            .foregroundColor(selectedFilter == opt ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Asset Row
    @ViewBuilder
    private func assetRow(_ item: InventoryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconForAssetType(item.assetType))
                .font(.title2)
                .foregroundColor(item.criticality == .tier1 ? .red : .accentColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if item.criticality == .tier1 {
                        Text("TIER 1")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.18))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 6) {
                    Text(item.assetType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let ip = item.ipAddressOrURL, !ip.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(ip)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(item.ownerDisplayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: item.isEncrypted ? "lock.fill" : "lock.open.fill")
                        .font(.caption2)
                        .foregroundColor(item.isEncrypted ? .green : .orange)
                    Text(item.isEncrypted ? "Encrypted" : "Plaintext")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(item.isEncrypted ? .green : .orange)
                }
                
                Text(item.classification.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 6)
    }
    
    private var emptyInventoryPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            
            Text("No Assets Registered")
                .font(.headline)
            
            Text("Scope systems, data stores, and cloud endpoints to map to compliance controls and scan diagnostics.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddAssetSheet = true
            } label: {
                Label("Register First Asset", systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteAssets(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    
    private func iconForAssetType(_ type: String) -> String {
        let lower = type.lowercased()
        if lower.contains("database") || lower.contains("sql") { return "cylinder.split.1x2.fill" }
        if lower.contains("server") || lower.contains("host") { return "server.rack" }
        if lower.contains("laptop") || lower.contains("macbook") { return "laptopcomputer" }
        if lower.contains("cloud") || lower.contains("aws") { return "cloud.fill" }
        if lower.contains("storage") || lower.contains("s3") { return "externaldrive.fill" }
        return "desktopcomputer"
    }
}

// MARK: - Add Inventory Item Sheet
struct AddInventoryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var name: String = ""
    @State private var assetType: String = "Application Server (EC2/VM)"
    @State private var ipAddressOrURL: String = ""
    @State private var isEncrypted: Bool = true
    @State private var classification: DataClassification = .internalData
    @State private var criticality: AssetCriticality = .tier2
    
    // Custodian Selection
    @State private var selectedEmployee: Employee? = nil
    @State private var customOwnerName: String = ""
    
    let assetTypes = [
        "Application Server (EC2/VM)",
        "Relational Database (PostgreSQL/MySQL/RDS)",
        "NoSQL Data Store (MongoDB/DynamoDB)",
        "Object Storage (AWS S3/GCS/Azure Blob)",
        "Auditor Workstation (macOS/Windows)",
        "Mobile Device (iOS/iPadOS Fleet)",
        "Network Router / Firewall / VPC Gateway"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset Details") {
                    TextField("Asset Name (e.g., Core Production DB)", text: $name)
                    Picker("Asset Type", selection: $assetType) {
                        ForEach(assetTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("IP Address or Endpoint Hostname (Optional)", text: $ipAddressOrURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                Section("Classification & Security") {
                    Picker("Data Classification", selection: $classification) {
                        ForEach(DataClassification.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    
                    Picker("Criticality Tier", selection: $criticality) {
                        ForEach(AssetCriticality.allCases, id: \.self) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    
                    Toggle("Encrypted at Rest & Transit", isOn: $isEncrypted)
                }
                
                Section("Assigned Custodian") {
                    if !employees.isEmpty {
                        Picker("Select Personnel", selection: $selectedEmployee) {
                            Text("Unassigned / General Team").tag(Employee?.none)
                            ForEach(employees) { emp in
                                Text("\(emp.name) (\(emp.role))").tag(Employee?.some(emp))
                            }
                        }
                    }
                    
                    if selectedEmployee == nil {
                        TextField("Or Manual Custodian / Team Label", text: $customOwnerName)
                    }
                }
            }
            .navigationTitle("New Inventory Asset")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEndpoint = ipAddressOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newItem = InventoryItem(
            name: cleanName,
            assetType: assetType,
            owner: customOwnerName.isEmpty ? "IT & Security Ops" : customOwnerName,
            assignedEmployee: selectedEmployee,
            ipAddressOrURL: cleanEndpoint.isEmpty ? nil : cleanEndpoint,
            status: .active,
            classification: classification,
            criticality: criticality,
            isEncrypted: isEncrypted
        )
        
        modelContext.insert(newItem)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Inventory Detail & Edit Sheet
struct InventoryItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: InventoryItem
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var isEditing: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset Identification") {
                    if isEditing {
                        TextField("Name", text: $item.name)
                        TextField("IP Address or Endpoint", text: Binding(
                            get: { item.ipAddressOrURL ?? "" },
                            set: { item.ipAddressOrURL = $0.isEmpty ? nil : $0 }
                        ))
                    } else {
                        LabeledContent("Name", value: item.name)
                        LabeledContent("Type", value: item.assetType)
                        LabeledContent("Endpoint / Host", value: item.ipAddressOrURL ?? "None")
                    }
                }
                
                Section("Security & Compliance Profile") {
                    if isEditing {
                        Toggle("Encrypted", isOn: $item.isEncrypted)
                        Picker("Classification", selection: $item.classification) {
                            ForEach(DataClassification.allCases, id: \.self) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        Picker("Criticality", selection: $item.criticality) {
                            ForEach(AssetCriticality.allCases, id: \.self) { tier in
                                Text(tier.rawValue).tag(tier)
                            }
                        }
                        Picker("Status", selection: $item.status) {
                            ForEach(AssetStatus.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                    } else {
                        LabeledContent("Encryption", value: item.isEncrypted ? "Protected" : "Unencrypted Plaintext")
                        LabeledContent("Classification", value: item.classification.rawValue)
                        LabeledContent("Criticality", value: item.criticality.rawValue)
                        LabeledContent("Status", value: item.status.rawValue)
                    }
                }
                
                Section("Custodian & Personnel") {
                    if isEditing {
                        Picker("Custodian", selection: $item.assignedEmployee) {
                            Text("Unassigned / Generic").tag(Employee?.none)
                            ForEach(employees) { emp in
                                Text("\(emp.name) (\(emp.department))").tag(Employee?.some(emp))
                            }
                        }
                    } else {
                        LabeledContent("Assigned Custodian", value: item.ownerDisplayName)
                        if let emp = item.assignedEmployee {
                            LabeledContent("Role & Department", value: "\(emp.role) • \(emp.department)")
                        }
                    }
                }
                
                if item.status == .decommissioned {
                    Section("NIST 800-88 Sanitization Details") {
                        if isEditing {
                            TextField("Certificate / Evidence ID", text: Binding(
                                get: { item.sanitizationCertificateID ?? "" },
                                set: { item.sanitizationCertificateID = $0.isEmpty ? nil : $0 }
                            ))
                        } else {
                            LabeledContent("Certificate ID", value: item.sanitizationCertificateID ?? "None Recorded")
                        }
                    }
                }
            }
            .navigationTitle(item.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            try? modelContext.save()
                            isEditing = false
                        } else {
                            isEditing = true
                        }
                    }
                }
            }
        }
    }
}

