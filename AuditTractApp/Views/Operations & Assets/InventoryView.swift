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
    @Query(sort: \AssetItem.name) private var assets: [AssetItem]
    @Query(sort: \Location.name) private var locations: [Location]
    @Query(sort: \Employee.name) private var employees: [Employee]
    
    @State private var searchText = ""
    @State private var showingAddSheet = false
    
    var filteredAssets: [AssetItem] {
        if searchText.isEmpty {
            return assets
        }
        return assets.filter { asset in
            asset.name.localizedCaseInsensitiveContains(searchText) ||
            asset.serialNumber.localizedCaseInsensitiveContains(searchText) ||
            asset.ipAddress.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredAssets.isEmpty {
                    ContentUnavailableView(
                        "No Inventory Assets",
                        systemImage: "desktopcomputer",
                        description: Text("Add hardware, systems, or network assets to track inventory compliance.")
                    )
                } else {
                    ForEach(filteredAssets) { asset in
                        AssetRowView(asset: asset)
                    }
                    .onDelete(perform: deleteAssets)
                }
            }
            .searchable(text: $searchText, prompt: "Search assets...")
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Asset", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAssetSheetView(locations: locations, employees: employees)
            }
        }
    }
    
    private func deleteAssets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredAssets[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Extracted Asset Row View (Solves Type Checker Expression Complexity)
private struct AssetRowView: View {
    let asset: AssetItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(asset.name)
                    .font(.headline)
                Spacer()
                Text(asset.criticality)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(criticalityColor(asset.criticality).opacity(0.15))
                    .foregroundColor(criticalityColor(asset.criticality))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 12) {
                if !asset.serialNumber.isEmpty {
                    Label(asset.serialNumber, systemImage: "barcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !asset.ipAddress.isEmpty {
                    Label(asset.ipAddress, systemImage: "network")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                if let loc = asset.location {
                    Label(loc.name, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let owner = asset.assignedOwner {
                    Label(owner.name, systemImage: "person")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func criticalityColor(_ criticality: String) -> Color {
        switch criticality.lowercased() {
        case "high", "critical": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
}

// MARK: - Extracted Add Asset Sheet View
private struct AddAssetSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let locations: [Location]
    let employees: [Employee]
    
    @State private var name = ""
    @State private var serialNumber = ""
    @State private var ipAddress = ""
    @State private var assetType = "Hardware"
    @State private var criticality = "Medium"
    @State private var selectedLocation: Location?
    @State private var selectedOwner: Employee?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset Metadata") {
                    TextField("Asset Name (e.g. Prod-DB-01)", text: $name)
                    TextField("Serial Number", text: $serialNumber)
                    TextField("IP Address", text: $ipAddress)
                }
                
                Section("Classification") {
                    Picker("Asset Type", selection: $assetType) {
                        Text("Hardware").tag("Hardware")
                        Text("Software / VM").tag("Software")
                        Text("Network Device").tag("Network")
                        Text("Cloud Instance").tag("Cloud")
                    }
                    
                    Picker("Criticality", selection: $criticality) {
                        Text("Low").tag("Low")
                        Text("Medium").tag("Medium")
                        Text("High").tag("High")
                        Text("Critical").tag("Critical")
                    }
                }
                
                Section("Assignments") {
                    Picker("Location", selection: $selectedLocation) {
                        Text("Unassigned").tag(Optional<Location>.none)
                        ForEach(locations) { loc in
                            Text(loc.name).tag(Optional(loc))
                        }
                    }
                    
                    Picker("Assigned Owner", selection: $selectedOwner) {
                        Text("Unassigned").tag(Optional<Employee>.none)
                        ForEach(employees) { emp in
                            Text(emp.name).tag(Optional(emp))
                        }
                    }
                }
            }
            .navigationTitle("New Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAsset()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveAsset() {
        let newAsset = AssetItem(
            name: name,
            serialNumber: serialNumber,
            ipAddress: ipAddress,
            assetType: assetType,
            criticality: criticality,
            location: selectedLocation,
            assignedOwner: selectedOwner
        )
        modelContext.insert(newAsset)
        try? modelContext.save()
    }
}
