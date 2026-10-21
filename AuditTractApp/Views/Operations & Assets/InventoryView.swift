//
//  InventoryView 2.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/20/26.
//


// === File: ./Views/Inventory/InventoryView.swift ===
//
//  InventoryView.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/20/26.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.name) private var inventoryItems: [InventoryItem]
    
    @ObservedObject private var syncManager = ControlSyncManager.shared
    @State private var searchText = ""
    @State private var selectedClassification: String = "All"
    @State private var selectedItemForEdit: InventoryItem? = nil
    @State private var showingAddItemSheet = false
    
    var filteredItems: [InventoryItem] {
        inventoryItems.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.assetType.localizedCaseInsensitiveContains(searchText) ||
                item.owner.localizedCaseInsensitiveContains(searchText)
            
            let matchesClassification = selectedClassification == "All" ||
                item.classificationRaw == selectedClassification
            
            return matchesSearch && matchesClassification
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Metrics Bar
                inventoryMetricsHeader
                
                // Classification Filter Chips
                classificationFilterBar
                
                Divider()
                
                if filteredItems.isEmpty {
                    emptyInventoryView
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            InventoryRowView(item: item) {
                                selectedItemForEdit = item
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Asset & Evidence Inventory")
            .searchable(text: $searchText, prompt: "Search assets by name, type, or owner...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddItemSheet = true }) {
                        Label("Add Asset", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddEditInventorySheet()
            }
            .sheet(item: $selectedItemForEdit) { item in
                AddEditInventorySheet(itemToEdit: item)
            }
            .onAppear {
                seedDefaultInventoryIfNeeded()
            }
        }
    }
    
    // MARK: - Header Metrics
    private var inventoryMetricsHeader: some View {
        HStack(spacing: 16) {
            metricCard(
                title: "Total Assets",
                value: "\(inventoryItems.count)",
                icon: "server.rack",
                color: .blue
            )
            metricCard(
                title: "Encrypted",
                value: "\(inventoryItems.filter { $0.isEncrypted }.count)",
                icon: "lock.shield.fill",
                color: .green
            )
            metricCard(
                title: "In Scope Controls",
                value: "\(Set(inventoryItems.flatMap { $0.linkedControlIDs }).count)",
                icon: "link",
                color: .orange
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Classification Filter Bar
    private var classificationFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedClassification == "All") {
                    selectedClassification = "All"
                }
                
                ForEach(DataClassification.allCases, id: \.self) { classification in
                    FilterChip(
                        title: classification.rawValue,
                        isSelected: selectedClassification == classification.rawValue
                    ) {
                        selectedClassification = classification.rawValue
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var emptyInventoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Assets Found")
                .font(.headline)
            Text("Add an asset or adjust your classification filter.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func seedDefaultInventoryIfNeeded() {
        if inventoryItems.isEmpty {
            let defaults = InventoryItem.buildDefaultInventory()
            for item in defaults {
                modelContext.insert(item)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            modelContext.delete(item)
        }
    }
}

// MARK: - Filter Chip View
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Inventory Row View
struct InventoryRowView: View {
    let item: InventoryItem
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(item.classification.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(classificationColor(item.classification).opacity(0.18))
                        .foregroundColor(classificationColor(item.classification))
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 12) {
                    Label(item.assetType, systemImage: "server.rack")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(item.owner, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if item.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                if !item.linkedControlIDs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            Text("Linked Controls:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            ForEach(item.linkedControlIDs, id: \.self) { cid in
                                Text(cid)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundColor(.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func classificationColor(_ cls: DataClassification) -> Color {
        switch cls {
        case .cardholderData: return .green
        case .phi: return .teal
        case .cui: return .red
        case .cji: return .brown
        case .studentData: return .mint
        case .personalData: return .blue
        case .confidential: return .orange
        case .internalData: return .indigo
        case .publicData: return .secondary
        }
    }
}

// MARK: - Add / Edit Inventory Modal Sheet
struct AddEditInventorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var itemToEdit: InventoryItem? = nil
    
    @State private var name: String = ""
    @State private var assetType: String = "AWS EC2"
    @State private var owner: String = ""
    @State private var ipAddressOrURL: String = ""
    @State private var classification: DataClassification = .internalData
    @State private var criticality: AssetCriticality = .tier2
    @State private var isEncrypted: Bool = true
    @State private var linkedControlsInput: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset Details") {
                    TextField("Asset Name (e.g. prod-db-01)", text: $name)
                    TextField("Asset Type (e.g. Database, S3 Bucket)", text: $assetType)
                    TextField("System Owner / Custodian", text: $owner)
                    TextField("IP Address or URL (Optional)", text: $ipAddressOrURL)
                }
                
                Section("Scope & Data Classification") {
                    Picker("Classification", selection: $classification) {
                        ForEach(DataClassification.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    
                    Picker("Criticality", selection: $criticality) {
                        ForEach(AssetCriticality.allCases, id: \.self) { crit in
                            Text(crit.rawValue).tag(crit)
                        }
                    }
                    
                    Toggle("Encrypted at Rest / In Transit", isOn: $isEncrypted)
                }
                
                Section("Control Scope Binding") {
                    TextField("Comma-separated Control IDs (e.g. PCI-REQ-03, SOC2-CC6.1)", text: $linkedControlsInput)
                        .autocapitalization(.allCharacters)
                }
                
                Section("Notes & Evidence Details") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle(itemToEdit == nil ? "New Asset" : "Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAsset() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let item = itemToEdit {
                    name = item.name
                    assetType = item.assetType
                    owner = item.owner
                    ipAddressOrURL = item.ipAddressOrURL ?? ""
                    classification = item.classification
                    criticality = item.criticality
                    isEncrypted = item.isEncrypted
                    linkedControlsInput = item.linkedControlIDs.joined(separator: ", ")
                    notes = item.notes
                }
            }
        }
    }
    
    private func saveAsset() {
        let linkedIDs = linkedControlsInput
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let item = itemToEdit {
            item.name = name
            item.assetType = assetType
            item.owner = owner
            item.ipAddressOrURL = ipAddressOrURL.isEmpty ? nil : ipAddressOrURL
            item.classification = classification
            item.criticality = criticality
            item.isEncrypted = isEncrypted
            item.linkedControlIDs = linkedIDs
            item.notes = notes
        } else {
            let newItem = InventoryItem(
                name: name,
                assetType: assetType,
                owner: owner,
                ipAddressOrURL: ipAddressOrURL.isEmpty ? nil : ipAddressOrURL,
                classification: classification,
                criticality: criticality,
                linkedControlIDs: linkedIDs,
                isEncrypted: isEncrypted,
                notes: notes
            )
            modelContext.insert(newItem)
        }
        
        dismiss()
    }
}
